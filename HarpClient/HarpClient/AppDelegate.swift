import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let service = Service(maxConcurrentConnections: 2, controllerName: "Proto1ViewController")

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        service.register()
        window.backgroundColor = NSColor.redColor()
    }

    // MARK: - Connection Manager Delegate
    func didEstablishConnection(playerNum: Int, playerName: String) {}
    func didDropConnection(playerNum: Int, playerName: String) {}
    func didReceivePlayerInput(playerNum: Int, bitpattern: UInt64) {}
}



