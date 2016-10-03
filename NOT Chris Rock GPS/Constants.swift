//
//  Constants.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/13/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation

let BaseURL = "http://www.notchrisrock.com/gps/api/"

//Login Registration API
let url_login           = BaseURL + "login.php"
let url_register        = BaseURL + "register.php"
let url_fb_register     = BaseURL + "facebook_register.php"
let url_updateProfile   = BaseURL + "update.php"

let url_setProfilePic   = BaseURL + "profile.php"
let url_soundFiles      = BaseURL + "sounds.php"
let url_saveRecording   = BaseURL + "upload_file.php"

let googlePlacesAPIKey  = "AIzaSyCQ9yhrhgV3OEJPzFb_87XfJzl0O3_OXRM"
let googleMapsApiKey    = "AIzaSyB5jzZt5pc9-WVIEvfaBIZAIvQOYLhVu94"

let foodTypes           = ["American", "Mexican", "Italian", "Chinese", "Asian", "Indian", "Mediterranean", "BBQ", "Fast Food", "Steak", "Soups", "Salads", "Pizza", "Southern", "Cajun"]
let genderType          = ["Male", "Female"]


let clrGreen = UIColor.init(rgb: 0x1abc9c)
let clrBlackSelected = UIColor.init(rgb: 0x222831)
let clrBlack = UIColor.init(rgb: 0x222831)

let clrOrange = UIColor(red: 208/255.0, green: 88/255.0, blue: 0.1/255.0, alpha: 1.0)
let clrRed = UIColor(red: 228/255.0, green: 81/255.0, blue: 55/255.0, alpha: 1.0)
let clrPurple = UIColor(red: 154/255.0, green: 88/255.0, blue: 186/255.0, alpha: 1.0)


//Global Data
var CLocation:CLLocation?// = CLLocation()
var CLocationSelected:CLLocation = CLLocation()
var CLocationPlace:String = String()

//YELP Api
let apiConsoleInfo = YelpAPIConsole()
//let client = YelpAPIClient()

var businessArr: [Business]? = nil
var searchString = ""
var Myfilters = Filters()