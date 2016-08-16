import UIKit
import HarpTvOS

class ViewController: UIViewController, HarpServiceDelegate {

    let service = HarpService(maxConcurrentConnections: 2)
    @IBOutlet weak var textView : UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        service.delegate = self
        service.register()
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
        if let s = state as? Proto1ControllerState {
            log("Player \(playerNum):  Dpad: \(s.dpadState)  B: \(s.bButtonState)  A: \(s.aButtonState)")
        } else if let s = state as? Proto2ControllerState {
            log("Player \(playerNum):  AnalogStick x: \(s.stickState.xNormalized) y: \(s.stickState.yNormalized)  A: \(s.aButtonState)")
        }
    }


    // MARK: -

    private func log(msg: String) {
        print(msg)
        textView.insertText("\(msg)\n")
        textView.scrollRangeToVisible(NSRange(location: textView.text.characters.count - 1, length: 0))
    }
}

