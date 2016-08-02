//
//  ViewController.swift
//  DeleteMeSometime
//
//  Created by Lou Zell on 6/13/16.
//  Copyright © 2016 Lou Zell. All rights reserved.



import UIKit

class ViewController: UIViewController {

    let networker = Networker(numConnections: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        networker.sync()
    }
}