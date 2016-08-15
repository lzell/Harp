import Foundation
import HarpCommoniOS

class Proto2ViewController : RemoteViewController, Proto2WriteContract, StickViewDelegate {

    func aPressed(sender: ButtonView) {
        updateBitPatternWithAButtonState(true)
        sendBitPattern()
    }

    func aReleased(sender: ButtonView) {
        updateBitPatternWithAButtonState(false)
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
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[aBtn(200)]|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["aBtn": aBtn]))

        let stick = StickView.auto()
        stick.delegate = self
        v.addSubview(stick)
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(30)-[stick(200)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["stick": stick]))

        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[stick(200)]-(50)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["stick": stick]))



        view = v
    }

    // MARK: - StickViewDelegate
    func stickStateDidChange(stickState: StickState) {
        updateBitPatternWithStickState(stickState)
        sendBitPattern()
    }
    
}
