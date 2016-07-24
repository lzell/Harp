import Foundation

public func createBindedTCPListeningSocketWithAcceptCallback(context: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> (CFSocket, UInt16) {

    // Create socket:
    let callbackType: CFSocketCallBackType = [.AcceptCallBack]
    var sockCtxt = CFSocketContext(version: 0, info: context, retain: nil, release: nil, copyDescription: nil)
    let sock = CFSocketCreate(kCFAllocatorDefault,
                              AF_INET6,
                              SOCK_STREAM,
                              IPPROTO_TCP,
                              callbackType.rawValue,
                              callback,
                              &sockCtxt)

    var sockOpts = CFSocketGetSocketFlags(sock)
    sockOpts |= kCFSocketCloseOnInvalidate
    CFSocketSetSocketFlags(sock, sockOpts)


    // Give it an ipv6 address:
    var addr6In = sockaddr_in6(sin6_len: UInt8(sizeof(sockaddr_in6)),
                               sin6_family: sa_family_t(AF_INET6),
                               sin6_port: CFSwapInt16HostToBig(0),
                               sin6_flowinfo: 0,
                               sin6_addr: in6addr_any,
                               sin6_scope_id: 0)
    let addr6InPtr : UnsafeMutablePointer<UInt8> = valuePtrCast(&addr6In)
    let socketAddrData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, addr6InPtr, sizeofValue(addr6In), kCFAllocatorNull)
    if (CFSocketSetAddress(sock, socketAddrData) != .Success) {
        assert(false, "Could not set socket address")
    }

    // Find what port we're listening on.  See the "Listening with POSIX Socket APIs" section of "Network Programming Topics":
    var addrOut = sockaddr_in6()
    var lenOut : socklen_t = socklen_t(sizeof(sockaddr_in6))

    // The address_len parameter should be initialized to indicate the amount of space pointed to by address.
    // On return it contains the actual size of the address returned (in bytes)
    if getsockname(CFSocketGetNative(sock), withUnsafePointer(&addrOut) {UnsafeMutablePointer<sockaddr>($0)}, &lenOut) < 0 {
        assert(false, "Could not get socket address")
    }
    let port = CFSwapInt16BigToHost(addrOut.sin6_port)
    assert(port > 0, "Could not get a listening port")

    // Add this cf socket to the runloop so we get callbacks
    addSocketToRunLoop(sock)

    return (sock, port)
}


/* Connecting */
public func createConnectingTCPSocketWithConnectCallback(connectTo: sockaddr_in6, _ info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> CFSocket {
    let callbackOpts : CFSocketCallBackType = [.ConnectCallBack]
    // This is repeated all over the place:
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: info, retain: nil, release: nil, copyDescription: nil)

    var mutableAddr6 = connectTo
    let ptr : UnsafePointer<sockaddr_in6> = withUnsafePointer(&mutableAddr6) { $0 }
    let cfdata = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(ptr), sizeof(sockaddr_in6))
    let sock = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, IPPROTO_TCP, callbackOpts.rawValue, callback, &sockCtxt)

    var sockOpts = CFSocketGetSocketFlags(sock)
    sockOpts |= kCFSocketCloseOnInvalidate
    CFSocketSetSocketFlags(sock, sockOpts)

    if CFSocketConnectToAddress(sock, cfdata, -1) != .Success {
        assert(false, "Could not issue connectToAddress call")
    }

    addSocketToRunLoop(sock)
    return sock
}


/* Connected */
public func createConnectedTCPSocketFromNativeHandleWithDataCallback(nativeHandle: Int32!, _ info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> CFSocket {

    let callbackOpts: CFSocketCallBackType = [.DataCallBack]
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: info, retain: nil, release: nil, copyDescription: nil)
    let sock = CFSocketCreateWithNative(kCFAllocatorDefault, nativeHandle, callbackOpts.rawValue, callback, &sockCtxt)
    var sockOpts = CFSocketGetSocketFlags(sock)
    sockOpts |= kCFSocketCloseOnInvalidate
    CFSocketSetSocketFlags(sock, sockOpts)


    addSocketToRunLoop(sock)

    return sock
}



public func createBindedUDPReadSocketWithReadCallback(info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> (CFSocket, UInt16) {

    // Note we can switch this to Data and let CFNetwork chunk the data in for us:
    let callbackOpts : CFSocketCallBackType = [.ReadCallBack]
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: info, retain: nil, release: nil, copyDescription: nil)
    let sock = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_DGRAM, IPPROTO_UDP, callbackOpts.rawValue, callback, &sockCtxt)

    var sockOpts = CFSocketGetSocketFlags(sock)
    sockOpts |= kCFSocketCloseOnInvalidate | kCFSocketAutomaticallyReenableReadCallBack
    CFSocketSetSocketFlags(sock, sockOpts)


    /* Bind it */
    // Note that binding a UDP socket using CFSocketSetAddress throws the "CFSocketSetAddress listen failure: 102"
    // error.  Binding using the native handle:
    let handle : CFSocketNativeHandle = CFSocketGetNative(sock)

    var addr6Len = sizeof(sockaddr_in6)
    var anyAddress = sockaddr_in6()
    anyAddress.sin6_len = UInt8(addr6Len)
    anyAddress.sin6_family = sa_family_t(AF_INET6)
    anyAddress.sin6_port = CFSwapInt16HostToBig(UInt16(0))          // This swap is unnecessary
    anyAddress.sin6_addr = in6addr_any

    let anyAddrPtr = withUnsafeMutablePointer(&anyAddress) {$0}
    let err = bind(handle, UnsafePointer<sockaddr>(anyAddrPtr), UInt32(addr6Len))

    var lenOut : socklen_t = socklen_t(sizeof(sockaddr_in6))

    if getsockname(handle, withUnsafePointer(&anyAddress) {UnsafeMutablePointer<sockaddr>($0)}, &lenOut) < 0 {
        assert(false, "Could not get socket address")
    }
    let port = CFSwapInt16BigToHost(anyAddress.sin6_port)
    assert(port > 0, "Could not get a reading port")

    addSocketToRunLoop(sock)

    return (sock, port)
}


// We aren't going to use callbacks for our udp write sockets.  We're not going to fill up the write buffer (the reason
// to use a callback is to be notified when there's more room in the write buffer)
public func createUDPWriteSocket() -> CFSocket {
    let callbackOpts : CFSocketCallBackType = [.NoCallBack]
    var sockCtxt = CFSocketContext(version: CFIndex(0), info: nil, retain: nil, release: nil, copyDescription: nil)
    let sock = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_DGRAM, IPPROTO_UDP, callbackOpts.rawValue, nil, &sockCtxt)
    var sockOpts = CFSocketGetSocketFlags(sock)
    sockOpts |= kCFSocketCloseOnInvalidate
    CFSocketSetSocketFlags(sock, sockOpts)
    return sock
}

public func createSendData(msg: String) -> CFData {
    return CFDataCreateWithBytesNoCopy(nil, msg, msg.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
}


// MARK: - Private
private func addSocketToRunLoop(sock: CFSocket) {
    let runLoopSourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, sock, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSourceRef, kCFRunLoopDefaultMode)
}

private func setReuseAddress(sock: CFSocket) {
    var on: UInt32 = 1
    if setsockopt(CFSocketGetNative(sock), SOL_SOCKET, SO_REUSEADDR, &on, UInt32(sizeofValue(1))) != 0 {
        assert(false)
    }
}