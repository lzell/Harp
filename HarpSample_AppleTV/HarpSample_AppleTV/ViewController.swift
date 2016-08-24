import UIKit
import HarpTvOS

class ViewController: UIViewController, HarpServiceDelegate {

    let service = HarpService(maxConcurrentConnections: 2)
    @IBOutlet weak var textView : UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        service.delegate = self
        service.register()
        textView.font = UIFont(name: "Menlo", size: 24) // fixed width
        log("Started Service for \(service.maxConcurrentConnections) players, waiting for them to join...")
    }
    
    // MARK: -

    @IBAction func switchToController1(sender: AnyObject) {
        service.setController("Proto1ViewController", inputTranslator: Proto1InputTranslator() /*, forPlayer: playerNum */)
    }

    @IBAction func switchToController2(sender: AnyObject) {
        service.setController("Proto2ViewController", inputTranslator: Proto2InputTranslator() /*, forPlayer: playerNum */)
    }


    // MARK: - HarpServiceDelegate

    func didConnectToPlayer(playerNum: Int) {
        service.setController("Proto1ViewController", inputTranslator: Proto1InputTranslator() /*, forPlayer: playerNum */)
        log("Player: \(playerNum) connected")
    }

    func didDisconnectFromPlayer(playerNum: Int) {
        log("Player: \(playerNum) disconnected")
    }

    func didReceiveControllerInput(state: ControllerState, forPlayer playerNum: Int) {
        if let state = state as? Proto1ControllerState {

            /* Do something with Proto1 controller input */

            log(message(forPlayer: playerNum, controllerState: state))
        } else if let state = state as? Proto2ControllerState {

            /* Do something with Proto2 controller input */

            log(message(forPlayer: playerNum, controllerState: state))
        }
    }


    // MARK: -

    private func log(msg: String) {
        print(msg)
        textView.insertText("\(msg)\n")
        textView.scrollRangeToVisible(NSRange(location: textView.text.characters.count - 1, length: 0))
    }

    private func message(forPlayer playerNum: Int, controllerState: Proto1ControllerState) -> String {
        // Pad the dpad string
        let dpadStr = "\(controllerState.dpadState),".nulTerminatedUTF8.withUnsafeBufferPointer() {
            return String(format: "%-10s", $0.baseAddress)
        }

        return "Player: \(playerNum), " +
            "Dpad: \(dpadStr) " +
            "B: \(controllerState.bButtonState), " +
            "A: \(controllerState.aButtonState)"
    }

    private func message(forPlayer playerNum: Int, controllerState: Proto2ControllerState) -> String {
        let x = String(format: "%.2f", controllerState.stickState.xNormalized)
        let y = String(format: "%.2f", controllerState.stickState.yNormalized)
        return "Player: \(playerNum): " +
            "AnalogStick x: \(x) y: \(y) " +
            "A: \(controllerState.aButtonState)"
    }
}

