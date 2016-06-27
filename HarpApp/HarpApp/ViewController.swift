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


var __acceptedSock : CFSocket!


func socketCallback(sock: CFSocket!, type: CFSocketCallBackType, var address: CFData!, data: UnsafePointer<Void>, info: UnsafeMutablePointer<Void>) -> Void {

    assert(type == .DataCallBack, "Unexpected callback type")
    print("WHATEVER")
//    let sockObj = fromContext(UnsafeMutablePointer<SocketAccept>(info))
//    assert(sockObj.underlying === sock, "Unexpected socket")
//    sockObj._didAccept(UnsafePointer<Int32!>(data).memory)
}




class ViewController: UIViewController, SocketAcceptDelegate {

    var reg : BluetoothService.Registration!

    let regType = "_harp._tcp"
    var acceptSocket : SocketAccept!

    override func viewDidLoad() {
        super.viewDidLoad()

        acceptSocket = SocketAccept()
        acceptSocket.delegate = self

        // Pass an accept socket into it, it emits connections?
        reg = BluetoothService.Registration(format: regType, port: acceptSocket.port.littleEndian)
        reg.start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didAccept(nativeHandle: Int32!) {
        print("did Accept!")

        print("Native handle is: \(nativeHandle)")
        let daOptions: CFSocketCallBackType = [.DataCallBack]
        __acceptedSock = CFSocketCreateWithNative(nil, nativeHandle, daOptions.rawValue, socketCallback, nil)



        var send = "hello world"

        // C interop with swift strings!  Awesome!
        // Also see the String getBytes or getCString methods provided by Swift
        var sendData = CFDataCreateWithBytesNoCopy(nil, "hello world", send.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), nil)
        let err = CFSocketSendData(__acceptedSock, nil, sendData, -1)
        print("Socket send err is: \(err.rawValue)")
    }
}

