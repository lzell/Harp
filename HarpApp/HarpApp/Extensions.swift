// MARK: - Autolayout
import UIKit
extension NSLayoutConstraint {
    public static func superviewFillingConstraintsForView(_ view: UIView) -> [NSLayoutConstraint] {
        let hor = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": view])
        let ver = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view": view])
        return hor + ver
    }

    static func equalSizeConstraintsForViews(_ src: UIView, dst: UIView) -> [NSLayoutConstraint] {
        let w = NSLayoutConstraint(item: dst, attribute: .width, relatedBy: .equal, toItem: src, attribute: .width, multiplier: 1, constant: 0)
        let h = NSLayoutConstraint(item: dst, attribute: .height, relatedBy: .equal, toItem: src, attribute: .height, multiplier: 1, constant: 0)
        return [w,h]
    }
}

extension UIView {
    static func auto() -> Self {
        let view = self.init(frame: CGRect.zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
}
