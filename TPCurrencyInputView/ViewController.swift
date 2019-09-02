//
//  ViewController.swift
//  TPCurrencyInputView
//
//  Created by Tarun on 28/07/19.
//  Copyright © 2019 Tarun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var currencyView: TPCurrencyInputView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currencyView.font = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.largeTitle).pointSize)
        
    }


}










































