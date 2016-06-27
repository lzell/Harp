//
//  SocketAccept.swift
//  HarpCommon
//
//  Created by Lou Zell on 6/24/16.
//
//

import Foundation




//typedef void (*CFSocketCallBack)(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
///* If the callback wishes to keep hold of address or data after the point that it returns, then it must copy them. */
//
// For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
func socketCallback(sock: CFSocket!, type: CFSocketCallBackType, var address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {

    assert(type == .AcceptCallBack, "Unexpected callback type")
    let sockObj = fromContext(UnsafeMutablePointer<SocketAccept>(info))
    assert(sockObj.underlying === sock, "Unexpected socket")
    sockObj._didAccept(UnsafePointer<Int32!>(data).memory)
}

public protocol SocketAcceptDelegate : class {
    func didAccept(nativeHandle: Int32!)
}


public class SocketAccept {

    var underlying : CFSocket!
    public weak var delegate : SocketAcceptDelegate?

    public var port : UInt16!

    func _didAccept(nativeHandle: Int32!) {
        delegate?.didAccept(nativeHandle)
    }




    public init() {
        // let daOptions: CFSocketCallBackType = [.ReadCallBack, .AcceptCallBack, .DataCallBack, .ConnectCallBack, .WriteCallBack]
        let daOptions: CFSocketCallBackType = [.AcceptCallBack]
        print(daOptions.rawValue)

//        var mutableSelf = self

        var ctxt = CFSocketContext(version: 0, info: toContext(self), retain: nil, release: nil, copyDescription: nil)
        underlying = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, IPPROTO_TCP, daOptions.rawValue, socketCallback, &ctxt)

        var zeroAddress = sockaddr_in6()
        zeroAddress.sin6_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin6_family = sa_family_t(AF_INET6)
        zeroAddress.sin6_port = UInt16(0).bigEndian
        zeroAddress.sin6_addr = in6addr_any // INADDR_ANY

        let thePointer = withUnsafeMutablePointer(&zeroAddress) {UnsafeMutablePointer<UInt8>($0)}

        let sincfd: CFDataRef = CFDataCreate(
            kCFAllocatorDefault,
            thePointer,
            sizeofValue(zeroAddress));

        CFSocketSetAddress(underlying, sincfd);

        let socketsource : CFRunLoopSourceRef  = CFSocketCreateRunLoopSource(
            kCFAllocatorDefault,
            underlying,
            0);

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            socketsource,
            kCFRunLoopDefaultMode);

        let theNativeSocket = CFSocketGetNative(underlying)

        var addrLen = socklen_t(sizeofValue(zeroAddress))
        withUnsafeMutablePointers(&zeroAddress, &addrLen) { (sinPtr, addrPtr) in


            if getsockname(theNativeSocket, UnsafeMutablePointer(sinPtr), UnsafeMutablePointer(addrPtr)) < 0 {
                print("Socket error")
            }
        }

        print("port number is: \(zeroAddress.sin6_port.littleEndian)")
        self.port = zeroAddress.sin6_port.littleEndian

        // not sure if this is right
        var x = 1
        let truePtr = withUnsafePointer(&x) { $0 }
        setsockopt(CFSocketGetNative(underlying), SOL_SOCKET, SO_REUSEADDR, truePtr, UInt32(sizeofValue(1)))
    }


    deinit {
        CFSocketInvalidate(underlying)
    }
}