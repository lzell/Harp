import Foundation

// In our case, we use this for incoming connections (e.g. the listening socket has accepted
// a connection and handed us a native handle for the new connection)
private func createCFCommSocketFromNative(nativeHandle: Int32!, info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> CFSocket {

    let callbackOpts: CFSocketCallBackType = [.DataCallBack]
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: info, retain: nil, release: nil, copyDescription: nil)
    return CFSocketCreateWithNative(kCFAllocatorDefault, nativeHandle, callbackOpts.rawValue, callback, &sockCtxt)
}

// In our case, we use this after resolving a network service into a sockaddr_in6.  That is, we use this on the side
// looking for the Harp service.
private func createCFCommSocketConnectingToAddress(addr6: sockaddr_in6, info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> CFSocket {
    var mutableAddr6 = addr6
    let ptr : UnsafePointer<sockaddr_in6> = withUnsafePointer(&mutableAddr6) { $0 }
    let cfdata = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(ptr), sizeof(sockaddr_in6))
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: info, retain: nil, release: nil, copyDescription: nil)
    let callbackOpts : CFSocketCallBackType = [.DataCallBack, .ConnectCallBack]
    let sock = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, IPPROTO_TCP, callbackOpts.rawValue, callback, &sockCtxt)
    let err = CFSocketConnectToAddress(sock, cfdata, -1)
    print("Sock connect err is: \(err.rawValue)")
    return sock
}


private func createCFDatagramReadSocket(info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> CFSocket {
    // Use kCFSocketReadCallBack here instead of Data if we determine that letting CFNetwork
    // chunk in the data in the background isn't responsive enough for our application
    let callbackOpts : CFSocketCallBackType = [.ReadCallBack]
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: info, retain: nil, release: nil, copyDescription: nil)
    return CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_DGRAM, IPPROTO_UDP, callbackOpts.rawValue, callback, &sockCtxt)

}

// We aren't going to use callbacks for our udp write sockets.  We're not going to fill up the write buffer (the reason
// to use a callback is to be notified when there's more room in the write buffer)
private func createCFDatagramWriteSocket() -> CFSocket {
    let callbackOpts : CFSocketCallBackType = [.NoCallBack]
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: nil, retain: nil, release: nil, copyDescription: nil)
    return CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_DGRAM, IPPROTO_UDP, callbackOpts.rawValue, nil, &sockCtxt)

}


private func createCFAcceptSocket(info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> CFSocket {
    let callbackType: CFSocketCallBackType = [.AcceptCallBack]
    var sockCtxt = CFSocketContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
    return CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, IPPROTO_TCP, callbackType.rawValue, callback, &sockCtxt)
}

// See the "Listening with
private func bindCFSocketToAnyAddr(sock: CFSocket) -> UInt16 {
    var addr6Len = sizeof(sockaddr_in6)
    var anyAddress = sockaddr_in6()
    anyAddress.sin6_len = UInt8(addr6Len)
    anyAddress.sin6_family = sa_family_t(AF_INET6)
    anyAddress.sin6_port = CFSwapInt16HostToBig(UInt16(0))  // TODO: This swap is not necessary
    anyAddress.sin6_addr = in6addr_any

    let anyAddrPtr = withUnsafeMutablePointer(&anyAddress) {UnsafeMutablePointer<UInt8>($0)}

    let socketAddrData: CFDataRef = CFDataCreate(kCFAllocatorDefault, anyAddrPtr, addr6Len)
    let err: CFSocketError = CFSocketSetAddress(sock, socketAddrData)
    print("setting socket address err is: \(err.rawValue)")

    // I don't think this is necessary at all, actually.  It's in the "Listening with POSIX Socket APIs" section
    // TODO: cleanme
    // sinPtr and anyAddrPtr aren't any different, I think.
    withUnsafeMutablePointer(&addr6Len) { (addr6LenPtr) in
        if getsockname(CFSocketGetNative(sock), UnsafeMutablePointer<sockaddr>(anyAddrPtr), UnsafeMutablePointer<socklen_t>(addr6LenPtr)) < 0 {
            print("Socket error")
        }
    }

    print("port number is: \(CFSwapInt16BigToHost(anyAddress.sin6_port))")
    return CFSwapInt16BigToHost(anyAddress.sin6_port)
}

