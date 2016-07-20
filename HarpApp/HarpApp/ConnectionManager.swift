// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommoniOS



class ConnectionManager : ListeningSocketDelegate, CommSocketDelegate {

    let numConnections : Int

    let acceptSocket : ListeningSocket
    var reg : BluetoothService.Registration!

    let regType = "_harp._tcp"


    // When these drop out, we should immediately start searching again until we connect up to numConnections:
    // TODO
    var commSockets : [CommSocket]

    init(numConnections: Int) {
        // First phase
        acceptSocket = ListeningSocket()
        self.numConnections = numConnections
        commSockets = []

        // Second phase
        acceptSocket.delegate = self
        acceptSocket.run()
    }

    func registerService() {
        assert(acceptSocket.port > 0, "accept socket has not been configured")
        reg = BluetoothService.Registration(format: regType, port: acceptSocket.port.littleEndian)
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
        print(dict)
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