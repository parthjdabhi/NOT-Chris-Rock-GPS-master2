//
//  PlaceMarker.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/28/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

class BizMarker: GMSMarker {
  let biz: Business
  
  init(biz: Business) {
    self.biz = biz
    super.init()
    
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = kGMSMarkerAnimationPop
    
    //icon = UIImage(named: place.placeType+"_pin")
    icon = UIImage(named: "default_marker.png")
    
    position = biz.coordinate!
    
    title = biz.name
    snippet = biz.address
    
  }
    
    func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        //view.endEditing(true)
        //super.touchesBegan(touches, withEvent: event)
    }
}
