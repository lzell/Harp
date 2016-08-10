import Foundation

public enum DpadState : Int {
    case `default` = 0
    case right
    case downRight
    case down
    case downLeft
    case left
    case upLeft
    case up
    case upRight
}

public struct StickState {
    var x : Int8
    var y : Int8

    func mapNormalToDiscrete(norm: Double) -> Int8 {
        if norm > 0 {
            return Int8(round(Double(Int8.max) * norm))
        } else if norm < 0 {
            return Int8(round(Double(Int8.min) * norm))
        } else {
            return 0
        }
    }

    mutating func adjustTo(xNormal: Double, yNormal: Double){
        x = mapNormalToDiscrete(norm: xNormal)
        y = mapNormalToDiscrete(norm: yNormal)
    }
}
