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
        // When we get to UDP packets: Use kCFSocketReadCallBack here instead of Data if we determine that letting CFNetwork
        // chunk in the data in the background isn't responsive enough for our application
        let callbackOpts : CFSocketCallBackType = [.DataCallBack, .ConnectCallBack]
        let sock = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, IPPROTO_TCP, callbackOpts.rawValue, callback, &sockCtxt)
        let err = CFSocketConnectToAddress(sock, cfdata, -1)
        print("Sock is: \(sock), connect err is: \(err.rawValue)")
        return sock
}


private func autoReadCallback(sock: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {

    if type == CFSocketCallBackType.DataCallBack {
        let ptr = COpaquePointer(data)
        let unmanaged : Unmanaged<CFData> = Unmanaged.fromOpaque(ptr)
        let cfdata = unmanaged.takeUnretainedValue()    // Does this leak?
        print("Data available of length: \(CFDataGetLength(cfdata))")
        print(String(data:cfdata, encoding: NSUTF8StringEncoding)!)
    } else if type == CFSocketCallBackType.ConnectCallBack {
        print("Socket connected")
    }
}


public class SocketComm {

    var underlying : CFSocket!

    private var running : Bool = false
    private var runLoopSourceRef : CFRunLoopSourceRef!


    public init(nativeHandle: Int32!) {
        underlying = createCFCommSocketFromNative(nativeHandle, info: toContext(self), callback: autoReadCallback)
    }

    public init(addr6: sockaddr_in6) {
        underlying = createCFCommSocketConnectingToAddress(addr6, info: toContext(self), callback: autoReadCallback)
    }

    public func start() {
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

