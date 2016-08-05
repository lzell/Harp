import UIKit
import HarpCommoniOS



protocol DpadViewDelegate : class {
    func dpadStateDidChange(dpadState: DpadState)
}


class DpadView : UIView {

    weak var delegate : DpadViewDelegate?

    var state : DpadState = .Default {
        didSet {
            if oldValue != state {
                delegate?.dpadStateDidChange(state)
                imgView.image = images.forState(state)
            }
        }
    }

    class Images {
        lazy var inactive   = UIImage(named: "Dpad")!
        lazy var right      = UIImage(named: "DpadRight")!
        lazy var downRight  = UIImage(named: "DpadDownRight")!
        lazy var down       = UIImage(named: "DpadDown")!
        lazy var downLeft   = UIImage(named: "DpadDownLeft")!
        lazy var left       = UIImage(named: "DpadLeft")!
        lazy var upLeft     = UIImage(named: "DpadUpLeft")!
        lazy var up         = UIImage(named: "DpadUp")!
        lazy var upRight    = UIImage(named: "DpadUpRight")!

        func forState(state: DpadState) -> UIImage {
            switch state {
            case .Default:   return inactive
            case .Right:     return right
            case .DownRight: return downRight
            case .Down:      return down
            case .DownLeft:  return downLeft
            case .Left:      return left
            case .UpLeft:    return upLeft
            case .Up:        return up
            case .UpRight:   return upRight
            }
        }
    }


    let images = Images()
    var imgView : UIImageView!

    override init(frame: CGRect) {
        // First Phase
        super.init(frame: frame)

        // Second phase
        multipleTouchEnabled = false
        imgView = UIImageView.auto()
        addSubview(imgView)
        addConstraints(NSLayoutConstraint.superviewFillingConstraintsForView(imgView))
        imgView.image = images.inactive
    }

    required init?(coder: NSCoder) { super.init(coder: coder); assert(false) }


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

    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateState(nil)
    }

    // MARK: - State Management
    private static let a = M_PI_4
    private static let b = a / 2.0

    private let arcs = [
        [-b          , b],
        [b           , b + a],
        [b + a       , b + 2 * a],
        [b + 2 * a   , b + 3 * a],
        [b + 3 * a   , -b - 3 * a],
        [-b - 3 * a  , -b - 2 * a],
        [-b - 2 * a  , -b - a],
        [-b - a      , -b],
        ]


    private func stateForAngle(angle: Double, _ squaredDistanceRatio: Double) -> DpadState {

        if squaredDistanceRatio < 0.009 {   // Experiment with this value
            return .Default
        }

        switch angle {
        case _ where angle > arcs[0][0] && angle <= arcs[0][1]: return .Right
        case _ where angle > arcs[1][0] && angle <= arcs[1][1]: return .DownRight
        case _ where angle > arcs[2][0] && angle <= arcs[2][1]: return .Down
        case _ where angle > arcs[3][0] && angle <= arcs[3][1]: return .DownLeft
        case _ where angle > arcs[4][0] || angle <= arcs[4][1]: return .Left
        case _ where angle > arcs[5][0] && angle <= arcs[5][1]: return .UpLeft
        case _ where angle > arcs[6][0] && angle <= arcs[6][1]: return .Up
        case _ where angle > arcs[7][0] && angle <= arcs[7][1]: return .UpRight
        default:
            assert(false)
            return .Default
        }
    }

    private func updateState(touch: UITouch?) {
        if let t = touch {
            let loc = t.locationInView(self)
            let origin = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
            let dy = loc.y - origin.y
            let dx = loc.x - origin.x
            let theta = atan2(dy, dx)
            let width = CGRectGetWidth(bounds)
            let squaredDistanceRatio = (dy * dy + dx * dx) / (width * width)
            state = stateForAngle(Double(theta), Double(squaredDistanceRatio))
        } else {
            trackingTouch = nil
            state = .Default
        }
    }
}
