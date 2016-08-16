import UIKit

import Foundation

class ButtonView : UIView {

    var didPress: ((sender: ButtonView) -> Void)?
    var didRelease: ((sender: ButtonView) -> Void)?
    let label = UILabel.auto()

    var btnState : Bool = false {
        didSet {
            if oldValue != btnState {
                if btnState {
                    didPress?(sender: self)
                    backgroundColor = UIColor.darkGrayColor()
                } else {
                    didRelease?(sender: self)
                    backgroundColor = UIColor.grayColor()
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.grayColor()
        multipleTouchEnabled = false
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.whiteColor().CGColor

        addSubview(label)
        addConstraint(NSLayoutConstraint(item: label, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: label, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0))
        label.text = "Tmp"
    }

    required init?(coder: NSCoder) { super.init(coder: coder); assert(false) }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let hit = hitTest(touches.first!.locationInView(self), withEvent: event) != nil
        btnState = hit
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let hit = hitTest(touches.first!.locationInView(self), withEvent: event) != nil
        btnState = hit
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        btnState = false
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        btnState = false
    }
}
