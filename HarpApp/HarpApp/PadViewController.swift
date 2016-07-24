//
//  PadViewController.swift
//  HarpApp
//
//  Created by Lou Zell on 7/24/16.
//  Copyright © 2016 Lou Zell. All rights reserved.
//

import UIKit
import HarpCommoniOS

class PadViewController : UIViewController {

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
}
