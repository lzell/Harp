// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommoniOS


func autoReadCallback(sock: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {
    assert(type == .DataCallBack, "Unexpected callback type")
    print("WHATEVER")
    //    let sockObj = fromContext(UnsafeMutablePointer<SocketAccept>(info))
    //    assert(sockObj.underlying === sock, "Unexpected socket")
    //    sockObj._didAccept(UnsafePointer<Int32!>(data).memory)
}


class ConnectionManager : ListeningSocketDelegate {

    let numConnections : Int

    let acceptSocket : ListeningSocket
    var reg : BluetoothService.Registration!

    let regType = "_harp._tcp"


    // When these drop out, we should immediately start searching again until we connect up to numConnections:
    // TODO
    var commSockets : [CFSocket]

    init(numConnections: Int) {
        // First phase
        acceptSocket = ListeningSocket()
        numConnections = numConnections
        commSockets = []

        // Second phase
        acceptSocket.delegate = self
        acceptSocket.start()
    }

    func registerService() {
        assert(acceptSocket.port > 0, "accept socket has not been configured")
        reg = BluetoothService.Registration(format: regType, port: acceptSocket.port.littleEndian)
        reg.start()
    }

    // MARK: - SocketAcceptDelegate
    func didAccept(listeningSocket listeningSocket: ListeningSocket, connectedSocket: SocketComm) {

        assert(commSockets.count < numConnections, "We accepted a connection when we shouldn't have been listening for one")
        print("-------- accepted a socket ---- ")
//        commSockets.append(sock)
//        handshakeWith(sock)
    }

    private func handshakeWith(socket: CFSocket) {
//        // C interop with swift strings!  Awesome!
//        // Also see the String getBytes or getCString methods provided by Swift
//        let send = "hello world"
//        let sendData = CFDataCreateWithBytesNoCopy(nil, send, send.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), nil)
//        let err = CFSocketSendData(socket, nil, sendData, -1)
//        print("Socket send err is: \(err.rawValue)")
    }

}