import UIKit
import HarpCommoniOS

class ViewController: UIViewController, HarpClientDelegate {

    let harpClient = HarpClient()

    var receiveAddr: sockaddr_in6?
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: - Init/Deinit

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        postinit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        postinit()
    }

    private func postinit() {
        harpClient.startSearchForHarpHosts()
        harpClient.delegate = self
        nc().addObserver(self, selector: #selector(didEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        nc().addObserver(self, selector: #selector(willEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)

        /* let delay = DispatchTimeInterval.milliseconds(1)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            self.present(Proto2ViewController(clientUDPAddress: sockaddr_in6()), animated: true, completion: nil)
        }
 */
    }

    deinit {
        harpClient.stopSearchingForHarpHosts()
        nc().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        nc().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }


    // MARK: - Incoming

    @objc private func didEnterBackground(note: NSNotification) {
        harpClient.closeAnyConnections()
        harpClient.stopSearchingForHarpHosts()
    }

    @objc private func willEnterForeground(note: NSNotification) {
        harpClient.startSearchForHarpHosts()
    }


    func didFind(host: Host) {
        print("Found hostname:\(host.name) addressCount:\(host.addresses.count)")
        harpClient.stopSearchingForHarpHosts()
        harpClient.connectToHost(host)
    }


    func didFailToConnectTo(host: Host) {
        print("Failed to connect to host")
    }

    func didEstablishConnectionTo(host: Host, withHandshakeInfo handshakeInfo: HandshakeInfo) {
        statusLabel.hidden = true
        print("Connected to hostname: \(host.name)")
        receiveAddr = handshakeInfo.udpReceiveAddress
    }

    func didDisconnectFrom(host: Host) {
        statusLabel.hidden = false
        print("Disconnected from hostname: \(host.name)")
        dismissViewControllerAnimated(true, completion: nil)
        harpClient.startSearchForHarpHosts()
    }


    func didReceiveRequestForController(name: String, from host: Host) {
        print("Received request for controller: \(name)")
        let nextVC = (NSClassFromString("HarpApp." + name) as! RemoteViewController.Type).init(clientUDPAddress: receiveAddr!)
        if presentedViewController != nil {
            dismissViewControllerAnimated(true, completion: {
                self.presentViewController(nextVC, animated: true, completion: nil)
            })
        } else {
            presentViewController(nextVC, animated: true, completion: nil)
        }
    }

    private func nc() -> NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
}
