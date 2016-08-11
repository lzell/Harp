import Foundation
import HarpCommoniOS

class Proto2ViewController : RemoteViewController, Proto2WriteContract, StickViewDelegate {

    func aPressed(_ sender: ButtonView) {
        updateBitPatternWithAButtonState(true)
        sendBitPattern()
    }

    func aReleased(_ sender: ButtonView) {
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
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .height, relatedBy: .equal, toItem: v, attribute: .height, multiplier: 1, constant: 0))
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .top, relatedBy: .equal, toItem: v, attribute: .top, multiplier: 1, constant: 0))
        v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[aBtn(200)]|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["aBtn": aBtn]))

        let stick = StickView.auto()
        stick.delegate = self
        v.addSubview(stick)
        v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(30)-[stick(200)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["stick": stick]))

        v.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[stick(200)]-(50)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["stick": stick]))



        view = v
    }

    // MARK: - StickViewDelegate
    func stickStateDidChange(_ stickState: StickState) {
        print(stickState.xDiscrete)
        updateBitPatternWithStickState(stickState)
        sendBitPattern()
    }
    
}
