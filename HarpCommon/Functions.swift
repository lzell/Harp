//
//  Functions.swift
//  OpenJoypadClient
//
//  Created by Lou Zell on 6/22/16.
//  Copyright © 2016 Lou Zell. All rights reserved.
//

// Global Functions

import Foundation


public func printAddress(address: sockaddr_in6) {
    var mutableAddress = address
    var ip = [CChar](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)
    inet_ntop(AF_INET6, &mutableAddress.sin6_addr, &ip, UInt32(ip.count))
    print(String.fromCString(ip)! + " port \(mutableAddress.sin6_port.littleEndian)")
}


public func toContext(refType : AnyObject) -> UnsafeMutablePointer<Void> {
    return UnsafeMutablePointer(Unmanaged.passUnretained(refType).toOpaque())
}

public func fromContext<T:AnyObject>(context: UnsafeMutablePointer<T>) -> T {
    let ptr = Unmanaged<T>.fromOpaque(COpaquePointer(context))
    let instance = ptr.takeUnretainedValue()
    return instance
}

