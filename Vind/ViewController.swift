//
//  ViewController.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let connection = SMHIWeatherConnection()
    //    var sjofartsverketConnection = SjofartsverketWeatherConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        connection.weatherAtLocationId(97200, services: [.Temperature], completion: { result in
            print(result)
        })
//        connection.weatherObservation { result in
//            print(result)
//        }
        
//        sjofartsverketConnection.weatherAtLocationId(2, completion:{ (result: Result) -> Void in
//            switch result {
//            case .Success(let wind):
//                print(wind)
//            case .Error(let e):
//                print("Error: \(e)")
//            }
//        })
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

