//
//  ViewController.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/13/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let apiConsoleInfo = YelpAPIConsole()
    
    let client = YelpAPIClient()

    @IBOutlet var burgerLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func searchForBurgerPlaces() {
        client.searchPlacesWithParameters(["ll": "37.788022,-122.399797", "category_filter": "burgers", "radius_filter": "3000", "sort": "0"], successSearch: { (data, response) -> Void in
            print(NSString(data: data, encoding: NSUTF8StringEncoding))
            self.burgerLabel.text = String(self.client.searchPlacesWithParameters(["ll": "37.788022,-122.399797", "category_filter": "burgers", "radius_filter": "3000", "sort": "0"], successSearch: { (data, response) -> Void in
            }) { (error) -> Void in
                print(error)
            })

        }) { (error) -> Void in
            print(error)
        }
        
    }
    
}

