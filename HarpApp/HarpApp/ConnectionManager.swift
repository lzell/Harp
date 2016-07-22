// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommoniOS



class ConnectionManager {

    // This will write out the state of the controller
    let udpWriteSocket : CFSocket

    // Must be var because we can't satisfy first phase of init (we need self to construct the listeningSock)
    var listeningSock : CFSocket!
    var listeningPort : UInt16!
    let maxNumConnections : Int

    // Sockets created from the accept socket are not in the listening state
    var connectedSockets : [CFSocket]

    var reg : BluetoothService.Registration!
    let regType = "_harp._tcp"

    // TODO: When connections drop out, we should immediately re-register the service. Hm... do we want to de-register the service at all?  Maybe we just deny connections if we have one active.


    init(numConnections: Int) {
        // First phase
        udpWriteSocket = createUDPWriteSocket()
        maxNumConnections = numConnections
        connectedSockets = []

        // Second phase
        let port : UInt16
        let sock : CFSocket
        (sock, port) = createBindedTCPListeningSocketWithAcceptCallback(toContext(self)) {
            (_, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<ConnectionManager>(info))
            let nativeHandle = UnsafePointer<Int32>(data).memory
            me.acceptedNewConnection(nativeHandle)
        }

        listeningSock = sock
        listeningPort = port
        print("Listening on port: \(port)")
    }

    func acceptedNewConnection(handle: Int32) {
        assert(connectedSockets.count < maxNumConnections, "We accepted a connection when we shouldn't have been listening for one")


        let sock = createConnectedTCPSocketFromNativeHandleWithDataCallback(handle, toContext(self)) {
            (sock, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
                let me = fromContext(UnsafeMutablePointer<ConnectionManager>(info))
                let cfdata = fromContext(UnsafePointer<CFData>(data))
                if CFDataGetLength(cfdata) == 0 {
                    print("Disconnected!")
                    // TODO: We've disconnected
                    // With a connection-oriented socket, if the connection is broken from the
                    // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
                    // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
                    // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
                    // the data argument will be a CFDataRef of length 0.
                } else {
                    print("We got some stuff, cool!")
                    // Not putting in any protection about partial buffers! We'll 
                    // see what happens in practice.
                    if let request = String(data:cfdata, encoding: NSUTF8StringEncoding) {
                        me.didReceiveClientRequest(sock, request)
                    } else {
                        assert(false, "Receiving something other than a string.")
                    }
                }
        }


        // Hang on to this socket
        connectedSockets.append(sock)
    }

    func didReceiveClientRequest(sock: CFSocket, _ request: String) {
        print("Client sent a message: \(request)")

        let dict = parseRequest(request)
        assert(dict["UDP-Port"] != nil)
        assert(dict["Protocol-Version"] != nil)
        assert(dict["Controller"] != nil)

        let receivePort = UInt16(dict["UDP-Port"]!)!

        let data = CFSocketCopyPeerAddress(sock)
        let sockaddr_in6_ptr = UnsafeMutablePointer<sockaddr_in6>(CFDataGetBytePtr(data))

        var sockAddr6 = sockaddr_in6_ptr.memory
        sockAddr6.sin6_port = CFSwapInt16HostToBig(receivePort)


        let bytePtr = withUnsafePointer(&sockAddr6) { UnsafePointer<UInt8>($0) }
        let addressData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bytePtr, sizeofValue(sockAddr6), kCFAllocatorNull)
        //        let addressData = CFDataCreate(kCFAllocatorDefault, valuePtrCast(ptr), sizeof(sockaddr_in6))

        // C interop with swift strings!  Awesome!
        // Also see the String getBytes or getCString methods provided by Swift
        let sendData = CFDataCreateWithBytesNoCopy(nil, "foo", "foo".lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
        //        let sendData = CFDataCreate(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), nil)
        if CFSocketSendData(udpWriteSocket, addressData, sendData, -1) != .Success {
            print("UDP Socket send failed")
        } else {
            print("Sent something via UDP")
        }
    }


    func registerService() {
        assert(listeningPort > 0, "accept socket has not been configured")
        reg = BluetoothService.Registration(format: regType, port: listeningPort)
        reg.start()
    }



    func parseRequest(request: String) -> [String:String] {
        var ret : [String:String] = [:]
        let lines : [String] = request.componentsSeparatedByString("\n")
        lines.forEach { (line) in
            let pair = line.componentsSeparatedByString(":").map() { (comp) in stripWhitespace(comp) }
            ret[pair[0]] = pair[1]
        }
        return ret
    }
}