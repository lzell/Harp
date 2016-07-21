// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommoniOS



class ConnectionManager : ListeningSocketDelegate, CommSocketDelegate {

    let numConnections : Int

    let acceptSocket : ListeningSocket
    let udpWriteSocket : UDPWriteSocket
    var reg : BluetoothService.Registration!

    let regType = "_harp._tcp"


    // When these drop out, we should immediately start searching again until we connect up to numConnections:
    // TODO
    var commSockets : [CommSocket]

    init(numConnections: Int) {
        // First phase
        acceptSocket = ListeningSocket()
        let data = CFSocketCopyAddress(acceptSocket.underlying)
        let ptr = UnsafeMutablePointer<sockaddr_in6>(CFDataGetBytePtr(data))
        print("------------------------")
        printAddress(ptr.memory)
        print("++++++++++++++++++++++++++")

        udpWriteSocket = UDPWriteSocket()

        self.numConnections = numConnections
        commSockets = []

        // Second phase
        acceptSocket.delegate = self
        acceptSocket.run()
        udpWriteSocket.run()
    }

    func registerService() {
        assert(acceptSocket.port > 0, "accept socket has not been configured")
        reg = BluetoothService.Registration(format: regType, port: acceptSocket.port)
        reg.start()
    }

    // MARK: - SocketAcceptDelegate
    func didAccept(listeningSocket listeningSocket: ListeningSocket, connectedSocket: CommSocket) {
        assert(commSockets.count < numConnections, "We accepted a connection when we shouldn't have been listening for one")
        print("-------- accepted a socket ---- ")

        // Hang on to this socket
        commSockets.append(connectedSocket)
        connectedSocket.delegate = self

        // The client is going to send us the request... read it:
        connectedSocket.run()
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

        let tcpSockAddr6 = commSockets[0].peerAddress()
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