// Note that binding a UDP socket using CFSocketSetAddress throws the "CFSocketSetAddress listen failure: 102"
// error.  Binding using the native handle:
private func bindCFUDPSocketToAnyAddr(sock: CFSocket) -> UInt16 {

    let handle : CFSocketNativeHandle = CFSocketGetNative(sock)

    var addr6Len = sizeof(sockaddr_in6)
    var anyAddress = sockaddr_in6()     // memset required?
    anyAddress.sin6_len = UInt8(addr6Len)
    anyAddress.sin6_family = sa_family_t(AF_INET6)
    anyAddress.sin6_port = CFSwapInt16HostToBig(UInt16(0))      // TODO: This swap is not necessary
    anyAddress.sin6_addr = in6addr_any

    let anyAddrPtr = withUnsafeMutablePointer(&anyAddress) {$0}

    let err = bind(handle, UnsafePointer<sockaddr>(anyAddrPtr), UInt32(addr6Len))

    withUnsafeMutablePointer(&addr6Len) { (addr6LenPtr) in
        if getsockname(CFSocketGetNative(sock), UnsafeMutablePointer<sockaddr>(anyAddrPtr), UnsafeMutablePointer<socklen_t>(addr6LenPtr)) < 0 {
            print("Socket error")
        }
    }

    print("Err is \(err)")
    return CFSwapInt16BigToHost(anyAddress.sin6_port)
}


