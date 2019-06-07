//
//  SCTestControllerViewController.swift
//  SpectroBLETest
//
//  Created by Teja's MacBook on 26/04/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit

class TestControllerViewController: UIViewController {

    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var acivityIndiCator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var backBuon: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startButon(_ sender: Any) {
    }
    @IBAction func abortButton(_ sender: Any) {
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
