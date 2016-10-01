//
//  PlaceMarker.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/28/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

class PlaceMarker: GMSMarker {
  let place: MyPlace
  
  init(place: MyPlace) {
    self.place = place
    super.init()
    
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = kGMSMarkerAnimationPop
    
    //icon = UIImage(named: place.placeType+"_pin")
    icon = UIImage(named: "default_marker.png")
    
    position = place.coordinate
    
    title = place.json["name"].string
    snippet = place.json["snippet_text"].string
    
  }
}
