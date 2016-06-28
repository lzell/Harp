// Usage
// =====
// Clients of BluetoothService.Registration and BluetoothService.Resolver are responsible for calling -stop.
// I.e. there is no auto-stop functionality when a service registers or resolves.
//
//
// Todo
// ====
// Supposed to release peer connection with:
// let err = PeerConnectionRelease(0x0, self.name, self.regType, self.domain)
// print("Release error: \(err)")
//
// Notes
// =====
// Do not mix CFSocket-related code in with this collection of classes.  These classes should be used in conjunction
// with TCP and UDP Sockets found in HarpCommon.


#if os(OSX)
    import DNSSD_Map_OSX
#elseif os(iOS)
    #if (arch(i386) || arch(x86_64))
        import DNSSD_Map_Sim
    #else
        import DNSSD_Map_iOS
    #endif
#endif



import Foundation

private func DnsDispatchQueue() -> dispatch_queue_t! { return dispatch_get_main_queue() }

private func printDebug(str: String) {
    if true {
        print(str)
    }
}


public struct BluetoothServiceResult {
    public let name : String
    public let addresses : [sockaddr_in6]
}


public class BluetoothService {

    struct NetServiceIdentifier : CustomDebugStringConvertible {
        let name: String
        let regType: String
        let domain: String
        var debugDescription : String {
            return "\n\tname: \(name)\n\tregType: \(regType)\n\tdomain: \(domain)"
        }
    }

    public class Registration {
        private let registrar : Registrar
        private var running : Bool = false

        public init(format: String, port: UInt16) {
            registrar = Registrar(format: format, port: port)
            pluginRegistrationHandling()
        }

        private func pluginRegistrationHandling() {
            registrar.registered = { (service) in
                print("HI HI HI HI")
                print("Registered \(service.name)")
            }
        }

        public func start() {
            if !running {
                running = true
                registrar.start()
            }
        }

        public func stop() {
            if running {
                registrar.stop()
            }
        }

        deinit {
            if running {
                registrar.stop()
            }
            print("Registration helper is going away")
        }
    }

    public class Resolver {
        private let browser : Browser
        private var hostResolvers : [HostAndPortResolver]
        private var addressResolvers : [IPV6Resolver]
        private var consumer : ((BluetoothServiceResult) -> Void)?
        private var running : Bool = false

        public init(format: String) {
            // First phase:
            browser = Browser(format: format)
            hostResolvers = []
            addressResolvers = []

            // Second phase:
            pluginBrowserHandling()
        }


        //
        // MARK: - Public API
        //

        public func start(consumer: (service: BluetoothServiceResult) -> Void) {
            if !running {
                running = true
                self.consumer = consumer
                browser.start()
            }
        }

        public func stop() {
            if running {
                running = false
                consumer = nil
                browser.stop()
                hostResolvers.forEach { $0.stop() }
                hostResolvers = []
                addressResolvers.forEach { $0.stop() }
                addressResolvers = []
            }
        }

        //
        // MARK: - Private
        //
        private func pluginBrowserHandling() {
            browser.found = { [weak self] (serviceIdentifier) in

                // Upon finding a service we immediately progress down the chain to resolving its
                // host and port.  We assume that if the browser is running then the client is
                // looking for more controllers to connect to.
                self?.resolveHostAndPortOfService(serviceIdentifier)
            }

            // Removed is unused.  We should not use this as a cue to use that the client is no longer
            // interested in a connection.  They may have stopped dns registration once a connection to
            // us was established.
            browser.removed = { (_) in  }
        }

        // We only need the resolvers to live for the amount of time that it takes them to resolve.
        // Set the resolved callback, and in the body remove the strong reference to hostAndPortResolver:
        private func resolveHostAndPortOfService(serviceIdentifier: NetServiceIdentifier) {
            let hostAndPortResolver = HostAndPortResolver(serviceIdentifier: serviceIdentifier)
            hostAndPortResolver.resolved = { [weak self] (resolver: HostAndPortResolver, hosttarget: String, port: UInt16) in
                if let safeSelf = self {
                    safeSelf.resolveAddress(hosttarget, port)
                    safeSelf.hostResolvers = safeSelf.hostResolvers.filter() { $0 !== resolver }
                }
            }
            self.hostResolvers.append(hostAndPortResolver)
            hostAndPortResolver.start()
        }

