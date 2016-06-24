//
//  SocketComm.swift
//  OpenJoypadClient
//
//  Created by Lou Zell on 6/21/16.
//  Copyright © 2016 Lou Zell. All rights reserved.
//

// TODO: I suspect this doesn't teardown well

import Foundation

class SocketComm {

    // How can I make sock a let and satisfy initialization requirements?
    var sock : CFSocket!

    init(addr6: sockaddr_in6) {
        var mutableAddr6 = addr6
        var mutableSelf = self
        let ptr : UnsafePointer<sockaddr_in6> = withUnsafePointer(&mutableAddr6) { $0 }
        let cfdata = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(ptr), sizeof(sockaddr_in6))
        //let sig = CFSocketSignature(protocolFamily: AF_INET6, socketType: SOCK_STREAM, protocol: IPPROTO_IP, address: Unmanaged.passRetained(cfdata))
        var sockContext = CFSocketContext(version: CFIndex(0), info: &mutableSelf, retain: nil, release: nil, copyDescription: nil)

        // When we get to UDP packets: Use kCFSocketReadCallBack here instead of Data if we determine that letting CFNetwork
        // chunk in the data in the background isn't responsive enough for our application
        let callbackOpts : UInt = 4 | 3    // kCFSocketConnectCallBack and kCFSocketDataCallBack are "unresolved"?

        sock = CFSocketCreate(kCFAllocatorDefault, AF_INET6, SOCK_STREAM, IPPROTO_TCP, callbackOpts, getSocketCallback(), &sockContext)
        let socketsource6 = CFSocketCreateRunLoopSource(
            kCFAllocatorDefault,
            sock,
            0);

        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            socketsource6,
            kCFRunLoopDefaultMode)

        let err = CFSocketConnectToAddress(sock, cfdata, -1)
        //        sock = CFSocketCreateConnectedToSocketSignature(kCFAllocatorDefault, &sig, UInt(callbackOpts), getSocketCallback(), &sockContext, 100)
        print("Sock is: \(sock), connect err is: \(err.rawValue)")


    }

    deinit {
        CFSocketInvalidate(sock)
        print("BYEEEEEEEEEEEEEE")

    }

    private func getSocketCallback() -> CFSocketCallBack {

        let c : CFSocketCallBack = { (socket: CFSocket!, callbackType: CFSocketCallBackType, address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
            if callbackType == CFSocketCallBackType.DataCallBack {
                let ptr = COpaquePointer(data)
                let unmanaged : Unmanaged<CFData> = Unmanaged.fromOpaque(ptr)
                let cfdata = unmanaged.takeUnretainedValue()    // Does this leak?
                print("Data available of length: \(CFDataGetLength(cfdata))")
                print(String(data:cfdata, encoding: NSUTF8StringEncoding)!)
            } else if callbackType == CFSocketCallBackType.ConnectCallBack {
                print("Socket connected")
            }
        }
        return c
    }
}

