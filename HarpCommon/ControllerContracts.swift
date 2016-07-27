import Foundation

// MARK: - Proto1 Controller

// Creating these as UInt64s because << can't apply to a UInt64 if the rhs is Int (Swift 2.2)
private struct Proto1Shift {
    static let aButton : UInt64 = 0
    static let bButton : UInt64 = 1
    static let dpad : UInt64 = 2
}


public protocol Proto1WriteContract : class {
    var bitPattern : UInt64 { get set }
    func updateBitPatternWithDpadState(dpadState: DpadState)
    func updateBitPatternWithAButtonState(buttonState: Bool)
    func updateBitPatternWithBButtonState(buttonState: Bool)
}

extension Proto1WriteContract {
    public func updateBitPatternWithDpadState(dpadState: DpadState) {
        let shift = Proto1Shift.dpad
        var dpadBits : UInt64 = 0xF << shift
        let dpadMask : UInt64 = ~dpadBits
        bitPattern &= dpadMask
        bitPattern |= UInt64(dpadState.rawValue) << shift
    }

    public func updateBitPatternWithAButtonState(buttonState: Bool) {
        let shift = Proto1Shift.aButton
        if buttonState {
            bitPattern |= (1 << shift)
        } else {
            bitPattern &= ~(0x1 << shift)
        }
    }

    public func updateBitPatternWithBButtonState(buttonState: Bool) {
        let shift = Proto1Shift.bButton
        if buttonState {
            bitPattern |= (1 << shift)
        } else {
            bitPattern &= ~(1 << shift)
        }
    }
}

public protocol Proto1ReadContract : class {
    func dpadStateFromBitPattern(bitPattern: UInt64) -> DpadState
    func aButtonStateFromBitPattern(bitPattern: UInt64) -> Bool
    func bButtonStateFromBitPattern(bitPattern: UInt64) -> Bool
}

extension Proto1ReadContract {
    public func dpadStateFromBitPattern(bitPattern: UInt64) -> DpadState {
        let shift = Proto1Shift.dpad
        let dpadBitsUnshifted = (bitPattern & (0xF << shift)) >> shift
        return DpadState(rawValue: Int(dpadBitsUnshifted))!
    }

    public func aButtonStateFromBitPattern(bitPattern: UInt64) -> Bool {
        let shift = Proto1Shift.aButton
        let aButtonUnshifted = (bitPattern & (1 << shift)) >> shift
        return Bool(Int(aButtonUnshifted))
    }
    public func bButtonStateFromBitPattern(bitPattern: UInt64) -> Bool {
        let shift = Proto1Shift.bButton
        let bButtonUnshifted = (bitPattern & (1 << shift)) >> shift
        return Bool(Int(bButtonUnshifted))
    }
}
