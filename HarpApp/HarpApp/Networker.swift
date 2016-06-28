// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommoniOS


func socketCallback(sock: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {
    assert(type == .DataCallBack, "Unexpected callback type")
    print("WHATEVER")
    //    let sockObj = fromContext(UnsafeMutablePointer<SocketAccept>(info))
    //    assert(sockObj.underlying === sock, "Unexpected socket")
    //    sockObj._didAccept(UnsafePointer<Int32!>(data).memory)
}


class Networker : SocketAcceptDelegate {

    let numConnections : Int

    var reg : BluetoothService.Registration!
    let regType = "_harp._tcp"

    var acceptSocket : SocketAccept!

    // When these drop out, we will immediately start searching again until we connect up to numConnections:
    var commSockets : [CFSocket]

    init(numConnections: Int) {
        self.numConnections = numConnections
        self.commSockets = []
    }

    func sync() {
        acceptSocket = SocketAccept()
        acceptSocket.delegate = self
        reg = BluetoothService.Registration(format: regType, port: acceptSocket.port.littleEndian)
        reg.start()
    }


    // MARK: - SocketAcceptDelegate
    func didAccept(nativeHandle: Int32!) {
        assert(commSockets.count < numConnections, "We accepted a connection when we shouldn't have been listening for one")
        print("Listening socket accepted new connection.  New native handle is: \(nativeHandle)")
        print("Creating comm socket...")
        let callbackType: CFSocketCallBackType = [.DataCallBack]
        let sock = CFSocketCreateWithNative(nil, nativeHandle, callbackType.rawValue, socketCallback, nil)
        commSockets.append(sock)
        handshakeWith(sock)
    }

    private func handshakeWith(socket: CFSocket) {
        // C interop with swift strings!  Awesome!
        // Also see the String getBytes or getCString methods provided by Swift
        let send = "hello world"
        let sendData = CFDataCreateWithBytesNoCopy(nil, send, send.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), nil)
        let err = CFSocketSendData(socket, nil, sendData, -1)
        print("Socket send err is: \(err.rawValue)")
    }

}