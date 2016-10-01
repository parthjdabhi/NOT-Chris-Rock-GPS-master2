//
//  MyPlace.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/28/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import SwiftyJSON
import SDWebImage

class MyPlace {
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    //let placeType: String
    var photoUrl: String?
    var photo: UIImage?
    var ratingUrl: String?
    var ratingPhoto: UIImage?
    var json: JSON
    
    //init(dictionary:[String : AnyObject], Types: [String]?)
    init(json:JSON, Types: [String]?)
    {
        //let json = JSON(dictionary)
        self.json = json
        name = json["name"].stringValue
        address = json["snippet_text"].stringValue
        
        let lat = json["location"]["coordinate"]["latitude"].doubleValue as CLLocationDegrees
        let lng = json["location"]["coordinate"]["longitude"].doubleValue as CLLocationDegrees
        coordinate = CLLocationCoordinate2DMake(lat, lng)
        
        photoUrl = json["image_url"].string
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: json["image_url"].string ?? ""), options: .RetryFailed, progress: nil, completed: { (image, error, catche, flag, url) in
            self.photo = image
        })
        
        ratingUrl = json["rating_img_url"].string       //rating_img_url_large
        SDWebImageManager.sharedManager().downloadImageWithURL(NSURL(string: ratingUrl ?? ""), options: .RetryFailed, progress: nil, completed: { (image, error, catche, flag, url) in
            self.ratingPhoto = image
        })
        
        //    var foundType = "restaurant"
        //    let possibleTypes = acceptedTypes.count > 0 ? Types : ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
        //    for type in json["types"].arrayObject as! [String] {
        //      if possibleTypes.contains(type) {
        //        foundType = type
        //        break
        //      }
        //    }
        //    placeType = foundType
    }
}
