import UIKit
import HarpCommoniOS

class ViewController: UIViewController, HarpClientDelegate {

    let harpClient = HarpClient()


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
    }

    deinit {
        harpClient.stopSearchingForHarpHosts()
        nc().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }


    // MARK: - Incoming

    @objc private func didEnterBackground(note: NSNotification) {
        harpClient.closeAnyConnections()
        harpClient.stopSearchingForHarpHosts()
    }

    @objc private func willEnterForeground(note: NSNotification) {
        harpClient.startSearchForHarpHosts()
    }


    func didFindHost(host: Host) {
        print("Found hostname:\(host.name) addressCount:\(host.addresses.count)")
        harpClient.stopSearchingForHarpHosts()
        harpClient.connectToHost(host)
    }

    func didFailToConnectToHost(host: Host) {
        print("Failed to connect to host")
    }

    func didEstablishConnectionToHost(host: Host, withHandshakeInfo handshakeInfo: HandshakeInfo) {
        print("Connected to hostname: \(host.name)")
        let nextVC = (NSClassFromString("HarpApp." + handshakeInfo.controllerName) as! RemoteViewController.Type).init(clientUDPAddress: handshakeInfo.udpReceiveAddress)
        presentViewController(nextVC, animated: true, completion: nil)
    }

    func didDisconnectFromHost(host: Host) {
        print("Disconnected from hostname: \(host.name)")
        dismissViewControllerAnimated(true, completion: nil)
        harpClient.startSearchForHarpHosts()
    }


    private func nc() -> NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }
}