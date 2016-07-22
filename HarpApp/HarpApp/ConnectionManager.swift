// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommoniOS



class ConnectionManager : ListeningSocketDelegate, CommSocketDelegate {

    let numConnections : Int

    var listeningSock : CFSocket!
    var listeningPort : UInt16!


    let udpWriteSocket : UDPWriteSocket
    var reg : BluetoothService.Registration!

    let regType = "_harp._tcp"

    // TODO: When these drop out, we should immediately start searching again until we connect up to numConnections:

    // Sockets created from the accept socket are not in the listening state
    var connectedSockets : [CFSocket]

    init(numConnections: Int) {
        // First phase



//
//        ) { (ctxt) in
//            let me = fromContext(UnsafeMutablePointer<ConnectionManager>(ctxt))
//            print("Doing stuff: \(me)")
//        }

//        acceptSocket = ListeningSocket()
//        let data = CFSocketCopyAddress(acceptSocket.underlying)
//        let ptr = UnsafeMutablePointer<sockaddr_in6>(CFDataGetBytePtr(data))
//        print("------------------------")
//        printAddress(ptr.memory)
//        print("++++++++++++++++++++++++++")
//
        udpWriteSocket = UDPWriteSocket()

        self.numConnections = numConnections
        connectedSockets = []

        // Second phase
//        acceptSocket.delegate = self
//        acceptSocket.run()
        udpWriteSocket.run()



        let port : UInt16
        let sock : CFSocket
        (sock, port) = createBindedTCPListeningSocketWithAcceptCallback(toContext(self)) {
            (_, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
            // For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle:
            let nativeHandle: Int32 = UnsafePointer<Int32>(data).memory
            let me = fromContext(UnsafeMutablePointer<ConnectionManager>(info))
            print("Accepted something")
        }

        listeningSock = sock
        listeningPort = port

        print("LZLZL port is: \(port)")

    }

    func registerService() {
        assert(listeningPort > 0, "accept socket has not been configured")
        reg = BluetoothService.Registration(format: regType, port: listeningPort)
        reg.start()
    }

    // MARK: - SocketAcceptDelegate
    func didAccept(listeningSocket listeningSocket: ListeningSocket, connectedSocket: CommSocket) {
//        assert(commSockets.count < numConnections, "We accepted a connection when we shouldn't have been listening for one")
//        print("-------- accepted a socket ---- ")
//
//        // Hang on to this socket
//        commSockets.append(connectedSocket)
//        connectedSocket.delegate = self
//
//        // The client is going to send us the request... read it:
//        connectedSocket.run()
    }

    func didConnect(commSocket: CommSocket) {
        // We don't initiate connections on this side.
    }

    func didRead(commSocket: CommSocket, request: String) {
        print("Client sent a message: \(request)")

        let dict = parseRequest(request)
        assert(dict["UDP-Port"] != nil)
        assert(dict["Protocol-Version"] != nil)
        assert(dict["Controller"] != nil)

        let daPort = UInt16(dict["UDP-Port"]!)!

//        let controller = dict["Controller"]

        let data = CFSocketCopyPeerAddress(connectedSockets[0])
        let sockaddr_in6_ptr = UnsafeMutablePointer<sockaddr_in6>(CFDataGetBytePtr(data))

        let tcpSockAddr6 = sockaddr_in6_ptr.memory
        var sockAddr6 = tcpSockAddr6
        sockAddr6.sin6_port = CFSwapInt16HostToBig(daPort)
//
//        var sock6Addr = sockaddr_in6()
//        sock6Addr.sin6_len = UInt8(sizeof(sockaddr_in6))
//        sock6Addr.sin6_addr = in6Addr
//        sock6Addr.sin6_family = sa_family_t(AF_INET6)
//        sock6Addr.sin6_port = CFSwapInt16HostToBig(daPort)
//        


        let ptr : UnsafePointer<sockaddr_in6> = withUnsafePointer(&sockAddr6) { $0 }
        let cfdata = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(ptr), sizeof(sockaddr_in6))
        udpWriteSocket.sendTo(cfdata)
        udpWriteSocket.run()
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