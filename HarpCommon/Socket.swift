import Foundation


private func createCFAcceptSocket(info: UnsafeMutablePointer<Void>, callback: CFSocketCallBack) -> CFSocket {
    let callbackType: CFSocketCallBackType = [.AcceptCallBack]
    var sockCtxt = CFSocketContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
    return CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, IPPROTO_TCP, callbackType.rawValue, callback, &sockCtxt)
}

private func bindCFSocketToAnyAddr(sock: CFSocket) -> UInt16 {
    var addr6Len = sizeof(sockaddr_in6)
    var anyAddress = sockaddr_in6()
    anyAddress.sin6_len = UInt8(addr6Len)
    anyAddress.sin6_family = sa_family_t(AF_INET6)
    anyAddress.sin6_port = UInt16(0).bigEndian
    anyAddress.sin6_addr = in6addr_any

    let anyAddrPtr = withUnsafeMutablePointer(&anyAddress) {UnsafeMutablePointer<UInt8>($0)}

    let socketAddrData: CFDataRef = CFDataCreate(kCFAllocatorDefault, anyAddrPtr, addr6Len)
    CFSocketSetAddress(sock, socketAddrData);

    // TODO: cleanme
    // sinPtr and anyAddrPtr aren't any different, I think.
    withUnsafeMutablePointer(&addr6Len) { (addr6LenPtr) in
        if getsockname(CFSocketGetNative(sock), UnsafeMutablePointer<sockaddr>(anyAddrPtr), UnsafeMutablePointer<socklen_t>(addr6LenPtr)) < 0 {
            print("Socket error")
        }
    }

    print("port number is: \(anyAddress.sin6_port.littleEndian)")
    return anyAddress.sin6_port.littleEndian
}


// If the callback wishes to keep hold of address or data after the point that it returns, then it must copy them.
// For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
private func acceptCallback(sock: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {
    assert(type == .AcceptCallBack, "Unexpected callback type")
    let listeningSock = fromContext(UnsafeMutablePointer<ListeningSocket>(info))
    assert(listeningSock.underlying === sock, "Unexpected socket")
    listeningSock._didAccept(UnsafePointer<Int32!>(data).memory)
}

//@objc public protocol SocketDelegate : class {
//    optional func didAccept(listeningSocket: Socket, connectedSocket: Socket)
//    optional func didConnect(socket: Socket)
//    optional func didWrite(socket: Socket, data: NSData)
//    optional func didRead(socket: Socket, data: NSData)
//    optional func didFailAccept(listeningSocket: Socket)
//    optional func didFailConnect(socket: Socket)
//    optional func didFailWrite(socket: Socket)
//    optional func didFailRead(socket: Socket)
//}

public protocol ListeningSocketDelegate : class {
    func didAccept(listeningSocket listeningSocket: ListeningSocket, connectedSocket: SocketComm)
}


public class ListeningSocket {
    public var port: UInt16!
    private var underlying : CFSocket!
    public weak var delegate : ListeningSocketDelegate?
    private var runLoopSourceRef : CFRunLoopSourceRef!

    private var running : Bool = false

    public init() {
        // First phase
        // Second phase
        underlying = createCFAcceptSocket(toContext(self), callback: acceptCallback)
        port = bindCFSocketToAnyAddr(underlying)

        var on: UInt32 = 1
        if setsockopt(CFSocketGetNative(underlying), SOL_SOCKET, SO_REUSEADDR, &on, UInt32(sizeofValue(1))) != 0 {
            assert(false)
        }

    }

    public func start() {
        if !running {
            running = true
            runLoopSourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, underlying, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSourceRef, kCFRunLoopDefaultMode)
        }
    }

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

    func _didAccept(nativeHandle: Int32!) {
        print("Listening socket accepted new connection.  New native handle is: \(nativeHandle)")
        print("Creating comm socket...")
        let commSock = SocketComm(nativeHandle: nativeHandle)
        delegate?.didAccept(listeningSocket: self, connectedSocket: commSock)
    }
}
