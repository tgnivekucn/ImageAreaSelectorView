//
//  ViewController.swift
//  ImageAreaSelectorView
//
//  Created on 2023/12/22.
//

import UIKit

class ViewController: UIViewController {
    var customView: ImageAreaSelectorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        customView = ImageAreaSelectorView(frame: CGRect(x: 50, y: 100, width: 300, height: 300))
        if let customView = customView {
            customView.backgroundColor = .yellow
            self.view.addSubview(customView)
        }
        
    }


}

