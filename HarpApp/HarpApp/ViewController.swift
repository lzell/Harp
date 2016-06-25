//
//  ViewController.swift
//  DeleteMeSometime
//
//  Created by Lou Zell on 6/13/16.
//  Copyright © 2016 Lou Zell. All rights reserved.



import UIKit
import HarpCommoniOS


//func sendIt() {
//        if CFSocketIsValid(acceptedSock) {
//            let data = CFDataCreate(nil, UnsafePointer<UInt8>(ptr), toSend.count)
//            let err = CFSocketSendData(acceptedSock, nil, data, -1)
//            print("Err is: \(err.rawValue)")
//        } else {
//        }
//    }
//}




class ViewController: UIViewController {

    var reg : BluetoothService.Registration!

    let regType = "_harp._tcp"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        reg = BluetoothService.Registration(format: regType)
        reg.start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

