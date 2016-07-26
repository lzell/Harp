import UIKit
import HarpCommoniOS


class SingleButtonProtoViewController : PadViewController, DpadViewDelegate {

    var bitState : UInt64 = 0

//    func pressed(sender: UIButton) {
//        bitState |= 1
//        sendBitState()
//    }
//
//    func released(sender: UIButton) {
//        bitState &= ~(0x1)
//        sendBitState()
//    }

    private func sendBitState() {
        // Copy state
        var x = bitState
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
//        let btn = UIButton(type: UIButtonType.System)
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        btn.setTitle("Push Me", forState: UIControlState.Normal)
//        btn.addTarget(self, action: #selector(pressed(_:)), forControlEvents: UIControlEvents.TouchDown)
//        btn.addTarget(self, action: #selector(released(_:)), forControlEvents: [.TouchDragExit, .TouchCancel, .TouchUpInside, .TouchUpOutside, .TouchDragOutside])
//        v.addSubview(btn)
//        v.addConstraints(NSLayoutConstraint.superviewFillingConstraintsForView(btn))

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
        let dpadBits : UInt64 = 0xF
        let dpadMask : UInt64 = ~dpadBits
        bitState &= dpadMask
        bitState |= UInt64(dpadState.rawValue)
        sendBitState()
    }
}
