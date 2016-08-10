import UIKit
import HarpCommoniOS


class Proto1ViewController : RemoteViewController, DpadViewDelegate, Proto1WriteContract {

    func aPressed(_ sender: ButtonView) {
        updateBitPatternWithAButtonState(true)
        sendBitPattern()
    }

    func aReleased(_ sender: ButtonView) {
        updateBitPatternWithAButtonState(false)
        sendBitPattern()
    }


    func bPressed(_ sender: ButtonView) {
        updateBitPatternWithBButtonState(true)
        sendBitPattern()
    }

    func bReleased(_ sender: ButtonView) {
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
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .height, relatedBy: .equal, toItem: v, attribute: .height, multiplier: 1, constant: 0))
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .top, relatedBy: .equal, toItem: v, attribute: .top, multiplier: 1, constant: 0))
        v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[aBtn(100)]|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["aBtn": aBtn]))

        let bBtn = ButtonView.auto()
        bBtn.label.text = "B"
        bBtn.didPress = bPressed
        bBtn.didRelease = bReleased
        v.addSubview(bBtn)
        v.addConstraint(NSLayoutConstraint(item: bBtn, attribute: .height, relatedBy: .equal, toItem: v, attribute: .height, multiplier: 1, constant: 0))
        v.addConstraint(NSLayoutConstraint(item: bBtn, attribute: .top, relatedBy: .equal, toItem: v, attribute: .top, multiplier: 1, constant: 0))
        v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[bBtn(100)]-100-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["bBtn": bBtn]))


        let dpadView = DpadView.auto()
        dpadView.delegate = self
        v.addSubview(dpadView)
        v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-30-[dpadView(200)]", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["dpadView": dpadView]))
        v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[dpadView(200)]-70-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["dpadView": dpadView]))

        view = v
    }

    // MARK: DpadViewDelegate
    func dpadStateDidChange(_ dpadState: DpadState) {
        updateBitPatternWithDpadState(dpadState)
        sendBitPattern()
    }
}
