import Cocoa
import HarpCommonOSX


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    @IBOutlet weak var window: NSWindow!

    var bluetoothServiceResolver : BluetoothService.Resolver!
    var requestSocket : CFSocket!

    var udpReadSocket : CFSocket!
    var udpReadPort : UInt16!


    func applicationDidFinishLaunching(aNotification: NSNotification) {

        let (sock, port) = createBindedUDPReadSocketWithReadCallback(toContext(self)) {
            (_,_,_,data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) in
            print("READ UDP WHATUP")
        }
        udpReadSocket = sock
        udpReadPort = port
        print("Reading on UDP Port \(port)")


//        var sock6Addr = sockaddr_in6()
//        sock6Addr.sin6_len = UInt8(sizeof(sockaddr_in6))
//        sock6Addr.sin6_family = sa_family_t(AF_INET6)
//        sock6Addr.sin6_port = CFSwapInt16HostToBig(udpReadSocket.port)
//        sock6Addr.sin6_addr = in6addr_loopback
//
//
//       let readAddress = CFSocketCopyAddress(self.udpReadSocket.underlying)
//
//
//        let ptr : UnsafePointer<sockaddr_in6> = withUnsafePointer(&sock6Addr) { $0 }
//        // let cfdata = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(ptr), sizeof(sockaddr_in6))
//
//        var buf : [CChar] = [CChar](count: 1024, repeatedValue: 0)
//
//        let res = sendto(CFSocketGetNative(udpWriteSocket.underlying), "hello", "hello".lengthOfBytesUsingEncoding(NSUTF8StringEncoding), 0, UnsafePointer<sockaddr>(ptr), UInt32(sizeof(sockaddr_in6)))
//
//        print(res)
//
////        udpWriteSocket.sendTo(cfdata)
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
//            print(recv(CFSocketGetNative(self.udpReadSocket.underlying), &buf, 1, 0))
//            print("HI")
//        }



        bluetoothServiceResolver = BluetoothService.Resolver(format: "_harp._tcp")
        bluetoothServiceResolver.start() {  [weak self] (bluetoothService) in
            for sockAddr in bluetoothService.addresses {
                printAddress(sockAddr)
            }
            self?.connectTo(bluetoothService.addresses[0])
            self?.bluetoothServiceResolver.stop()
            self?.bluetoothServiceResolver = nil
        }
    }

    func connectTo(addr: sockaddr_in6) {
        // This should really be called something CommSocket(connectTo:)
        createConnectingTCPSocketWithConnectCallback(addr, toContext(self)) {
            (sock, _, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>)
            in

            let me = fromContext(UnsafeMutablePointer<AppDelegate>(info))

            if data == nil {
                print("Connected woooooop!")
                me.sendPayload(sock)
            } else {
                // Data is a pointer to an SInt32 error code in this case
                assert(false, "Connection failed")
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func sendPayload(sock: CFSocket) {
        // C interop with swift strings!  Awesome!
        // Also see the String getBytes or getCString methods provided by Swift
        let content = payload()

        let sendData = CFDataCreateWithBytesNoCopy(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
        if CFSocketSendData(sock, nil, sendData, -1) != .Success {
            assert(false, "Socket send failed")
        }
    }



    private func payload() -> String {
        return  "Protocol-Version: 0.1.0\n" +
                "UDP-Port: \(udpReadPort)\n" +
                "Controller: LZProto1"
    }

    func didRead() {
        print("UDP READ SOMETHING")
    }
}
