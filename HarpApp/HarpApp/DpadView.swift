import UIKit
import HarpCommoniOS



protocol DpadViewDelegate : class {
    func dpadStateDidChange(_ dpadState: DpadState)
}


class DpadView : UIView {

    weak var delegate : DpadViewDelegate?

    var state : DpadState = .default {
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

        func forState(_ state: DpadState) -> UIImage {
            switch state {
            case .default:   return inactive
            case .right:     return right
            case .downRight: return downRight
            case .down:      return down
            case .downLeft:  return downLeft
            case .left:      return left
            case .upLeft:    return upLeft
            case .up:        return up
            case .upRight:   return upRight
            }
        }
    }


    let images = Images()
    var imgView : UIImageView!

    override init(frame: CGRect) {
        // First Phase
        super.init(frame: frame)

        // Second phase
        isMultipleTouchEnabled = false
        imgView = UIImageView.auto()
        addSubview(imgView)
        addConstraints(NSLayoutConstraint.superviewFillingConstraintsForView(imgView))
        imgView.image = images.inactive
    }

    required init?(coder: NSCoder) { super.init(coder: coder); assert(false) }


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
        updateState(nil)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
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


    private func stateForAngle(_ angle: Double, _ squaredDistanceRatio: Double) -> DpadState {

        if squaredDistanceRatio < 0.009 {   // Experiment with this value
            return .default
        }

        switch angle {
        case _ where angle > arcs[0][0] && angle <= arcs[0][1]: return .right
        case _ where angle > arcs[1][0] && angle <= arcs[1][1]: return .downRight
        case _ where angle > arcs[2][0] && angle <= arcs[2][1]: return .down
        case _ where angle > arcs[3][0] && angle <= arcs[3][1]: return .downLeft
        case _ where angle > arcs[4][0] || angle <= arcs[4][1]: return .left
        case _ where angle > arcs[5][0] && angle <= arcs[5][1]: return .upLeft
        case _ where angle > arcs[6][0] && angle <= arcs[6][1]: return .up
        case _ where angle > arcs[7][0] && angle <= arcs[7][1]: return .upRight
        default:
            assert(false)
            return .default
        }
    }

    private func updateState(_ touch: UITouch?) {
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
    }
}