// If the callback wishes to keep hold of address or data after the point that it returns, then it must copy them.
// For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
private func acceptCallback(sock: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {
    assert(type == .AcceptCallBack, "Unexpected callback type")
    let listeningSock = fromContext(UnsafeMutablePointer<ListeningSocket>(info))
    assert(listeningSock.underlying === sock, "Unexpected CF socket")
    listeningSock._didAccept(UnsafePointer<Int32!>(data).memory)
}

// I'm ignoring the fact that we could get notified of this callback before a full request
// has been buffered in (or we could pick up part of the next request).  Seeing how it works
// in practice.  This may be good enough for now.
//
private func autoReadCallback(sock: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {
    assert([CFSocketCallBackType.DataCallBack, CFSocketCallBackType.ConnectCallBack].contains(type), "Unexpected callback type")
    let commSocket = fromContext(UnsafeMutablePointer<CommSocket>(info))
    assert(commSocket.underlying === sock, "Unexpected CF socket")
    switch type {
    case CFSocketCallBackType.DataCallBack:
        let unmanaged : Unmanaged<CFData> = Unmanaged.fromOpaque(COpaquePointer(data))
        let cfdata = unmanaged.takeUnretainedValue()
        if CFDataGetLength(cfdata) == 0 {
            print("Disconnected!")
            // TODO: We've disconnected
            // With a connection-oriented socket, if the connection is broken from the
            // other end, then one final kCFSocketReadCallBack or kCFSocketDataCallBack
            // will occur.  In the case of kCFSocketReadCallBack, the underlying socket
            // will have 0 bytes available to read.  In the case of kCFSocketDataCallBack,
            // the data argument will be a CFDataRef of length 0.

        } else {
            commSocket._didRead(String(data:cfdata, encoding: NSUTF8StringEncoding)!)
        }
    case CFSocketCallBackType.ConnectCallBack:
        // In this case the data argument is either NULL, or a pointer to
        // an SInt32 error code if the connect failed
        commSocket._didConnect()
    default:
        assert(false)
    }
}

private func udpReadCallback(sock: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {
    assert(type == .ReadCallBack, "Unexpected callback type")
    let udpReadSocket = fromContext(UnsafeMutablePointer<UDPReadSocket>(info))
    assert(udpReadSocket.underlying === sock, "Unexpected CF socket")
    print("UDP socket did read")
}




public protocol CommSocketDelegate : class {
    func didConnect(commSocket: CommSocket)
    func didRead(commSocket: CommSocket, request: String)
}

// TODO: I don't like this design
public class CommSocket : HarpSocket {
    public weak var delegate : CommSocketDelegate?

    public init(nativeHandle: Int32!) {
        super.init()
        underlying = createCFCommSocketFromNative(nativeHandle, info: toContext(self), callback: autoReadCallback)
    }

    public init(addr6: sockaddr_in6) {
        super.init()
        underlying = createCFCommSocketConnectingToAddress(addr6, info: toContext(self), callback: autoReadCallback)
    }

    private func _didConnect() {
        delegate?.didConnect(self)
    }

    private func _didRead(str: String) {
        delegate?.didRead(self, request: str)
    }

    public func send(content: String) {
        // C interop with swift strings!  Awesome!
        // Also see the String getBytes or getCString methods provided by Swift
        let sendData = CFDataCreateWithBytesNoCopy(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
//        let sendData = CFDataCreate(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), nil)
        if CFSocketSendData(underlying, nil, sendData, -1) != .Success {
            print("Socket send failed")
        }
    }

    public func peerAddress() -> sockaddr_in6 {
        let data = CFSocketCopyPeerAddress(underlying)
        let ptr = UnsafeMutablePointer<sockaddr_in6>(CFDataGetBytePtr(data))
        return ptr.memory
    }
}


public protocol ListeningSocketDelegate : class {
    func didAccept(listeningSocket listeningSocket: ListeningSocket, connectedSocket: CommSocket)
}

public class ListeningSocket : HarpSocket {
    public var port: UInt16!
    public weak var delegate : ListeningSocketDelegate?

    override public init() {
        // First phase
        super.init()

        // Second phase
        underlying = createCFAcceptSocket(toContext(self), callback: acceptCallback)
        port = bindCFSocketToAnyAddr(underlying)

        var on: UInt32 = 1
        if setsockopt(CFSocketGetNative(underlying), SOL_SOCKET, SO_REUSEADDR, &on, UInt32(sizeofValue(1))) != 0 {
            assert(false)
        }
    }

    func _didAccept(nativeHandle: Int32!) {
        print("Listening socket accepted new connection.  New native handle is: \(nativeHandle)")
        print("Creating comm socket...")
        let commSock = CommSocket(nativeHandle: nativeHandle)
        delegate?.didAccept(listeningSocket: self, connectedSocket: commSock)
    }
}

public protocol UDPReadSocketDelegate : class {
    func didRead()
}

public class UDPReadSocket : HarpSocket {
    public var port : UInt16!
    public weak var delegate : UDPReadSocketDelegate?

    public override init() {
        super.init()
        underlying = createCFDatagramReadSocket(toContext(self), callback: udpReadCallback)
        port = bindCFUDPSocketToAnyAddr(underlying)
        print("UDP port is: \(port)")
    }

    public func listen() {
        run()
    }
}


public class UDPWriteSocket : HarpSocket {
    public override init() {
        super.init()
        underlying = createCFDatagramWriteSocket()
    }

    public override func run() {
        // Deliberately empty.  Not using callbacks for our write sockets
    }

    public func sendTo(addr6: CFData) {
        // C interop with swift strings!  Awesome!
        // Also see the String getBytes or getCString methods provided by Swift
        let sendData = CFDataCreateWithBytesNoCopy(nil, "foo", "foo".lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
        //        let sendData = CFDataCreate(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), nil)
        if CFSocketSendData(underlying, addr6, sendData, -1) != .Success {
            print("UDP Socket send failed")
        } else {
            print("Sent something via UDP")
        }
    }
}


public class HarpSocket {
    public var underlying : CFSocket!
    private var running : Bool = false
    private var runLoopSourceRef : CFRunLoopSourceRef!

    public func run() {
        if !running {
            running = true
            runLoopSourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, underlying, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSourceRef,kCFRunLoopDefaultMode)
        }
    }

    // TODO: DRY THIS
    public func stop() {
        if running {
            running = false
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSourceRef, kCFRunLoopDefaultMode)
        }
    }

    deinit {
        stop()
        CFSocketInvalidate(underlying)
    }
}