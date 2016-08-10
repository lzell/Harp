import UIKit
import HarpCommoniOS

class RemoteViewController : UIViewController {

    var bitPattern : UInt64 = 0

    // This will write out the state of the controller
    let udpWriteSocket : CFSocket = createUDPWriteSocket()
    let clientUDPAddress : sockaddr_in6

    // Designated initializer
    required init(clientUDPAddress: sockaddr_in6) {
        self.clientUDPAddress = clientUDPAddress

        // Super up designated initializer
        super.init(nibName: nil, bundle: nil)
    }

    // How do I get rid of this damn thing?
    required init?(coder: NSCoder) {
        assert(false)
        clientUDPAddress = sockaddr_in6()
        super.init(coder:coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }

    func sendBitPattern() {
        if clientUDPAddress.sin6_len != 0 {
            var x = bitPattern
            var byteArray = [UInt8]()
            for _ in 0..<sizeof(UInt64.self) {
                byteArray.append(UInt8(x))
                x >>= 8
            }
            byteArray = byteArray.reversed()

            var sock6Addr = clientUDPAddress
            let addressData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, valuePtrCast(&sock6Addr), sizeofValue(sock6Addr), kCFAllocatorNull)
            let sendData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, &byteArray, sizeofValue(sock6Addr), kCFAllocatorNull)
            if CFSocketSendData(udpWriteSocket, addressData, sendData, -1) != .success {
                assert(false, "UDP socket failed to send")
            }
        }
    }
}
