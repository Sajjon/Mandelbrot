//
//  ViewController.swift
//  MandelbrotSwift
//
//  Created by Clara Cyon on 2015-12-07.
//  Copyright (c) 2015 Clara Cyon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mandelbrotView = MandelbrotView(frame: self.view.frame)
        self.view.addSubview(mandelbrotView)
    }
}

