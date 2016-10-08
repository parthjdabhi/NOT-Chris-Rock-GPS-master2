//
//  Filters.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/3/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation

// Model class that represents the user's search filterring
class Filters: NSObject {
    
    //Voice Setting
    var SettingMain = "Family Mode"
    var SettingSub = "Medium"
    
    var hasDeal = false
    var distance: Float? = 0.0
    var sortBy: Int? = 0
    var categories = [String]()
    override init() {
        
    }
}