        // The same logic that we used in the host and port resolvers applies here.  That is, only
        // let address resolvers live for the amount of time it takes to get output from them.
        //
        // Note that when we get multiple addresses on the same resolve, they have different sin6_scope_ids.
        // Maybe we can glean something interesting from this?
        private func resolveAddress(hosttarget: String, _ port: UInt16) {
            let addressResolver = IPV6Resolver(hosttarget: hosttarget, port: port)
            var addressList = [sockaddr_in6]()
            addressResolver.resolved = { [weak self] (ipv6Resolver: IPV6Resolver, address: sockaddr_in6, moreComing: Bool) in
                if let safeSelf = self {
                    addressList.append(address)
                    if !moreComing {
                        // If there's no more coming, we are ready to notify the consumer:
                        safeSelf.consumer?(BluetoothServiceResult(name: "foo", addresses: [address]))
                        safeSelf.addressResolvers = safeSelf.addressResolvers.filter() {$0 !== ipv6Resolver}
                        addressList = []
                    }
                }
            }
            self.addressResolvers.append(addressResolver)
            addressResolver.start()
        }
        
        deinit {
            if (running) {
                stop()
            }
            print("\(self) is going away!")
        }
    }



    // MARK: - Nested Types
    public class Service {
        var ref : DNSServiceRef = nil
        let interfaceIndex : UInt32 = UInt32() &- 3 // Allow overflow; this is equivalent to kDNSServiceInterfaceIndexP2P

        private func dnsCall() -> DNSServiceErrorType {
            assert(false)
        }

        func start() {
            guard ref == nil else {
                print("\(self) service already started! Bailing")
                return
            }

            var err = dnsCall()

            guard err == Int32(kDNSServiceErr_NoError) else {
                print("\(self) dns call failed")
                return
            }

            err = DNSServiceSetDispatchQueue(ref, DnsDispatchQueue());
            guard err == Int32(kDNSServiceErr_NoError) else {
                print("\(self) setting dispatch queue failed")
                return
            }
        }

        deinit {
            if (ref != nil) {
                DNSServiceRefDeallocate(ref)
            }
            print("\(self) service is going away")
        }

        func stop() {
            DNSServiceRefDeallocate(ref)
            ref = nil
        }
    }

    class Registrar : Service {
        let format : String
        // Plug me in!
        var registered : (serviceID: NetServiceIdentifier) -> Void
        let port : UInt16


        init(format: String, port: UInt16) {
            self.format = format
            self.port = port
            registered = { (_) in assert(false) }
        }


        deinit {
            print("Registrar is going away!")
        }

        // There has got to be a more concise way to do this...
        private func registrarCallback() -> DNSServiceRegisterReply {
            return { (sdRef, flags, errorCode, name, regType, domain, context) in
                let registrar = fromContext(UnsafeMutablePointer<Registrar>(context))
                registrar.handleRegisterResult(sdRef, flags, errorCode, name, regType, domain)
            }
        }

        private func handleRegisterResult(sdRef: DNSServiceRef,
                                        _ flags: DNSServiceFlags,
                                        _ errorCode: DNSServiceErrorType,
                                        _ name: UnsafePointer<CChar>,
                                        _ regType: UnsafePointer<CChar>,
                                        _ domain: UnsafePointer<CChar>) {

            guard errorCode == 0 else {
                fatalError("Registration error code: \(errorCode)")
            }

            let name = String.fromCString(name)!
            let regType = String.fromCString(regType)!
            let domain = String.fromCString(domain)!
            registered(serviceID: NetServiceIdentifier(name: name, regType: regType, domain: domain))
        }


