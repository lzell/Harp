import Cocoa
import HarpCommonOSX


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ServiceDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet var textView: NSTextView!

    let service = Service(maxConcurrentConnections: 2, controllerName: "Proto1ViewController", inputTranslator: Proto1InputTranslator())

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        service.delegate = self
        service.register()
        log("Started Service for \(service.maxConcurrentConnections) players...")
    }


    // MARK: - ServiceDelegate
    func didReceiveControllerInput(state: ControllerState, forPlayer playerNum: Int) {
        let s = state as! Proto1ControllerState
        log("Player \(playerNum):  Dpad: \(s.dpadState)  B: \(s.bButtonState)  A: \(s.aButtonState)")
    }

    func didConnectToPlayer(playerNum: Int) {
        log("Player: \(playerNum) connected")
    }

    func didDisconnectFromPlayer(playerNum: Int) {
        log("Player: \(playerNum) disconnected")
    }

    // MARK: -
    private func log(msg: String) {
        print(msg)
        textView.insertText(msg, replacementRange: textView.selectedRange())
        textView.insertNewline(nil)
    }
}