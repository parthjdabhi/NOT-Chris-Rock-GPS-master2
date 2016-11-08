//
//  ViewController.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/13/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

import SVProgressHUD
import AVFoundation
import KDEAudioPlayer

class AppState: NSObject {
    
    static let sharedInstance = AppState()
    
    var signedIn = false
    var displayName: String?
    var photoUrl: NSURL?
}

//Global Data
//var userData: [String : AnyObject] = [:]
var userDetail:Dictionary<String,AnyObject> = [:]
var user_id:String = {
    if let uid = userDetail["user_id"] as? Int {
        return String(uid)
    } else {
        return userDetail["user_id"] as? String ?? ""
    }
}()


//var CLocation:CLLocation = CLLocation()
//var CLocationPlace:String = String()
//
//var timeline:Array<JSON> = []
//var myTimeline:Array<JSON> = []
//var searchTimeline:Array<JSON> = []
//var selectedPhoto:JSON = []

// Sounds
var audioPlayer:AVPlayer? = AVPlayer()
var mp3Urls = [NSURL]()
var player = AudioPlayer()
var AudioItems:[AudioItem]? = [AudioItem]()

