// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommonOSX


class ConnectionManager : Proto1ReadContract {

    var udpReadSocket : CFSocket!
    var udpReadPort : UInt16!


    // Must be var because we can't satisfy first phase of init (we need self to construct the listeningSock)
    var listeningSock : CFSocket!
    var listeningPort : UInt16!
    let maxNumConnections : Int

    // Sockets created from the accept socket are not in the listening state
    var connectedSockets : [CFSocket]

    var reg : BluetoothService.Registration!
    let regType = "_harp._tcp"

    // TODO: When connections drop out, we should immediately re-register the service. Hm... do we want to de-register the service at all?  Maybe we just deny connections if we have one active.


    private func doRead(sock: CFSocket) {
        var buf = [UInt8](count: 8, repeatedValue: 0)
        let bytesRead = recv(CFSocketGetNative(sock), &buf, buf.count, 0)
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
            handleState(state)
        }

        if (posixErr != 0) {
            assert(false, "Could not read udp data")
        }
    }

    private func handleState(bitPattern: UInt64) {
        let dpadState = dpadStateFromBitPattern(bitPattern)
        let bBtnState = bButtonStateFromBitPattern(bitPattern)
        let aBtnState = aButtonStateFromBitPattern(bitPattern)
        print("Dpad is: \(dpadState), b is: \(bBtnState), a is: \(aBtnState)")
    }



    init(numConnections: Int) {
        // First phase
        maxNumConnections = numConnections
        connectedSockets = []

        // Second phase
        let (sock, port) = createBindedUDPReadSocketWithReadCallback(toContext(self)) {
            (sock, _, _, _, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<ConnectionManager>(info))
            me.doRead(sock)
        }
        udpReadSocket = sock
        udpReadPort = port
        print("Reading on UDP Port \(port)")


        // Second phase
        let (tcpsock, tcpport) = createBindedTCPListeningSocketWithAcceptCallback(toContext(self)) {
            (_, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<ConnectionManager>(info))
            // For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle:
            let nativeHandle = UnsafePointer<Int32>(data).memory
            me.acceptedNewConnection(nativeHandle)
        }
        listeningSock = tcpsock
        listeningPort = tcpport

        print("Listening on port: \(tcpport)")
    }

    func acceptedNewConnection(handle: Int32) {
        assert(connectedSockets.count < maxNumConnections, "We accepted a connection when we shouldn't have been listening for one")


        let sock = createConnectedTCPSocketFromNativeHandleWithDataCallback(handle, toContext(self)) {
            (sock, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
                let me = fromContext(UnsafeMutablePointer<ConnectionManager>(info))
                let cfdata = fromContext(UnsafePointer<CFData>(data))
                if CFDataGetLength(cfdata) == 0 {
                    // With a connection-oriented socket, if the connection is broken from the
                    // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
                    // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
                    // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
                    // the data argument will be a CFDataRef of length 0.
                    me.didDisconnectFromHarpApp(sock)
                } else {
                    // Not putting in any protection about partial buffers! We'll
                    // see what happens in practice.
                    if let message = String(data:cfdata, encoding: NSUTF8StringEncoding) {
                        print("HarpApp sent us a message: \(message)")
                    } else {
                        assert(false, "Receiving something other than a string.")
                    }
                }
        }

        // Send initial data down:
        sendInitialDataToHarpApp(sock)
        
        // Hang on to this socket
        connectedSockets.append(sock)
    }


    func sendInitialDataToHarpApp(sock: CFSocket) {
        let content = payload()
        let sendData = CFDataCreateWithBytesNoCopy(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
        if CFSocketSendData(sock, nil, sendData, -1) != .Success {
            assert(false, "Socket send failed")
        }
    }

    private func payload() -> String {
        return  "Protocol-Version: 0.1.0\n" +
            "UDP-Port: \(udpReadPort)\n" +
        "Controller: Proto1ViewController"
    }


    func didDisconnectFromHarpApp(sock: CFSocket) {
        print("Harp app disconnected... should register the service again?")
    }


    func registerService() {
        assert(listeningPort > 0, "accept socket has not been configured")
        reg = BluetoothService.Registration(format: regType, port: listeningPort)
        reg.start()
    }

}