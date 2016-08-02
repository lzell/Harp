// This class should have no understanding of dpads, buttons, etc.

import Foundation
import HarpCommonOSX

protocol ServiceDelegate : class {
    func didReceiveControllerInput(state: ControllerState, forPlayer playerNum: Int)
    func didConnectToPlayer(playerNum: Int)
    func didDisconnectFromPlayer(playerNum: Int)
}

class Service {

    weak var delegate : ServiceDelegate?

    let maxConcurrentConnections : Int
    let controllerName : String
    let inputTranslator : InputTranslator

    // We can't satisfy the first phase of init if these are constants (we pass self to the
    // constructors of these sockets) so we're using implicitly unwrapped vars instead:
    var listeningSock : CFSocket!
    var listeningPort : UInt16!
    var udpReadSocket : CFSocket!
    var udpReadPort : UInt16!

    var reg : BluetoothService.Registration!
    let regType = "_harp._tcp"

    var connectionSlotMap : NSMapTable

    init(maxConcurrentConnections: Int, controllerName: String, inputTranslator: InputTranslator) {
        /* First phase */
        self.maxConcurrentConnections = maxConcurrentConnections
        self.controllerName = controllerName
        self.inputTranslator = inputTranslator
        connectionSlotMap = NSMapTable(keyOptions: NSPointerFunctionsOptions.OpaquePersonality, valueOptions: NSPointerFunctionsOptions.StrongMemory)

        /* Second ohase */
        let (sock, port) = createBindedUDPReadSocketWithReadCallback(toContext(self)) {
            (sock, _, _, _, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<Service>(info))
            me.udpDataIsAvailable(sock)
        }
        udpReadSocket = sock
        udpReadPort = port

        let (tcpsock, tcpport) = createBindedTCPListeningSocketWithAcceptCallback(toContext(self)) {
            (_, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
                // TODO: Close native handle if we've already accepted maxConcurrent
                let me = fromContext(UnsafeMutablePointer<Service>(info))
                // For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle:
                let nativeHandle = UnsafePointer<Int32>(data).memory
                me.didAcceptNewConnection(nativeHandle)
        }
        listeningSock = tcpsock
        listeningPort = tcpport
    }

    func register() {
        assert(listeningPort > 0, "accept socket has not been configured")
        reg = BluetoothService.Registration(format: regType, port: listeningPort)
        reg.start()
    }


    private func didAcceptNewConnection(handle: Int32) {
        assert(connectionSlotMap.count < maxConcurrentConnections, "We accepted a connection when we shouldn't have been listening for one")

        let sock = createConnectedTCPSocketFromNativeHandleWithDataCallback(handle, toContext(self)) {
            (sock, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<Service>(info))
            me.didReadFromConnectedSocket(sock, data)
        }

        // Send initial data down:
        sendInitialDataToHarpApp(sock)

        // Assign it a slot:
        let slot = findFreeSlotForSocket(sock)

        // Hang on to this socket
        connectionSlotMap.setObject(slot, forKey: sock)

        if connectionSlotMap.count >= maxConcurrentConnections {
            reg.stop()
        }

        // Notify delegate
        delegate?.didConnectToPlayer(slot)
    }


    func findFreeSlotForSocket(sock: CFSocket) -> Int {
        let used = NSAllMapTableValues(connectionSlotMap).map(){ $0 as! Int }.sort(<)
        var slot = 1
        var idx = 0
        while idx < used.count && used[idx] == slot {
            idx += 1
            slot += 1
        }
        return slot
    }


    private func udpDataIsAvailable(sock: CFSocket) {
        var buf = [UInt8](count: 8, repeatedValue: 0)
        var addrOut = sockaddr_in6()
        var addrLenInOut = sizeof(sockaddr_in6)
        let bytesRead = recvfrom(CFSocketGetNative(sock), &buf, buf.count, 0, valuePtrCast(&addrOut), valuePtrCast(&addrLenInOut))
        var posixErr: Int32 = 0

        if (bytesRead < 0) {
            posixErr = errno
        } else if (bytesRead == 0) {
            posixErr = EPIPE
        } else {
            assert(bytesRead == 8)
            var state: UInt64 = UInt64(buf[0])
            for i in 1..<8 {
                state <<= 8
                state |= UInt64(buf[i])
            }
            translateState(state, fromAddr: addrOut.sin6_addr)
        }

        if (posixErr != 0) {
            assert(false, "Could not read udp data")
        }
    }

    private func didReadFromConnectedSocket(sock: CFSocket, _ data: UnsafePointer<Void>) {
        let cfdata = fromContext(UnsafePointer<CFData>(data))
        if CFDataGetLength(cfdata) == 0 {
            // With a connection-oriented socket, if the connection is broken from the
            // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
            // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
            // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
            // the data argument will be a CFDataRef of length 0.
            didDisconnect(sock)
        } else {
            // Not putting in any protection about partial buffers! We'll see what happens
            // in practice first.
            if let message = String(data:cfdata, encoding: NSUTF8StringEncoding) {
                print("HarpApp sent us a message: \(message)")
            } else {
                assert(false, "Receiving something other than a string.")
            }
        }
    }


    private func sendInitialDataToHarpApp(sock: CFSocket) {
        let content = payload()
        let sendData = CFDataCreateWithBytesNoCopy(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
        if CFSocketSendData(sock, nil, sendData, -1) != .Success {
            assert(false, "Socket send failed")
        }
    }

    private func payload() -> String {
        return "Protocol-Version: 0.1.0\n" +
               "UDP-Port: \(udpReadPort)\n" +
               "Controller: \(controllerName)"
    }


    func didDisconnect(sock: CFSocket) {
        if let slot = connectionSlotMap.objectForKey(sock) as? Int {
            connectionSlotMap.removeObjectForKey(sock)
            if connectionSlotMap.count < maxConcurrentConnections {
                reg.start()
            }
            delegate?.didDisconnectFromPlayer(slot)
        } else {
            assert(false)
        }
    }


    func translateState(bitPattern: UInt64, fromAddr _fromAddr: in6_addr) {
        var fromAddr = _fromAddr
        var player: Int?
        for sock in connectionSlotMap.keyEnumerator() {
            let data = CFSocketCopyPeerAddress(sock as! CFSocket)
            let sadd : sockaddr_in6 = valuePtrCast(CFDataGetBytePtr(data)).memory
            var commAddr = sadd.sin6_addr
            if memcmp(&fromAddr, &commAddr, sizeofValue(commAddr)) == 0 {
                player = connectionSlotMap.objectForKey(sock) as? Int
                break
            }
        }

        if let player = player {
            let translated = inputTranslator.translate(bitPattern)
            delegate?.didReceiveControllerInput(translated, forPlayer: player)
        } else {
            print("Ignoring packet from address not found in connection map")
        }
    }
}