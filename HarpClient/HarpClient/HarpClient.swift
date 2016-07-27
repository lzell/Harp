import Foundation
import HarpCommonOSX

class HarpClient : Proto1ReadContract {
    var bluetoothServiceResolver : BluetoothService.Resolver!

    var udpReadSocket : CFSocket!
    var udpReadPort : UInt16!

    let maxNumConcurrentConnections = 1
    var connections : [CFSocket]
    var pending : [CFSocket]

    init() {
        pending = []
        connections = []

        // Second phase
        let (sock, port) = createBindedUDPReadSocketWithReadCallback(toContext(self)) {
            (sock, _, _, _, info: UnsafeMutablePointer<Void>) in
            let me = fromContext(UnsafeMutablePointer<HarpClient>(info))
            me.doRead(sock)
        }
        udpReadSocket = sock
        udpReadPort = port
        print("Reading on UDP Port \(port)")
    }

    func removeSocket(sock: CFSocket, inout from: [CFSocket]) {
        let _idx = from.indexOf() { $0 === sock }
        if let idx = _idx {
            from.removeAtIndex(idx)
        }
    }

    func stopResolver() {
        guard bluetoothServiceResolver != nil else { return }
        bluetoothServiceResolver.stop()
        bluetoothServiceResolver = nil
    }

    func startResolver() {
        guard bluetoothServiceResolver == nil else { return }
        bluetoothServiceResolver = BluetoothService.Resolver(format: "_harp._tcp")
        bluetoothServiceResolver.start() {  [weak self] (bluetoothService) in
            for sockAddr in bluetoothService.addresses {
                printAddress(sockAddr)
            }
            // TODO: Assumption built in here... Need to compare addresses
            // to what we have already connected to
            self?.connectTo(bluetoothService.addresses[0])
            self?.stopResolver()
        }
    }

    func connectTo(addr: sockaddr_in6) {
        // This should really be called something CommSocket(connectTo:)
        let psock = createConnectingTCPSocketWithConnectCallback(addr, toContext(self)) {
            (sock, type, _, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>)
            in

            let me = fromContext(UnsafeMutablePointer<HarpClient>(info))
            if type == .ConnectCallBack {
                if data == nil {
                    me.socketDidConnect(sock)
                } else {
                    // Data is a pointer to an SInt32 error code in this case
                    let errCode = UnsafePointer<Int32>(data).memory
                    perror(strerror(errCode))
                    assert(false)
                }
            } else {
                me.socketDidDisconnect(sock)
            }
        }

        pending.append(psock)
    }

    func socketDidDisconnect(sock: CFSocket) {
        removeSocket(sock, from: &connections)

        if connections.count < maxNumConcurrentConnections {
            print("Connections dropped below max concurrent, restarting the search...")
            startResolver()
        }
    }

    func socketDidConnect(sock: CFSocket) {
        removeSocket(sock, from: &pending)
        connections.append(sock)
        sendClientRequest(sock)
    }

    func sendClientRequest(sock: CFSocket) {
        let content = payload()
        let sendData = CFDataCreateWithBytesNoCopy(nil, content, content.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), kCFAllocatorNull)
        if CFSocketSendData(sock, nil, sendData, -1) != .Success {
            assert(false, "Socket send failed")
        }
    }

    private func doRead(sock: CFSocket) {
        var buf = [UInt8](count: 8, repeatedValue: 0)
        let bytesRead = recv(CFSocketGetNative(sock), &buf, buf.count, 0)
        var posixErr: Int32 = 0

        if (bytesRead < 0) {
            posixErr = errno
        } else if (bytesRead == 0) {
            posixErr = EPIPE
        } else {
            assert(bytesRead == 8)
            var state: UInt64 = UInt64(buf[0])
            for i in 1..<8 {
                state <<= 8
                state |= UInt64(buf[i])
            }
            handleState(state)
        }

        if (posixErr != 0) {
            assert(false, "Could not read udp data")
        }
    }

    private func handleState(bitPattern: UInt64) {
        let dpadState = dpadStateFromBitPattern(bitPattern)
        let bBtnState = bButtonStateFromBitPattern(bitPattern)
        let aBtnState = aButtonStateFromBitPattern(bitPattern)
        print("Dpad is: \(dpadState), b is: \(bBtnState), a is: \(aBtnState)")
    }


    private func payload() -> String {
        return  "Protocol-Version: 0.1.0\n" +
            "UDP-Port: \(udpReadPort)\n" +
        "Controller: Proto1ViewController"
    }

}