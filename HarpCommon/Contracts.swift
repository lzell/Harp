import Foundation

public protocol Proto1WriteContract : class {
    var bitPattern : UInt64 { get set }
    func updateBitPatternWithDpadState(dpadState: DpadState)
    func updateBitPatternWithAButtonState(buttonState: Bool)
    func updateBitPatternWithBButtonState(buttonState: Bool)
}

extension Proto1WriteContract {
    public func updateBitPatternWithDpadState(dpadState: DpadState) {
        let dpadBits : UInt64 = 0xF << 2
        let dpadMask : UInt64 = ~dpadBits
        bitPattern &= dpadMask
        bitPattern |= (UInt64(dpadState.rawValue << 2))
    }

    public func updateBitPatternWithAButtonState(buttonState: Bool) {
        if buttonState {
            bitPattern |= 1
        } else {
            bitPattern &= ~(0x1)
        }
    }

    public func updateBitPatternWithBButtonState(buttonState: Bool) {
        if buttonState {
            bitPattern |= 1 << 1
        } else {
            bitPattern &= ~(1 << 1)
        }
    }
}
