// Todo
// ====
// Determine application rules around when to stop accepting new connections
//
import Foundation
import HarpCommoniOS

protocol ConnectionManagerDelegate : class {
    func clientRequestsController(controllerName: String, receiveAddress: sockaddr_in6)
}



class ConnectionManager {

    private let kRequestUdpPortKey = "UDP-Port"
    private let kRequestProtocolVersionKey = "Protocol-Version"
    private let kRequestControllerNameKey = "Controller"

    weak var delegate : ConnectionManagerDelegate?

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
        maxNumConnections = numConnections
        connectedSockets = []

        // Second phase
        let (sock, port) = createBindedTCPListeningSocketWithAcceptCallback(toContext(self)) {
            (_, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<ConnectionManager>(info))
            // For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle:
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
        let udpPortStr = dict[kRequestUdpPortKey]
        let controllerName = dict[kRequestControllerNameKey]
        let _ = dict[kRequestProtocolVersionKey]

        assert(udpPortStr != nil)
        assert(controllerName != nil)

        // We construct the remote UDP socket address based on the TCP address; the only
        // property we overwrite is the port:
        let receivePort = UInt16(udpPortStr!)!
        let data = CFSocketCopyPeerAddress(sock)
        let sockAddr6Ptr = UnsafeMutablePointer<sockaddr_in6>(CFDataGetBytePtr(data))
        var sockAddr6 = sockAddr6Ptr.memory
        sockAddr6.sin6_port = CFSwapInt16HostToBig(receivePort)
        delegate?.clientRequestsController(controllerName!, receiveAddress: sockAddr6)
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