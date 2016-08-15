import Foundation
import HarpCommoniOS

struct HandshakeInfo {
    let protocolVersion : String
    let udpReceiveAddress : sockaddr_in6
}

protocol HarpClientDelegate : class {
    func didFind(host: Host)
    func didEstablishConnectionTo(host: Host, withHandshakeInfo handshakeInfo: HandshakeInfo)
    func didFailToConnectTo(host: Host)
    func didDisconnectFrom(host: Host)
    func didReceiveRequestForController(name: String, from host:Host)
}

class HarpClient {

    weak var delegate : HarpClientDelegate?

    private var bluetoothServiceResolver : BluetoothService.Resolver!
    private var cxn : (sock: CFSocket, host: Host)?

    private let kRequestUdpPortKey = "udpPort"
    private let kRequestProtocolVersionKey = "protocolVersion"
    private let kRequestControllerNameKey = "controllerName"
    private let kRequestHeaderHandshake = "handshake"
    private let kRequestHeaderControllerChange = "controllerChange"


    func startSearchForHarpHosts() {
        startResolver()
    }

    func stopSearchingForHarpHosts() {
        stopResolver()
    }

    func connectToHost(host: Host) {
        assert(cxn == nil, "Assuming we only connect to one host")
        assert(host.addresses.count > 0, "Need at least one address")
        let addr = host.addresses.first!
        let sock = createConnectingTCPSocketWithConnectCallback(addr, toContext(self)) { (sock, type, _, data, info) in
            let me = fromContext(UnsafeMutablePointer<HarpClient>(info))
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

    var circleBuf = CircularBuffer()

    static let maxMessageSize = 1024
    static let workingBufLen = 2 * maxMessageSize
    var workingBuf = CFDataCreateMutable(nil, workingBufLen)
    var idx : Int = 0

    private func decipherSocketCallback(sock: CFSocket, _ type: CFSocketCallBackType, _ data: UnsafePointer<Void>) {
        if type == .ConnectCallBack {
            // In this case the data argument is either NULL, or a pointer to
            // an SInt32 error code if the connect failed
            if data == nil {
                socketDidConnect(sock)
            } else {
                let errCode = UnsafePointer<Int32>(data).memory
                socketDidFailToConnect(sock, err: strerror(errCode))
            }

        } else if type == .DataCallBack {
            // With a connection-oriented socket, if the connection is broken from the
            // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
            // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
            // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
            // the data argument will be a CFDataRef of length 0.
            let cfdata = fromContext(UnsafePointer<CFData>(data))
            let datalen = CFDataGetLength(cfdata)
            if  datalen == 0 {
                socketDidDisconnect(sock)
            } else {
                // CFNetworking chunked some data in on our behalf.  Maybe we got a full packet maybe not.
                // Appending all data to a circular buf and reading from head:
                circleBuf.append(cfdata, len: datalen)
                let headerSize = sizeof(UInt16.self)
                while let packLenBytes = circleBuf.peakTail(headerSize) {
                    // Get length of packet msg
                    var header : UInt16 = 0
                    CFDataGetBytes(packLenBytes, CFRangeMake(0, headerSize), withUnsafeMutablePointer(&header) { UnsafeMutablePointer<UInt8>($0) })
                    let packetLen = Int(header)
                    if circleBuf.lengthStored >= packetLen + headerSize {
                        _ = circleBuf.read(headerSize)
                        let packetMsg = circleBuf.read(packetLen)
                        let packetMsgBytePtr = CFDataGetBytePtr(packetMsg)
                        let msg = String(UTF8String: UnsafePointer<CChar>(packetMsgBytePtr))
                        socketDidRead(sock, msg!)
                    } else {
                        break
                    }
                }
            }

        } else {
            assert(false)
        }
    }


    private func socketDidConnect(sock: CFSocket) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)
    }

    private func socketDidFailToConnect(sock: CFSocket, err: UnsafePointer<Int8>) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)
        perror(err)
        // Perplexed by this.  I've only ever hit this assert on simulator.
        // Remedy on simulator: Start Host, then start App
        assert(false)
        notifyDidFailToConnectToHost(cxn!.host)
        cxn = nil
    }

    private func socketDidDisconnect(sock: CFSocket) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)
        notifyDidDisconnectFromHost(cxn!.host)
        CFSocketInvalidate(cxn!.sock)   // Is this necessary?
        cxn = nil
    }

    // Building in an assumption that the only read we get from the host is initial data.
    private func socketDidRead(sock: CFSocket, _ msg: String) {
        assert(cxn != nil)
        assert(cxn!.sock === sock)

        let (header, body) = parseRequest(msg)
        switch header {
        case kRequestHeaderControllerChange:
            let controllerName = body[kRequestControllerNameKey]
            assert(controllerName != nil)
            notifyDidReceiveRequestForController(controllerName!, from: cxn!.host)
        case kRequestHeaderHandshake:
            let handshakeInfo = createHandshakeInfo(body, referenceSock: cxn!.sock)
            notifyDidEstablishConnectionToHost(cxn!.host, withHandshakeInfo: handshakeInfo)
        default:
            assert(false)
        }
    }


    // MARK: - Utils

    private func parseRequest(request: String) -> (String, [String:String]) {
        var body : [String:String] = [:]
        var lines : [String] = request.componentsSeparatedByString("\n")
        let header = lines.removeFirst()
        lines.forEach { (line) in
            let pair = line.componentsSeparatedByString(":").map() { (comp) in stripWhitespace(comp) }
            body[pair[0]] = pair[1]
        }
        return (header, body)
    }


    // We construct the remote UDP socket address based on the TCP address of a reference socket, with 
    // the only overrided property being port.
    private func createHandshakeInfo(dict: [String:String], referenceSock: CFSocket) -> HandshakeInfo {
        let udpPortStr = dict[kRequestUdpPortKey]
        let protoVersion = dict[kRequestProtocolVersionKey]

        assert(udpPortStr != nil)
        assert(protoVersion != nil)

        let receivePort = UInt16(udpPortStr!)!
        let data = CFSocketCopyPeerAddress(referenceSock)
        var sadd : sockaddr_in6 = valuePtrCast(CFDataGetBytePtr(data)).memory
        sadd.sin6_port = CFSwapInt16HostToBig(receivePort)

        return HandshakeInfo(protocolVersion: protoVersion!, udpReceiveAddress: sadd)
    }


    // MARK: - Outgoing

    func notifyDidFindHost(host: Host) {
        delegate?.didFind(host)
    }

    func notifyDidDisconnectFromHost(host: Host) {
        delegate?.didDisconnectFrom(host)
    }

    func notifyDidFailToConnectToHost(host: Host) {
        delegate?.didFailToConnectTo(host)
    }

    func notifyDidEstablishConnectionToHost(host: Host, withHandshakeInfo handshakeInfo: HandshakeInfo) {
        delegate?.didEstablishConnectionTo(host, withHandshakeInfo: handshakeInfo)
    }

    func notifyDidReceiveRequestForController(name: String, from host: Host) {
        delegate?.didReceiveRequestForController(name, from: host)
    }
}
