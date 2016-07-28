import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let cxnManager = ConnectionManager(numConnections: 1)


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        cxnManager.registerService()
    }
}
