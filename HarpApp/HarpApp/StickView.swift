import UIKit
import HarpCommoniOS


protocol StickViewDelegate : class {
    func stickStateDidChange(stickState: StickState)
}


class StickView : UIView {

    weak var delegate : StickViewDelegate?

    let boundary : UIView
    let stick : UIView
    let verticalBar : UIView
    let horizontalBar : UIView
    var stickRadius : CGFloat?


    override init(frame: CGRect) {
        // First phase
        boundary = UIView(frame: CGRect.zero)
        boundary.backgroundColor = UIColor.lightGrayColor()

        stick = UIView(frame: CGRect.zero)
        stick.backgroundColor = UIColor.darkGrayColor()

        verticalBar = UIView(frame: CGRect.zero)
        verticalBar.backgroundColor = UIColor.darkGrayColor()

        horizontalBar = UIView(frame: CGRect.zero)
        horizontalBar.backgroundColor = UIColor.darkGrayColor()

        super.init(frame: frame)

        // Second phase
        multipleTouchEnabled = false
        backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        layer.cornerRadius = 5

        addSubview(boundary)
        addSubview(stick)
        addSubview(verticalBar)
        addSubview(horizontalBar)
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        boundary.frame = bounds
        boundary.layer.cornerRadius = bounds.midX

        let x = bounds.width / 100.0
        verticalBar.frame = CGRect(x: bounds.midX - x, y: bounds.midY - 2 * x, width: 2 * x, height: 4 * x)
        horizontalBar.frame = CGRect(x: bounds.midX - 2 * x, y: bounds.midY - x, width: 4 * x, height: 2 * x)

        let r = bounds.width / 10.0
        stick.frame = CGRect(x: bounds.midX - r, y: bounds.midY - r, width: 2 * r, height: 2 * r)
        stick.layer.cornerRadius = r
        stick.layer.shadowPath = UIBezierPath(roundedRect: stick.bounds,
                                              byRoundingCorners: UIRectCorner.AllCorners,
                                              cornerRadii: CGSize(width: r, height: r)).CGPath
        stick.layer.shadowRadius = 4
        stick.layer.shadowOffset = CGSize(width: 0, height: 3)
        stick.layer.shadowOpacity = 1
        stick.layer.shadowColor = UIColor.blackColor().CGColor
        stick.layer.masksToBounds = false
        stick.layer.shouldRasterize = true
        stick.layer.rasterizationScale = UIScreen.mainScreen().scale
        stickRadius = r
    }


    // MARK: - Tracking

    var trackingTouch : UITouch?
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        trackingTouch = touches.first
        updateState(trackingTouch!)
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        assert(trackingTouch == touches.first)
        updateState(trackingTouch!)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        assert(trackingTouch == touches.first)
        updateState(nil)
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        updateState(nil)
    }


    private func updateState(touch: UITouch?) {
        let p = touch?.locationInView(self) ?? CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = p.x - bounds.midX
        let dy = p.y - bounds.midY
        let r = bounds.midX

        let d = sqrt(dx * dx + dy * dy) // Distance from origin to touch
        let c = d - sqrt(r * r)         // Distance from edge of circle to touch

        let x : CGFloat
        let y : CGFloat
        if c > 0 {
            let yprime = c * dy / d     // Ratio of y component to touch hypotenuse, times c
            let xprime = c * dx / d
            x = p.x - xprime
            y = p.y - yprime
        } else {
            x = p.x
            y = p.y
        }
        stick.center = CGPoint(x: x, y: y)

        // Now get the ratio of the touch points to the total height and width:
        let xNormalized = (x - bounds.midX) / r
        let yNormalized = -(y - bounds.midY) / r    // Multiplying by -1 here to invert UIKit coordinate system

        let state = StickState(fromNormalized: xNormalized, yNormalized)
        notifyStickStateDidChange(state)
    }


    // MARK: - Outgoing

    func notifyStickStateDidChange(state: StickState) {
        delegate?.stickStateDidChange(state)
    }


    // MARK: - Junk

    required init?(coder: NSCoder) { boundary = UIView(); stick = UIView(); horizontalBar = UIView(); verticalBar = UIView(); super.init(coder: coder); assert(false) }

}