        override func dnsCall() -> DNSServiceErrorType {
            return DNSServiceRegister(
                &ref,
                UInt32(kDNSServiceFlagsIncludeP2P),
                interfaceIndex,
                nil,
                format,
                "local",
                nil,
                port.bigEndian,
                0,
                nil,
                registrarCallback(),
                UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque()))
        }
    }


    class Browser : Service {
        let format : String

        // Plug me in!
        var found : (serviceID: NetServiceIdentifier) -> Void
        var removed : (serviceID: NetServiceIdentifier) -> Void

        init(format: String) {
            self.format = format
            found = { (_) in assert(false) }
            removed = { (_) in assert(false) }
        }

        override private func dnsCall() -> DNSServiceErrorType {
            return DNSServiceBrowse(&ref,
                                 UInt32(kDNSServiceFlagsDenyExpensive | kDNSServiceFlagsDenyCellular | kDNSServiceFlagsIncludeP2P),
                                 interfaceIndex,
                                 format,
                                 nil,
                                 browseCallback(),
                                 toContext(self))
        }

        // There has got to be a more concise way to do this...
        private func browseCallback() -> DNSServiceBrowseReply {
            return { (sdRef, flags, interfaceIndex, errorCode, serviceName, regType, replyDomain, context) in
                let browser = fromContext(UnsafeMutablePointer<Browser>(context))
                browser.handleBrowseResult(sdRef, flags, interfaceIndex, errorCode, serviceName, regType, replyDomain)
            }
        }

        private func handleBrowseResult(sdRef: DNSServiceRef,
                                        _ flags: DNSServiceFlags,
                                        _ interfaceIndex: UInt32,
                                        _ errorCode: DNSServiceErrorType,
                                        _ serviceName: UnsafePointer<CChar>,
                                        _ regType: UnsafePointer<CChar>,
                                        _ replyDomain: UnsafePointer<CChar>) {

            guard errorCode == 0 else {
                fatalError("Browse error code: \(errorCode)")
            }

            let serviceName = String.fromCString(serviceName)!
            let regType = String.fromCString(regType)!
            let domain = String.fromCString(replyDomain)!
            if (flags & UInt32(kDNSServiceFlagsAdd) != 0) {
                found(serviceID: NetServiceIdentifier(name: serviceName, regType: regType, domain: domain))
            } else {
                removed(serviceID: NetServiceIdentifier(name: serviceName, regType: regType, domain: domain))
            }
        }
    }


    class HostAndPortResolver : Service {

        let serviceIdentifier : NetServiceIdentifier

        // Plug me in!
        var resolved : (resolver: HostAndPortResolver, hosttarget: String, port: UInt16) -> Void

        init(serviceIdentifier: NetServiceIdentifier) {
            self.serviceIdentifier = serviceIdentifier
            resolved = { (_,_,_) in assert(false) }
        }

        override private func dnsCall() -> DNSServiceErrorType {
            return DNSServiceResolve(&ref,
                                     UInt32(kDNSServiceFlagsIncludeP2P),
                                     interfaceIndex,
                                     serviceIdentifier.name,
                                     serviceIdentifier.regType,
                                     serviceIdentifier.domain,
                                     resolveCallback(),
                                     toContext(self))
        }

        private func resolveCallback() -> DNSServiceResolveReply {
            return { (sdRef, flags, interfaceIndex, errorCode, fullname, hosttarget, port, txtLen, txtRecord, context) in
                let resolver = fromContext(UnsafeMutablePointer<HostAndPortResolver>(context))
                resolver.handleResolveResult(sdRef, flags, interfaceIndex, errorCode, fullname, hosttarget, port, txtLen, txtRecord)
            }
        }

        private func handleResolveResult(sdRef: DNSServiceRef,
                                         _ flags: DNSServiceFlags,
                                         _ interfaceIndex: UInt32,
                                         _ errorCode: DNSServiceErrorType,
                                         _ fullname: UnsafePointer<CChar>,
                                         _ hosttarget: UnsafePointer<CChar>,
                                         _ port: UInt16,
                                         _ txtLen: UInt16,
                                         _ txtRecord: UnsafePointer<CUnsignedChar>) {

            guard errorCode == 0 else {
                fatalError("Resolver error code \(errorCode)")
            }
            resolved(resolver: self, hosttarget: String.fromCString(hosttarget)!, port: port.littleEndian)
        }
    }

    class IPV6Resolver : Service {
        let hosttarget : String
        let port : UInt16

        // Plug me in!
        var resolved : (ipv6Resolver: IPV6Resolver, address: sockaddr_in6, moreComing: Bool) -> Void


        init(hosttarget: String, port: UInt16) {
            self.hosttarget = hosttarget
            self.port = port
            resolved = { (_,_,_) in assert(false) }
        }

        override private func dnsCall() -> DNSServiceErrorType {
            return DNSServiceGetAddrInfo(&ref,
                                         UInt32(kDNSServiceFlagsServiceIndex | kDNSServiceFlagsDenyExpensive | kDNSServiceFlagsDenyCellular | kDNSServiceFlagsUnicastResponse),
                                         interfaceIndex,
                                         UInt32(kDNSServiceProtocol_IPv6),
                                         hosttarget,
                                         addressReplyCallback(),
                                         toContext(self))
        }

        func addressReplyCallback() -> DNSServiceGetAddrInfoReply {
            return { (sdRef, flags, interfaceIndex, errorCode, hostname, address, ttl, context) in
                let resolver = fromContext(UnsafeMutablePointer<IPV6Resolver>(context))
                resolver.handleAddressReply(sdRef, flags, interfaceIndex, errorCode, hostname, address, ttl)
            }
        }


        private func handleAddressReply(sdRef: DNSServiceRef,
                                        _ flags: DNSServiceFlags,
                                        _ interfaceIndex: UInt32,
                                        _ errorCode: DNSServiceErrorType,
                                        _ hostname: UnsafePointer<Int8>,
                                        _ address: UnsafePointer<sockaddr>,
                                        _ ttl: UInt32) {
            guard errorCode == 0 else {
                fatalError("Address reply failed with error \(errorCode)")
            }
            let moreComing = (flags & UInt32(kDNSServiceFlagsMoreComing) != 0)

            // Cast address to address 6
            let addr6Ptr = UnsafePointer<sockaddr_in6>(address)

            // Get a copy of it
            let tmp = addr6Ptr.memory
            var addrCpy = tmp

            // Set the port
            addrCpy.sin6_port = self.port.bigEndian
            resolved(ipv6Resolver: self, address: addrCpy, moreComing: moreComing)
        }
    }
}