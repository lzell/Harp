import UIKit

import Foundation

class ButtonView : UIView {

    var didPress: ((sender: ButtonView) -> Void)?
    var didRelease: ((sender: ButtonView) -> Void)?

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

    init() {
        super.init(frame: CGRectZero)
        backgroundColor = UIColor.grayColor()
        multipleTouchEnabled = false
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.whiteColor().CGColor
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