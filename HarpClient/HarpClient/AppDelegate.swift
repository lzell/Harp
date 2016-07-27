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
            (sock, _, _, _, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<AppDelegate>(info))
            me.doRead(sock)
        }
        udpReadSocket = sock
        udpReadPort = port
        print("Reading on UDP Port \(port)")

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


    private func doRead(sock: CFSocket) {
        var buf = [UInt8](count: 8, repeatedValue: 0)
        let bytesRead = recv(CFSocketGetNative(sock), &buf, buf.count, 0)
        var posixErr: Int32 = 0

        if (bytesRead < 0) {
            posixErr = errno
        } else if (bytesRead == 0) {
            posixErr = EPIPE
        } else {
            assert(bytesRead == 8)
            var state: UInt64 = UInt64(buf[0])
            for i in 1..<8 {
                state <<= 8
                state |= UInt64(buf[i])
            }
          print("State is: \(String(state, radix: 16))")
        }

        if (posixErr != 0) {
            assert(false, "Could not read udp data")
        }
    }



    private func payload() -> String {
        return  "Protocol-Version: 0.1.0\n" +
                "UDP-Port: \(udpReadPort)\n" +
                "Controller: Proto1ViewController"
    }
}
