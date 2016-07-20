import Cocoa
import HarpCommonOSX


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    @IBOutlet weak var window: NSWindow!

    var bluetoothServiceResolver : BluetoothService.Resolver!
    var commSocket : CommSocket!
    var udpReadSocket : UDPReadSocket!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        udpReadSocket = UDPReadSocket()
        udpReadSocket.run()
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
                "Controller: proto_1"
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