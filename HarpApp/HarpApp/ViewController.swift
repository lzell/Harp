import UIKit
import HarpCommoniOS

class ViewController: UIViewController, HarpClientDelegate {

    let harpClient = HarpClient()

    var receiveAddr : sockaddr_in6?


    // MARK: - Init/Deinit

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        postinit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        postinit()
    }

    private func postinit() {
        harpClient.startSearchForHarpHosts()
        harpClient.delegate = self
        nc().addObserver(self, selector: #selector(didEnterBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        nc().addObserver(self, selector: #selector(willEnterForeground(_:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    }

    deinit {
        harpClient.stopSearchingForHarpHosts()
        nc().removeObserver(self, name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }


    // MARK: - Incoming

    @objc private func didEnterBackground(_ note: Notification) {
        harpClient.closeAnyConnections()
        harpClient.stopSearchingForHarpHosts()
    }

    @objc private func willEnterForeground(_ note: Notification) {
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
        print("Connected to hostname: \(host.name)")
        receiveAddr = handshakeInfo.udpReceiveAddress
    }

    func didDisconnectFrom(host: Host) {
        print("Disconnected from hostname: \(host.name)")
        dismiss(animated: true, completion: nil)
        harpClient.startSearchForHarpHosts()
    }


    func didReceiveRequestForController(name: String, from host: Host) {
        print("Received request for controller: \(name)")
        let nextVC = (NSClassFromString("HarpApp." + name) as! RemoteViewController.Type).init(clientUDPAddress: receiveAddr!)
        if presentedViewController != nil {
            dismiss(animated: true, completion: {
                self.present(nextVC, animated: true, completion: nil)
            })
        } else {
            present(nextVC, animated: true, completion: nil)
        }
    }

    private func nc() -> NotificationCenter {
        return NotificationCenter.default
    }
}
