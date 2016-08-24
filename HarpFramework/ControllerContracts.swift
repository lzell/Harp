import Foundation

// MARK: - Generic
public protocol ControllerState {}
public protocol InputTranslator {
    func translate(bitPattern: UInt64) -> ControllerState
}


// MARK: - Proto1 Specific

/* Proto 1 Template Setup */

public struct Proto1ControllerState : ControllerState {
    public let dpadState : DpadState
    public let bButtonState : Bool
    public let aButtonState : Bool
}

private struct Proto1Shift {
    static let dpad : UInt64 = 2     // Declaring as UInt64s because << can't apply to a UInt64 if the rhs is Int (Swift 2.2)
    static let bButton : UInt64 = 1
    static let aButton : UInt64 = 0
}


/* Proto 1 Read Side */

public struct Proto1InputTranslator : Proto1ReadContract, InputTranslator {

    public init() {}

    public func translate(bitPattern: UInt64) -> ControllerState {
        let ret = Proto1ControllerState(
            dpadState: dpadStateFromBitPattern(bitPattern),
            bButtonState : bButtonStateFromBitPattern(bitPattern),
            aButtonState: aButtonStateFromBitPattern(bitPattern)
        )
        return ret
    }
}

public protocol Proto1ReadContract {
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


/* Proto 1 Write Side */

public protocol Proto1WriteContract : class {
    var bitPattern : UInt64 { get set }
    func updateBitPatternWithDpadState(dpadState: DpadState)
    func updateBitPatternWithAButtonState(buttonState: Bool)
    func updateBitPatternWithBButtonState(buttonState: Bool)
}

extension Proto1WriteContract {
    public func updateBitPatternWithDpadState(dpadState: DpadState) {
        let shift = Proto1Shift.dpad
        let dpadBits : UInt64 = 0xF << shift
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


// MARK: - Proto2 Specific

/* Proto 2 Template Setup */

public struct Proto2ControllerState : ControllerState {
    public let stickState : StickState
    public let aButtonState : Bool
}

private struct Proto2Shift {
    static let stick : UInt64 = 1
    static let aButton : UInt64 = 0
}


/* Proto 2 Read Side */

public struct Proto2InputTranslator : Proto2ReadContract, InputTranslator {

    public init() {}

    public func translate(bitPattern: UInt64) -> ControllerState {
        let ret = Proto2ControllerState(
            stickState: stickStateFromBitPattern(bitPattern),
            aButtonState: aButtonStateFromBitPattern(bitPattern)
        )
        return ret
    }
}

public protocol Proto2ReadContract {
    func stickStateFromBitPattern(bitPattern: UInt64) -> StickState
    func aButtonStateFromBitPattern(bitPattern: UInt64) -> Bool
}

extension Proto2ReadContract {
    public func stickStateFromBitPattern(bitPattern: UInt64) -> StickState {
        // Let's use 8 signed bits for normalized x and y ranges, that gives us 256 discrete distances [-128, 127]
        let shift = Proto2Shift.stick
        let reg = (bitPattern & (0xFFFF << shift)) >> shift
        let yBits = Int8(bitPattern: UInt8(reg & 0xFF))
        let xBits = Int8(bitPattern: UInt8((reg >> 8) & 0xFF))
        return StickState(fromDiscrete: xBits, yBits)
    }

    public func aButtonStateFromBitPattern(bitPattern: UInt64) -> Bool {
        let shift = Proto2Shift.aButton
        let aButtonUnshifted = (bitPattern & (1 << shift)) >> shift
        return Bool(Int(aButtonUnshifted))
    }
}


/* Proto 2 Write Side */

public protocol Proto2WriteContract : class {
    var bitPattern : UInt64 { get set }
    func updateBitPatternWithStickState(stickState: StickState)
    func updateBitPatternWithAButtonState(buttonState: Bool)
}

extension Proto2WriteContract {
    public func updateBitPatternWithStickState(stickState: StickState) {

        // Bit offsets of the x representation and y representation:
        let xShift = Proto2Shift.stick + 8
        let yShift = Proto2Shift.stick

        // Create a mask for the stick representation only:
        let xBits : UInt64 = 0xFF << xShift
        let yBits : UInt64 = 0xFF << yShift
        let stickBits : UInt64 = xBits | yBits
        let stickMask : UInt64 = ~stickBits

        // Zero the stick bits
        bitPattern &= stickMask

        // Set them to the new state.  Remember we're using signed ints to represent stick state:
        let xBitPattern = UInt64(UInt8(bitPattern: stickState.xDiscrete)) << xShift
        let yBitPattern = UInt64(UInt8(bitPattern: stickState.yDiscrete)) << yShift

        bitPattern |= xBitPattern
        bitPattern |= yBitPattern
    }

    public func updateBitPatternWithAButtonState(buttonState: Bool) {
        let shift = Proto2Shift.aButton
        if buttonState {
            bitPattern |= (1 << shift)
        } else {
            bitPattern &= ~(0x1 << shift)
        }
    }
}

