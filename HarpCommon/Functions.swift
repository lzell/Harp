//
//  Functions.swift
//  OpenJoypadClient
//
//  Created by Lou Zell on 6/22/16.
//  Copyright © 2016 Lou Zell. All rights reserved.
//

// Global Functions

import Foundation


// MARK: - Socket helpers
public func printAddress(address: sockaddr_in6) {
    var mutableAddress = address
    var ip = [CChar](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)
    inet_ntop(AF_INET6, &mutableAddress.sin6_addr, &ip, UInt32(ip.count))
    print(String.fromCString(ip)! + " port \(CFSwapInt16BigToHost(mutableAddress.sin6_port))")
}


// MARK: - Working With C
public func toContext(refType : AnyObject) -> UnsafeMutablePointer<Void> {
    // Is it possible to use this instead:
//    var secondRef = refType
//    return ptrCast(&secondRef)
    return UnsafeMutablePointer(Unmanaged.passUnretained(refType).toOpaque())
}

public func fromContext<T:AnyObject>(context: UnsafeMutablePointer<T>) -> T {
    let ptr = Unmanaged<T>.fromOpaque(COpaquePointer(context))
    let instance = ptr.takeUnretainedValue()
    return instance
}

// Overload, same implementation.  Probably a better way w generics
public func fromContext<T:AnyObject>(context: UnsafePointer<T>) -> T {
    let ptr = Unmanaged<T>.fromOpaque(COpaquePointer(context))
    let instance = ptr.takeUnretainedValue()
    return instance
}

// For reference types, these do not match:
// unsafeAddressOf(f) and

// This is safe to use w/ value types.  Here's what I don't understand: this ptrCast should 
// in theory work with reference and value types, but it doesn't. With a reference type, I would
// expect the returned pointer to be to the same memory address as Unmanaged.passUnretained(refType).toOpaque().
// Why is this not true?
public func valuePtrCast<T>(voidPtr: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<T> {
    return UnsafeMutablePointer<T>(voidPtr)
}

// MARK: - String Helpers
public func stripWhitespace(str: String) -> String {
    return String(str.characters.filter() {$0 != " "})
}

