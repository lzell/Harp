import UIKit

class ViewController: UIViewController, HarpClientDelegate {

    let harpClient = HarpClient()


    override func viewDidLoad() {
        super.viewDidLoad()

        harpClient.autoConnect()
        harpClient.delegate = self
    }

    func hostRequestsController(controllerName: String, receiveAddress: sockaddr_in6) {
        let nextVC = (NSClassFromString("HarpApp." + controllerName) as! RemoteViewController.Type).init(clientUDPAddress:receiveAddress)
        presentViewController(nextVC, animated: true, completion: nil)
    }

    func hostDidDisconnect() {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
