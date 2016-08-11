import Cocoa
import HarpCommonOSX


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ServiceDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet var textView: NSTextView!

    @IBAction func switchToController1(sender: AnyObject) {
        service.setController(name: "Proto1ViewController", inputTranslator: Proto1InputTranslator() /*, forPlayer: playerNum */)
    }

    @IBAction func switchToController2(sender: AnyObject) {
        service.setController(name: "Proto2ViewController", inputTranslator: Proto2InputTranslator() /*, forPlayer: playerNum */)
    }


    let service = Service(maxConcurrentConnections: 2)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        service.delegate = self
        service.register()
        log("Started Service for \(service.maxConcurrentConnections) players...")
    }


    // MARK: - ServiceDelegate
    func didReceiveControllerInput(_ state: ControllerState, forPlayer playerNum: Int) {
        if let s = state as? Proto1ControllerState {
            log("Player \(playerNum):  Dpad: \(s.dpadState)  B: \(s.bButtonState)  A: \(s.aButtonState)")
        } else if let s = state as? Proto2ControllerState {
            log("Player \(playerNum):  AnalogStick x: \(s.stickState.xNormalized) y: \(s.stickState.yNormalized)  A: \(s.aButtonState)")
        }
    }

    func didConnectToPlayer(_ playerNum: Int) {
        service.setController(name: "Proto1ViewController", inputTranslator: Proto1InputTranslator() /*, forPlayer: playerNum */)
        log("Player: \(playerNum) connected")
    }

    func didDisconnectFromPlayer(_ playerNum: Int) {
        log("Player: \(playerNum) disconnected")
    }

    // MARK: -
    private func log(_ msg: String) {
        print(msg)
        textView.insertText(msg, replacementRange: textView.selectedRange())
        textView.insertNewline(nil)
    }
}
