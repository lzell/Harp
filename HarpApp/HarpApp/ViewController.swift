import UIKit

class ViewController: UIViewController, ConnectionManagerDelegate {

    let cxnManager = ConnectionManager(numConnections: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        cxnManager.delegate = self
//        let delay = 0.1
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
//            self.presentViewController(SingleButtonProtoViewController(), animated: true, completion: nil)
//            
//        }

        cxnManager.registerService()
    }

    // MARK: - ConnectionManagerDelegate
    func clientRequestsController(controllerName: String, receiveAddress: sockaddr_in6) {
        let nextVC = (NSClassFromString("HarpApp." + controllerName) as! PadViewController.Type).init(clientUDPAddress:receiveAddress)
        presentViewController(nextVC, animated: true, completion: nil)
    }

    func clientDidDisconnect() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
