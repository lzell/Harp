//
//  AppDelegate.swift
//  OpenJoypadClient
//
//  Created by Lou Zell on 6/3/16.
//  Copyright © 2016 Lou Zell. All rights reserved.
//

import Cocoa
import HarpCommonOSX



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    @IBOutlet weak var window: NSWindow!

    var bluetoothServiceResolver : BluetoothService.Resolver!

    var socketComm : SocketComm!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        bluetoothServiceResolver = BluetoothService.Resolver(format: "_harp._tcp")
        bluetoothServiceResolver.start() {  (bluetoothService) in
            for sockAddr in bluetoothService.addresses {
                printAddress(sockAddr)
            }
            self.sendPayloadTo(bluetoothService.addresses[0])
            self.bluetoothServiceResolver.stop()
            self.bluetoothServiceResolver = nil
        }
    }

    func sendPayloadTo(addr: sockaddr_in6) {
        socketComm = SocketComm(addr6: addr)
//        socketComm.send(payload)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func payload(udpPort: UInt16) -> String {
        return "Blah blah blah"
    }
    
    
}



