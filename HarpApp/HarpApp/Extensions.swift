// MARK: - Autolayout
import UIKit
extension NSLayoutConstraint {
    public static func superviewFillingConstraintsForView(view: UIView) -> [NSLayoutConstraint] {
        let hor = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": view])
        let ver = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": view])
        return hor + ver
    }

    static func equalSizeConstraintsForViews(src src: UIView, dst: UIView) -> [NSLayoutConstraint] {
        let w = NSLayoutConstraint(item: dst, attribute: .Width, relatedBy: .Equal, toItem: src, attribute: .Width, multiplier: 1, constant: 0)
        let h = NSLayoutConstraint(item: dst, attribute: .Height, relatedBy: .Equal, toItem: src, attribute: .Height, multiplier: 1, constant: 0)
        return [w,h]
    }
}

extension UIView {
    static func auto() -> Self {
        let view = self.init(frame: CGRectZero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}