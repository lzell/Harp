import Foundation

public enum DpadState : Int {
    case Default = 0
    case Right
    case DownRight
    case Down
    case DownLeft
    case Left
    case UpLeft
    case Up
    case UpRight
}


public struct StickState {
    public let xDiscrete : Int8
    public let yDiscrete : Int8
    public let xNormalized : CGFloat
    public let yNormalized : CGFloat

    public init(fromDiscrete x: Int8, _ y: Int8) {
        self.xDiscrete = x
        self.yDiscrete = y
        xNormalized = StickState.mapDiscreteToNormal(x)
        yNormalized = StickState.mapDiscreteToNormal(y)
    }

    public init(fromNormalized x: CGFloat, _ y: CGFloat) {
        self.xNormalized = x
        self.yNormalized = y
        xDiscrete = StickState.mapNormalToDiscrete(x)
        yDiscrete = StickState.mapNormalToDiscrete(y)
    }

    static func mapNormalToDiscrete(norm: CGFloat) -> Int8 {
        if norm > 0 {
            return Int8(round(CGFloat(Int8.max) * norm))
        } else if norm < 0 {
            return Int8(round(CGFloat(Int8.min) * abs(norm)))
        } else {
            return 0
        }
    }

    static func mapDiscreteToNormal(discrete: Int8) -> CGFloat {
        if discrete > 0 {
            return CGFloat(discrete) / CGFloat(Int8.max)
        } else if discrete < 0 {
            return -1 * CGFloat(discrete) / CGFloat(Int8.min)
        } else {
            return 0
        }
    }
}
