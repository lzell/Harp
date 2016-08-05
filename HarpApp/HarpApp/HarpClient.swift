import Foundation
import HarpCommoniOS

struct HandshakeInfo {
    let protocolVersion : String
    let controllerName : String
    let udpReceiveAddress : sockaddr_in6
}

protocol HarpClientDelegate : class {
    func didFindHost(_ host: Host)
    func didEstablishConnectionToHost(_ host: Host, withHandshakeInfo handshakeInfo: HandshakeInfo)
    func didFailToConnectToHost(_ host: Host)
    func didDisconnectFromHost(_ host: Host)
}

class HarpClient {

    weak var delegate : HarpClientDelegate?

    private var bluetoothServiceResolver : BluetoothService.Resolver!
    private var cxn : (sock: CFSocket, host: Host)?

    private let kRequestUdpPortKey = "UDP-Port"
    private let kRequestProtocolVersionKey = "Protocol-Version"
    private let kRequestControllerNameKey = "Controller"


    func startSearchForHarpHosts() {
        startResolver()
    }

    func stopSearchingForHarpHosts() {
        stopResolver()
    }

    func connectToHost(_ host: Host) {
        assert(cxn == nil, "Assuming we only connect to one host")
        assert(host.addresses.count > 0, "Need at least one address")
        let addr = host.addresses.first!
        let sock = createConnectingTCPSocketWithConnectCallback(addr, toContext(self)) { (sock, type, _, data, info) in
            let me = fromContext(UnsafeMutablePointer<HarpClient>(info!))
            me.decipherSocketCallback(sock!, type, data)
        }
        cxn = (sock, host)
    }

    // Note that invalidating a connected CF socket does not trigger the zero-data-length
    // callback that we otherwise use to detect and surface a disconnected socket.  We'll
    // notify the delegate ourselves.
    func closeAnyConnections() {
        if let (sock, host) = cxn {
            let shouldNotify = CFSocketIsValid(sock)
            CFSocketInvalidate(sock)
            if shouldNotify {
                notifyDidDisconnectFromHost(host)
            }
            cxn = nil
        }
    }


    // MARK: -

    private func stopResolver() {
        guard bluetoothServiceResolver != nil else { return }
        bluetoothServiceResolver.stop()
        bluetoothServiceResolver = nil
    }

    private func startResolver() {
        guard bluetoothServiceResolver == nil else { return }
        bluetoothServiceResolver = BluetoothService.Resolver(format: "_harp._tcp")
        bluetoothServiceResolver.start(notifyDidFindHost)
    }


    // MARK: - Internal Socket handling

    private func decipherSocketCallback(_ sock: CFSocket, _ type: CFSocketCallBackType, _ data: UnsafePointer<Void>?) {
        if type == .connectCallBack {
            // In this case the data argument is either NULL, or a pointer to
            // an SInt32 error code if the connect failed
            if data == nil {
                socketDidConnect(sock)
            } else {
                let errCode = UnsafePointer<Int32>(data!).pointee
                socketDidFailToConnect(sock, err: strerror(errCode))
            }

        } else if type == .dataCallBack {
            // With a connection-oriented socket, if the connection is broken from the
            // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
            // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
            // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
            // the data argument will be a CFDataRef of length 0.
            let cfdata = fromContext(UnsafePointer<CFData>(data!))
            if CFDataGetLength(cfdata) == 0 {
                socketDidDisconnect(sock)
            } else {
                // Not putting in any protection about partial buffers! We'll
                // see what happens in practice.
                if let msg = String(data:cfdata as Data, encoding: String.Encoding.utf8) {
                    socketDidRead(sock, msg)
                } else {
                    assert(false, "Receiving something other than a string.")
                }
            }

        } else {
            assert(false)
        }
    }


    private func socketDidConnect(_ sock: CFSocket) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)
    }

    private func socketDidFailToConnect(_ sock: CFSocket, err: UnsafePointer<Int8>) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)
        perror(err)
        // Perplexed by this.  I've only ever hit this assert on simulator.
        // Remedy on simulator: Start Host, then start App
        assert(false)
        notifyDidFailToConnectToHost(cxn!.host)
        cxn = nil
    }

    private func socketDidDisconnect(_ sock: CFSocket) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)
        notifyDidDisconnectFromHost(cxn!.host)
        CFSocketInvalidate(cxn!.sock)   // Is this necessary?
        cxn = nil
    }

    // Building in an assumption that the only read we get from the host is initial data.
    private func socketDidRead(_ sock: CFSocket, _ msg: String) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)

        let handshakeInfo = createHandshakeInfo(parseRequest(msg), referenceSock: cxn!.sock)
        notifyDidEstablishConnectionToHost(cxn!.host, withHandshakeInfo: handshakeInfo)
    }


    // MARK: - Utils

    private func parseRequest(_ request: String) -> [String:String] {
        var ret : [String:String] = [:]
        let lines : [String] = request.components(separatedBy: "\n")
        lines.forEach { (line) in
            let pair = line.components(separatedBy: ":").map() { (comp) in stripWhitespace(comp) }
            ret[pair[0]] = pair[1]
        }
        return ret
    }


    // We construct the remote UDP socket address based on the TCP address of a reference socket, with 
    // the only overrided property being port.
    private func createHandshakeInfo(_ dict: [String:String], referenceSock: CFSocket) -> HandshakeInfo {
        let udpPortStr = dict[kRequestUdpPortKey]
        let controllerName = dict[kRequestControllerNameKey]
        let protoVersion = dict[kRequestProtocolVersionKey]

        assert(udpPortStr != nil)
        assert(controllerName != nil)
        assert(protoVersion != nil)

        let receivePort = UInt16(udpPortStr!)!
        let data = CFSocketCopyPeerAddress(referenceSock)
        var sadd : sockaddr_in6 = valuePtrCast(CFDataGetBytePtr(data)).pointee
        sadd.sin6_port = CFSwapInt16HostToBig(receivePort)

        return HandshakeInfo(protocolVersion: protoVersion!, controllerName: controllerName!, udpReceiveAddress: sadd)
    }


    // MARK: - Outgoing

    func notifyDidFindHost(_ host: Host) {
        delegate?.didFindHost(host)
    }


    func notifyDidDisconnectFromHost(_ host: Host) {
        delegate?.didDisconnectFromHost(host)
    }

    func notifyDidFailToConnectToHost(_ host: Host) {
        delegate?.didFailToConnectToHost(host)
    }

    func notifyDidEstablishConnectionToHost(_ host: Host, withHandshakeInfo handshakeInfo: HandshakeInfo) {
        delegate?.didEstablishConnectionToHost(host, withHandshakeInfo: handshakeInfo)
    }
}
