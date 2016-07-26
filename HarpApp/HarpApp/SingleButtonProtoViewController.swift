import UIKit
import HarpCommoniOS


// How do I expose the byte pattern as something the client can adopt?
//protocol ProtoReadContract {
//    var bitpattern: UInt64 { get set }
//    func dpadState() -> UInt8
//    func bButtonState() -> UInt8
//    func setDpadState(
//}

protocol ProtoWriteContract : class {
    var bitPattern : UInt64 { get set }
    func updateBitPatternWithDpadState(dpadState: DpadState)
    func updateBitPatternWithAButtonState(buttonState: Bool)
    func updateBitPatternWithBButtonState(buttonState: Bool)
}

extension ProtoWriteContract {
    func updateBitPatternWithDpadState(dpadState: DpadState) {
        let dpadBits : UInt64 = 0xF << 2
        let dpadMask : UInt64 = ~dpadBits
        bitPattern &= dpadMask
        bitPattern |= (UInt64(dpadState.rawValue << 2))
    }

    func updateBitPatternWithAButtonState(buttonState: Bool) {
        if buttonState {
            bitPattern |= 1
        } else {
            bitPattern &= ~(0x1)
        }
    }

    func updateBitPatternWithBButtonState(buttonState: Bool) {
        if buttonState {
            bitPattern |= 1 << 1
        } else {
            bitPattern &= ~(1 << 1)
        }
    }
}



class SingleButtonProtoViewController : PadViewController, DpadViewDelegate, ProtoWriteContract {

    var bitPattern : UInt64 = 0

    func aPressed(sender: ButtonView) {
        updateBitPatternWithAButtonState(true)
        sendBitPattern()
    }

    func aReleased(sender: ButtonView) {
        updateBitPatternWithAButtonState(false)
        sendBitPattern()
    }


    func bPressed(sender: ButtonView) {
        updateBitPatternWithBButtonState(true)
        sendBitPattern()
    }

    func bReleased(sender: ButtonView) {
        updateBitPatternWithBButtonState(false)
        sendBitPattern()
    }

    private func sendBitPattern() {
        // Copy state
        var x = bitPattern
        var byteArray = [UInt8]()
        for _ in 0..<sizeof(UInt64) {
            byteArray.append(UInt8(x))
            x >>= 8
        }
        byteArray = byteArray.reverse()

        var sock6Addr = clientUDPAddress
        let addressData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, valuePtrCast(&sock6Addr), sizeofValue(sock6Addr), kCFAllocatorNull)
        let sendData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, &byteArray, sizeofValue(sock6Addr), kCFAllocatorNull)
        if CFSocketSendData(udpWriteSocket, addressData, sendData, -1) != .Success {
            assert(false, "UDP socket failed to send")
        }
    }

    override func loadView() {
        let v = UIView(frame: CGRectZero)
        v.backgroundColor = UIColor.whiteColor()

        let aBtn = ButtonView()
        aBtn.translatesAutoresizingMaskIntoConstraints = false
        aBtn.didPress = aPressed
        aBtn.didRelease = aReleased
        v.addSubview(aBtn)
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .Height, relatedBy: .Equal, toItem: v, attribute: .Height, multiplier: 1, constant: 0))
        v.addConstraint(NSLayoutConstraint(item: aBtn, attribute: .Top, relatedBy: .Equal, toItem: v, attribute: .Top, multiplier: 1, constant: 0))
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[aBtn(100)]|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["aBtn": aBtn]))

        let bBtn = ButtonView()
        bBtn.translatesAutoresizingMaskIntoConstraints = false
        bBtn.didPress = bPressed
        bBtn.didRelease = bReleased
        v.addSubview(bBtn)
        v.addConstraint(NSLayoutConstraint(item: bBtn, attribute: .Height, relatedBy: .Equal, toItem: v, attribute: .Height, multiplier: 1, constant: 0))
        v.addConstraint(NSLayoutConstraint(item: bBtn, attribute: .Top, relatedBy: .Equal, toItem: v, attribute: .Top, multiplier: 1, constant: 0))
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[bBtn(100)]-100-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["bBtn": bBtn]))


        let dpadView = DpadView()
        dpadView.delegate = self
        dpadView.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(dpadView)
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[dpadView(200)]", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["dpadView": dpadView]))
        v.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[dpadView(200)]-20-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["dpadView": dpadView]))

        view = v
    }

    // MARK: DpadViewDelegate
    func dpadStateDidChange(dpadState: DpadState) {
        updateBitPatternWithDpadState(dpadState)
        sendBitPattern()
    }
}
