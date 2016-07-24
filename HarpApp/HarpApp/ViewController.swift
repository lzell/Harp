import UIKit

class ViewController: UIViewController, ConnectionManagerDelegate {

    let cxnManager = ConnectionManager(numConnections: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        cxnManager.delegate = self
        cxnManager.registerService()
    }

    // MARK: - ConnectionManagerDelegate
    func clientRequestsController(controllerName: String, receiveAddress: sockaddr_in6) {
        let nextVC = (NSClassFromString("HarpApp." + controllerName) as! PadViewController.Type).init(clientUDPAddress:receiveAddress)
        presentViewController(nextVC, animated: true, completion: nil)
    }
}
