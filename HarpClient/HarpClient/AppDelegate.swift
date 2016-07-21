import Cocoa
import HarpCommonOSX


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    @IBOutlet weak var window: NSWindow!

    var bluetoothServiceResolver : BluetoothService.Resolver!
    var commSocket : CommSocket!
    var udpReadSocket : UDPReadSocket!

    // TODO: DeleteME
    var udpWriteSocket : UDPWriteSocket!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        udpReadSocket = UDPReadSocket()
        udpReadSocket.run()

//        let delay = 2.0
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
//            let data = CFSocketCopyAddress(self.udpReadSocket.underlying)
//            let ptr = UnsafeMutablePointer<sockaddr_in6>(CFDataGetBytePtr(data))
//            printAddress(ptr.memory)
//        }


        udpWriteSocket = UDPWriteSocket()
        udpWriteSocket.run()

        var sock6Addr = sockaddr_in6()
        sock6Addr.sin6_len = UInt8(sizeof(sockaddr_in6))
        sock6Addr.sin6_family = sa_family_t(AF_INET6)
        sock6Addr.sin6_port = CFSwapInt16HostToBig(udpReadSocket.port)
        sock6Addr.sin6_addr = in6addr_loopback


       let readAddress = CFSocketCopyAddress(self.udpReadSocket.underlying)




        let ptr : UnsafePointer<sockaddr_in6> = withUnsafePointer(&sock6Addr) { $0 }
        // let cfdata = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(ptr), sizeof(sockaddr_in6))

        var buf : [CChar] = [CChar](count: 1024, repeatedValue: 0)

        let res = sendto(CFSocketGetNative(udpWriteSocket.underlying), "hello", "hello".lengthOfBytesUsingEncoding(NSUTF8StringEncoding), 0, UnsafePointer<sockaddr>(ptr), UInt32(sizeof(sockaddr_in6)))

        print(res)

//        udpWriteSocket.sendTo(cfdata)

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            print(recv(CFSocketGetNative(self.udpReadSocket.underlying), &buf, 1, 0))
            print("HI")
        }



//        bluetoothServiceResolver = BluetoothService.Resolver(format: "_harp._tcp")
//        bluetoothServiceResolver.start() {  [weak self] (bluetoothService) in
//            for sockAddr in bluetoothService.addresses {
//                printAddress(sockAddr)
//            }
//            self?.connectTo(bluetoothService.addresses[0])
//            self?.bluetoothServiceResolver.stop()
//            self?.bluetoothServiceResolver = nil
//        }
    }

    func connectTo(addr: sockaddr_in6) {
        commSocket = CommSocket(addr6: addr)
        commSocket.delegate = self
        commSocket.run()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func payload() -> String {
        return  "Protocol-Version: 0.1.0\n" +
                "UDP-Port: \(udpReadSocket.port)\n" +
                "Controller: LZProto1"
    }
}


extension AppDelegate : CommSocketDelegate {
    func didConnect(commSocket: CommSocket) {
        commSocket.send(payload())
    }

    func didRead(commSocket: CommSocket, request: String) {
        print("Got a message from the server: \(request)")
        // The server doesn't send us anything at the moment.
    }
}