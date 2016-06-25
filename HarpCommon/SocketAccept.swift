//
//  SocketAccept.swift
//  HarpCommon
//
//  Created by Lou Zell on 6/24/16.
//
//

import Foundation


var __acceptedSock : CFSocket!


//typedef void (*CFSocketCallBack)(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
///* If the callback wishes to keep hold of address or data after the point that it returns, then it must copy them. */
//
// For an accept callback, the data parameter is a pointer to a CFSocketNativeHandle.
func socketCallback(sock: CFSocket!, type: CFSocketCallBackType, var address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {

    //    let origData : CFData! = UnsafePointer<CFData!>(data).memory
    //
    //    var moData = CFDataCreateCopy(nil, origData)
    //    // Is there a better way to cast this?
    //    let sockHandle : UnsafePointer<Int32> = withUnsafePointer(&moData) { (ptr: UnsafePointer<CFData!>) -> UnsafePointer<Int32> in
    //        return UnsafePointer<Int32>(ptr)
    //    }
    //
    let daOptions: CFSocketCallBackType = [.DataCallBack]
    let nativeHandle = UnsafePointer<Int32!>(data).memory
    print("Native handle is: \(nativeHandle)")

    __acceptedSock = CFSocketCreateWithNative(nil, nativeHandle, daOptions.rawValue, socketCallback, nil)
    var send = "hello world"

    // C interop with swift strings!  Awesome!
    // Also see the String getBytes method provided by swift
    // Or the getCString method
    var sendData = CFDataCreateWithBytesNoCopy(nil, "hello world", send.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), nil)
    let err = CFSocketSendData(__acceptedSock, nil, sendData, -1)
    print("ERR is: \(err.rawValue)")
    //    var sendCast : UnsafePointer<UInt8> = UnsafePointer<UInt8>(&send)
    //    var sendCast : UnsafePointer<CChar> = withUnsafePointer(send) { $0 }
    //    var sendData = CFDataCreate, <#T##bytes: UnsafePointer<UInt8>##UnsafePointer<UInt8>#>, <#T##length: CFIndex##CFIndex#>)

    //    var send : [UInt8] = [1]
    //    var sendData = CFDataCreateWithBytesNoCopy(nil, &send, 1, nil)

    //    let erraddr = CFSocketSetAddress(acceptedSock, address)
    //    print("erraddr is: \(erraddr.rawValue)")

    //    Unmanaged.passUnretained(address).toOpaque()
    //
    //    COpaquePointer(address)




    //    print("In socket callback, socket valid: \(CFSocketIsValid(acceptedSock))")
    //    print("Sending hello world")
    //    var toSend = "hello world".cStringUsingEncoding(NSUTF8StringEncoding)!
    //    withUnsafePointer(&toSend) { ptr in
    //        if CFSocketIsValid(acceptedSock) {
    //            let sendData = CFDataCreate(nil, UnsafePointer<UInt8>(ptr), toSend.count)
    //            // This keeps failing, maybe I need to connect first?
    //            var ip = [CChar](count: 256, repeatedValue: 0)
    ////            let addrPtr = withUnsafePointer(&address) { x in
    ////                print("hi")
    ////                return x
    ////            }
    ////            let addrPtr2 = UnsafePointer<CFData!>(Unmanaged.passUnretained(address).toOpaque())
    ////            assert(addrPtr == addrPtr2)
    ////            let sock6 = UnsafePointer<sockaddr_in6>(addrPtr)
    ////            var sin6_addr = sock6.memory.sin6_addr
    ////            inet_ntop(AF_INET6, &sin6_addr, &ip, UInt32(ip.count))
    ////            print("Remote address is: \(String.fromCString(ip)), port: \(sock6.memory.sin6_port.littleEndian)")
    //
    //            let err = CFSocketSendData(acceptedSock, nil, sendData, -1)
    //            print("Err is: \(err.rawValue)")
    //        } else {
    //            print("Sock is invalid???")
    //        }
    //    }
    //    Unmanaged.passRetained(sock)
    //    acceptedSock = sock
    //    let delay = 2.0
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
    //        sendIt()
    //    }


    //CFSocketSendData(acceptedSock, nil, data, 10)
    //    print("socket callback.. woooooooooooooooooooooooo doggggyyyy")
}


class SocketAccept {

    var underlying : CFSocket!

    var port : UInt16!

    init() {
        // let daOptions: CFSocketCallBackType = [.ReadCallBack, .AcceptCallBack, .DataCallBack, .ConnectCallBack, .WriteCallBack]
        let daOptions: CFSocketCallBackType = [.AcceptCallBack]
        print(daOptions.rawValue)
        var mutableSelf = self

        var ctxt = CFSocketContext(version: 0, info: &mutableSelf, retain: nil, release: nil, copyDescription: nil)
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