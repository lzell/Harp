import UIKit
import HarpCommoniOS

class RemoteViewController : UIViewController {

    // This will write out the state of the controller
    let udpWriteSocket : CFSocket = createUDPWriteSocket()
    let clientUDPAddress : sockaddr_in6

    // Designated initializer
    required init(clientUDPAddress: sockaddr_in6) {
        self.clientUDPAddress = clientUDPAddress

        // Super up designated initializer
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        self.init(clientUDPAddress: sockaddr_in6())
    }

    // How do I get rid of this damn thing?
    required init?(coder: NSCoder) {
        assert(false)
        clientUDPAddress = sockaddr_in6()
        super.init(coder:coder)
    }
}