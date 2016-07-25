import UIKit
import HarpCommoniOS


class SingleButtonProtoViewController : PadViewController {

    var state : UInt64 = 0

    func pressed(sender: UIButton) {
        state |= 1
        sendState()
    }

    func released(sender: UIButton) {
        state &= ~(0x1)
        sendState()
    }

    private func sendState() {
        // Copy state
        var x = state
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
        let btn = UIButton(type: UIButtonType.System)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Push Me", forState: UIControlState.Normal)
        btn.addTarget(self, action: #selector(pressed(_:)), forControlEvents: UIControlEvents.TouchDown)
        btn.addTarget(self, action: #selector(released(_:)), forControlEvents: [.TouchDragExit, .TouchCancel, .TouchUpInside, .TouchUpOutside, .TouchDragOutside])
        v.addSubview(btn)
        v.addConstraints(NSLayoutConstraint.superviewFillingConstraintsForView(btn))
        view = v
    }
}
