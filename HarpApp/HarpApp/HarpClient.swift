import Foundation
import HarpCommoniOS

protocol HarpClientDelegate : class {
    func hostRequestsController(controllerName: String, receiveAddress: sockaddr_in6)
    func hostDidDisconnect()
}

class HarpClient {
    var bluetoothServiceResolver : BluetoothService.Resolver!

    weak var delegate : HarpClientDelegate?

    private let kRequestUdpPortKey = "UDP-Port"
    private let kRequestProtocolVersionKey = "Protocol-Version"
    private let kRequestControllerNameKey = "Controller"

    let maxNumConcurrentConnections = 1
    var connections : [CFSocket]
    var pending : [CFSocket]

    init() {
        pending = []
        connections = []
    }

    func removeSocket(sock: CFSocket, inout from: [CFSocket]) {
        let _idx = from.indexOf() { $0 === sock }
        if let idx = _idx {
            from.removeAtIndex(idx)
        }
    }

    func stopResolver() {
        guard bluetoothServiceResolver != nil else { return }
        bluetoothServiceResolver.stop()
        bluetoothServiceResolver = nil
    }

    func startResolver() {
        guard bluetoothServiceResolver == nil else { return }
        bluetoothServiceResolver = BluetoothService.Resolver(format: "_harp._tcp")
        bluetoothServiceResolver.start() {  [weak self] (bluetoothService) in
            print("Resolved: \(bluetoothService.addresses.count) addresses.  Connecting to first...")
            self?.connectTo(bluetoothService.addresses[0])
            self?.stopResolver()
        }
    }

    func autoConnect() {
        startResolver()
    }

    func connectTo(addr: sockaddr_in6) {
        let psock = createConnectingTCPSocketWithConnectCallback(addr, toContext(self)) {
            (sock, type, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>)
            in

            let me = fromContext(UnsafeMutablePointer<HarpClient>(info))
            if type == .ConnectCallBack {
                if data == nil {
                    me.socketDidConnect(sock)
                } else {
                    // Data is a pointer to an SInt32 error code in this case
                    let errCode = UnsafePointer<Int32>(data).memory
                    perror(strerror(errCode))
                    // Perplexed by this.  I've only ever hit this assert on simulator.
                    // Remedy on simulator: Start Host, then start App
                    assert(false)
                }
            } else {
                let cfdata = fromContext(UnsafePointer<CFData>(data))
                if CFDataGetLength(cfdata) == 0 {
                    // With a connection-oriented socket, if the connection is broken from the
                    // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
                    // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
                    // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
                    // the data argument will be a CFDataRef of length 0.
                    me.socketDidDisconnect(sock)
                } else {
                    // Not putting in any protection about partial buffers! We'll
                    // see what happens in practice.
                    if let request = String(data:cfdata, encoding: NSUTF8StringEncoding) {
                        me.didReceiveInitialData(sock, request)
                    } else {
                        assert(false, "Receiving something other than a string.")
                    }
                }
            }
        }

        pending.append(psock)
    }

    func socketDidDisconnect(sock: CFSocket) {
        removeSocket(sock, from: &connections)
        delegate?.hostDidDisconnect()

        if connections.count < maxNumConcurrentConnections {
            print("Connections dropped below max concurrent, restarting the search...")
            startResolver()
        }
    }

    func socketDidConnect(sock: CFSocket) {
        removeSocket(sock, from: &pending)
        connections.append(sock)
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

    func didReceiveInitialData(sock: CFSocket, _ request: String) {
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
        delegate?.hostRequestsController(controllerName!, receiveAddress: sockAddr6)
    }


}