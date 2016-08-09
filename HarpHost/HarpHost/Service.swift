// This class should have no understanding of dpads, buttons, etc.

import Foundation
import HarpCommonOSX

protocol ServiceDelegate : class {
    func didReceiveControllerInput(_ state: ControllerState, forPlayer playerNum: Int)
    func didConnectToPlayer(_ playerNum: Int)
    func didDisconnectFromPlayer(_ playerNum: Int)
}

class Service {

    weak var delegate : ServiceDelegate?

    let maxConcurrentConnections : Int
    var controllerName : String?
    var inputTranslator : InputTranslator?

    // We can't satisfy the first phase of init if these are constants (we pass self to the
    // constructors of these sockets) so we're using implicitly unwrapped vars instead:
    var listeningSock : CFSocket!
    var listeningPort : UInt16!
    var udpReadSocket : CFSocket!
    var udpReadPort : UInt16!

    var reg : BluetoothService.Registration!
    let regType = "_harp._tcp"

    var connectionSlotMap : NSMapTable<CFSocket, NSNumber>

    init(maxConcurrentConnections: Int) {
        /* First phase */
        self.maxConcurrentConnections = maxConcurrentConnections
        connectionSlotMap = NSMapTable(keyOptions: NSPointerFunctions.Options.opaquePersonality, valueOptions: NSPointerFunctions.Options.strongMemory)

        /* Second phase */
        let (sock, port) = createBindedUDPReadSocketWithReadCallback(toContext(self)) {
            (sock, _, _, _, info: UnsafeMutablePointer<Void>?) in
            let me = fromContext(UnsafeMutablePointer<Service>(info!))
            me.udpDataIsAvailable(sock!)
        }
        udpReadSocket = sock
        udpReadPort = port

        let (tcpsock, tcpport) = createBindedTCPListeningSocketWithAcceptCallback(toContext(self)) {
            (_, _, _, data: UnsafePointer<Void>?, info: UnsafeMutablePointer<Void>?) in
                // TODO: Close native handle if we've already accepted maxConcurrent
                let me = fromContext(UnsafeMutablePointer<Service>(info!))
                // For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle:
                let nativeHandle = UnsafePointer<Int32>(data!).pointee
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

    func setController(name: String, inputTranslator: InputTranslator /*, forPlayer playerNum: Int */) {
        self.controllerName = name
        self.inputTranslator = inputTranslator

        for sock in connectionSlotMap.keyEnumerator() {
            let cfsock = sock as! CFSocket
            send(content: controllerChangePayload(), on: cfsock)
            send(content: controllerChangePayload(), on: cfsock)
        }
    }


    private func didAcceptNewConnection(_ handle: Int32) {
        assert(connectionSlotMap.count < maxConcurrentConnections, "We accepted a connection when we shouldn't have been listening for one")

        let sock = createConnectedTCPSocketFromNativeHandleWithDataCallback(handle, toContext(self)) {
            (sock, _, _, data: UnsafePointer<Void>?, info: UnsafeMutablePointer<Void>?) in
            let me = fromContext(UnsafeMutablePointer<Service>(info!))
            me.didReadFromConnectedSocket(sock!, data!)
        }

        // Send initial data down:
        send(content: handshakePayload(), on: sock)

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


    func findFreeSlotForSocket(_ sock: CFSocket) -> Int {
        let used = connectionSlotMap.objectEnumerator()!.map(){ $0 as! Int }.sorted(by: <)
        var slot = 1
        var idx = 0
        while idx < used.count && used[idx] == slot {
            idx += 1
            slot += 1
        }
        return slot
    }


    private func udpDataIsAvailable(_ sock: CFSocket) {
        var buf = [UInt8](repeating: 0, count: 8)
        var addrOut = sockaddr_in6()
        var addrLenInOut = sizeof(sockaddr_in6.self)
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

    private func didReadFromConnectedSocket(_ sock: CFSocket, _ data: UnsafePointer<Void>) {
        let cfdata = fromContext(UnsafePointer<CFData>(data))
        if CFDataGetLength(cfdata) == 0 {
            // With a connection-oriented socket, if the connection is broken from the
            // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
            // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
            // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
            // the data argument will be a CFDataRef of length 0.
            didDisconnect(sock)
        } else {
            assert(false)
        }
    }

    private func send(content: String, on socket: CFSocket) {
        let numUtf8Bytes = content.lengthOfBytes(using: String.Encoding.utf8)
        assert(numUtf8Bytes < Int(~UInt16(0)))
        var header = UInt16(numUtf8Bytes)
        let numHeaderBytes = sizeofValue(header)
        let capacity = numUtf8Bytes + numHeaderBytes
        let buf = CFDataCreateMutable(nil, capacity)
        CFDataAppendBytes(buf, withUnsafePointer(&header) { UnsafePointer<UInt8>($0) }, numHeaderBytes)
        CFDataAppendBytes(buf, content, numUtf8Bytes)
        if CFSocketSendData(socket, nil, buf, -1) != .success {
            assert(false, "Socket send failed")
        }
    }


    private func handshakePayload() -> String {
        return "handshake\n" +
               "protocolVersion: 0.1.2\n" +
               "udpPort: \(udpReadPort!)"
    }

    private func controllerChangePayload() -> String {
        return "controllerChange\n" +
               "controllerName: \(controllerName!)"
    }


    func didDisconnect(_ sock: CFSocket) {
        if let slot = connectionSlotMap.object(forKey: sock) as? Int {
            connectionSlotMap.removeObject(forKey: sock)
            if connectionSlotMap.count < maxConcurrentConnections {
                reg.start()
            }
            delegate?.didDisconnectFromPlayer(slot)
        } else {
            assert(false)
        }
    }


    func translateState(_ bitPattern: UInt64, fromAddr _fromAddr: in6_addr) {
        var fromAddr = _fromAddr
        var player: Int?
        for sock in connectionSlotMap.keyEnumerator() {
            let sock : CFSocket = sock as! CFSocket
            let data = CFSocketCopyPeerAddress(sock)
            let sadd : sockaddr_in6 = valuePtrCast(CFDataGetBytePtr(data)).pointee
            var commAddr = sadd.sin6_addr
            if memcmp(&fromAddr, &commAddr, sizeofValue(commAddr)) == 0 {
                player = connectionSlotMap.object(forKey: sock)! as Int
                break
            }
        }

        if let player = player {
            let translated = inputTranslator!.translate(bitPattern)
            delegate?.didReceiveControllerInput(translated, forPlayer: player)
        } else {
            print("Ignoring packet from address not found in connection map")
        }
    }
}
