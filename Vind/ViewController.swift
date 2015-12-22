//
//  ViewController.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let connection = SMHIObservationConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connection.weatherObservation { result in
            print(result)
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

