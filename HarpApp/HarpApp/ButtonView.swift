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
                    backgroundColor = UIColor.darkGray
                } else {
                    didRelease?(sender: self)
                    backgroundColor = UIColor.gray
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.gray
        isMultipleTouchEnabled = false
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.white.cgColor

        addSubview(label)
        addConstraint(NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        label.text = "Tmp"
    }

    required init?(coder: NSCoder) { super.init(coder: coder); assert(false) }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let hit = hitTest(touches.first!.location(in: self), with: event) != nil
        btnState = hit
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let hit = hitTest(touches.first!.location(in: self), with: event) != nil
        btnState = hit
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        btnState = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        btnState = false
    }
}
