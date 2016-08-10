import UIKit
import HarpCommoniOS

class StickView : UIView {

    let boundary : UIView
    let stick : UIView
    let verticalBar : UIView
    let horizontalBar : UIView
    var stickRadius : CGFloat?

    /*
    var state : StickState {
        didSet {
            print("Set it")
        }
    }
 */

    override init(frame: CGRect) {
        boundary = UIView(frame: CGRect.zero)
        stick = UIView(frame: CGRect.zero)
        verticalBar = UIView(frame: CGRect.zero)
        horizontalBar = UIView(frame: CGRect.zero)

        super.init(frame: frame)

        isMultipleTouchEnabled = false
        backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        layer.cornerRadius = 5
        addSubview(boundary)
        addSubview(stick)
        addSubview(verticalBar)
        addSubview(horizontalBar)

        boundary.backgroundColor = UIColor.lightGray
        stick.backgroundColor = UIColor.darkGray
        verticalBar.backgroundColor = UIColor.darkGray
        horizontalBar.backgroundColor = UIColor.darkGray
    }

    required init?(coder: NSCoder) { boundary = UIView(); stick = UIView(); horizontalBar = UIView(); verticalBar = UIView(); super.init(coder: coder); assert(false) }

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
        stick.layer.shadowPath = UIBezierPath(roundedRect: stick.bounds, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: r, height: r)).cgPath
        stick.layer.shadowRadius = 4
        stick.layer.shadowOffset = CGSize(width: 0, height: 3)
        stick.layer.shadowOpacity = 1
        stick.layer.shadowColor = UIColor.black.cgColor
        stick.layer.masksToBounds = false
        stick.layer.shouldRasterize = true
        stick.layer.rasterizationScale = UIScreen.main.scale
        stickRadius = r
    }

    // MARK: - Tracking
    var trackingTouch : UITouch?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        trackingTouch = touches.first
        updateState(trackingTouch!)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        assert(trackingTouch == touches.first)
        updateState(trackingTouch!)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        assert(trackingTouch == touches.first)
        stick.center = self.center
        updateState(nil)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateState(nil)
    }

    private func updateState(_ touch: UITouch?) {
        let pt = trackingTouch!.location(in: self)
        stick.center = pt

        let dx = pt.x - bounds.midX
        let dy = pt.y - bounds.midY
        let r = bounds.midX

        let l = sqrt(dx * dx + dy * dy) // Distance from origin to touch
        let c = l - sqrt(r * r)         // Distance from edge of circle to touch

        if c > 0 {
            let yprime = c * dy / l     // Ratio of y component to touch hypotenuse, times c
            let xprime = c * dx / l
            stick.center = CGPoint(x: pt.x - xprime, y: pt.y - yprime)
        }
/*
        if dx * dx + dy * dy > r * r {
            // Use similar triangle:
            let distance = sqrt(dx * dx + dy * dy)
            let x = (stickRadius! * dx) / distance
            print("x is \(x)")

            let y = (stickRadius! * dy) / distance
            stick.center = CGPoint(x: x, y: y)
        }
 */



        /*
        if let t = touch {
            let loc = t.location(in: self)
            let origin = CGPoint(x: bounds.midX, y: bounds.midY)
            let dy = loc.y - origin.y
            let dx = loc.x - origin.x
            let theta = atan2(dy, dx)
            let width = bounds.width
            let squaredDistanceRatio = (dy * dy + dx * dx) / (width * width)
            state = stateForAngle(Double(theta), Double(squaredDistanceRatio))
        } else {
            trackingTouch = nil
            state = .default
        }
         */
    }
}
