import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let harpClient = HarpClient()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        harpClient.startResolver()
    }

}
