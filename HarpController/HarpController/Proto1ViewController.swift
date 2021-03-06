import UIKit
import HarpiOS


class Proto1ViewController : RemoteViewController, DpadViewDelegate, Proto1WriteContract {

    func aPressed(sender: ButtonView) {
        updateBitPatternWithAButtonState(true)
        sendBitPattern()
    }

    func aReleased(sender: ButtonView) {
        updateBitPatternWithAButtonState(false)
        sendBitPattern()
    }


    func bPressed(sender: ButtonView) {
        updateBitPatternWithBButtonState(true)
        sendBitPattern()
    }

    func bReleased(sender: ButtonView) {
        updateBitPatternWithBButtonState(false)
        sendBitPattern()
    }

    override func loadView() {
        let v = UIView(frame: CGRect.zero)

        let aBtn = ButtonView.auto()
        aBtn.label.text = "A"
        aBtn.didPress = aPressed
        aBtn.didRelease = aReleased
        v.addSubview(aBtn)
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .Height, relatedBy: .Equal, toItem: v, attribute: .Height, multiplier: 1, constant: 0))
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .Top, relatedBy: .Equal, toItem: v, attribute: .Top, multiplier: 1, constant: 0))
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[aBtn(100)]|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["aBtn": aBtn]))

        let bBtn = ButtonView.auto()
        bBtn.label.text = "B"
        bBtn.didPress = bPressed
        bBtn.didRelease = bReleased
        v.addSubview(bBtn)
        v.addConstraint(NSLayoutConstraint(item: bBtn, attribute: .Height, relatedBy: .Equal, toItem: v, attribute: .Height, multiplier: 1, constant: 0))
        v.addConstraint(NSLayoutConstraint(item: bBtn, attribute: .Top, relatedBy: .Equal, toItem: v, attribute: .Top, multiplier: 1, constant: 0))
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[bBtn(100)]-100-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["bBtn": bBtn]))


        let dpadView = DpadView.auto()
        dpadView.delegate = self
        v.addSubview(dpadView)
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-30-[dpadView(200)]", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["dpadView": dpadView]))
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[dpadView(200)]-70-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["dpadView": dpadView]))

        view = v
    }

    // MARK: DpadViewDelegate
    func dpadStateDidChange(dpadState: DpadState) {
        updateBitPatternWithDpadState(dpadState)
        sendBitPattern()
    }
}
