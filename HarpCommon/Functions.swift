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
    return UnsafeMutablePointer(Unmanaged.passUnretained(refType).toOpaque())
}

public func fromContext<T:AnyObject>(context: UnsafeMutablePointer<T>) -> T {
    return Unmanaged<T>.fromOpaque(COpaquePointer(context)).takeUnretainedValue()
}

// Overload, same implementation.  There's probably a better way using generics and _PointerType
public func fromContext<T:AnyObject>(context: UnsafePointer<T>) -> T {
    return Unmanaged<T>.fromOpaque(COpaquePointer(context)).takeUnretainedValue()
}

public func valuePtrCast<T>(voidPtr: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<T> {
    return UnsafeMutablePointer<T>(voidPtr)
}

public func valuePtrCast<T>(voidPtr: UnsafePointer<Void>) -> UnsafePointer<T> {
    return UnsafePointer<T>(voidPtr)
}

// MARK: - String Helpers

public func stripWhitespace(str: String) -> String {
    return String(str.characters.filter() {$0 != " "})
}
