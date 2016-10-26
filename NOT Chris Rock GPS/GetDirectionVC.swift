//
//  ViewController.swift
//  TYDirectionSwift
//
//  Created by Thabresh on 9/6/16.
//  Copyright © 2016 VividInfotech. All rights reserved.
//


import UIKit
import MapKit
import GoogleMaps
import GooglePlaces
import SWRevealViewController
import SwiftyJSON
import SVProgressHUD
import AVFoundation
import KDEAudioPlayer

class GetDirectionVC: UIViewController,UITextFieldDelegate,UISearchBarDelegate, LocateOnTheMap {
    
    var searchResultController:SearchResultsController!
    var resultsArray = [String]()
    var fromClicked = Bool()
    var mapManager = DirectionManager()
    var tableData = NSDictionary()
    var directionDetail = NSArray()
    var polyline: MKPolyline = MKPolyline()
    let markerNextTurn = GMSMarker()
    
    var audioPlayer:AVPlayer? = AVPlayer()
    var mp3Urls = [NSURL]()
    var player = AudioPlayer()
    var AudioItems:[AudioItem]? = [AudioItem]()
    
    var bizForRoute: Business?
    var routeTimer:NSTimer?
    
    @IBOutlet var btnMenu: UIButton?
    //@IBOutlet weak var drawMap: MKMapView!
    @IBOutlet weak var googleMapsView : GMSMapView!
    @IBOutlet weak var txtTo: UITextField!
    @IBOutlet weak var txtFrom: UITextField!
    @IBOutlet weak var btnGetDirection: UIButton!
    @IBOutlet weak var btnStartRoute: UIButton!
    @IBOutlet weak var btnRefresh: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchResultController = SearchResultsController()
        searchResultController.delegate = self
        
        btnGetDirection.enabled = false
        btnGetDirection.backgroundColor = UIColor.darkGrayColor()
        btnStartRoute.enabled = false
        btnStartRoute.backgroundColor = UIColor.darkGrayColor()
        self.btnStartRoute.tag == 1
        
        txtFrom.text = "Current Location"
        //txtFrom.text = "Santo Domingo"
        
        self.startFiveTapGesture()
        
        if bizForRoute != nil {
            self.btnMenu?.setTitle("Back", forState: .Normal)
            self.btnMenu?.addTarget(self, action: #selector(GetDirectionVC.actionGoToBack(_:)), forControlEvents: .TouchUpInside)
            self.txtTo.text = "\(bizForRoute?.coordinate?.latitude ?? 0),\(bizForRoute?.coordinate?.longitude ?? 0)"
            self.ClickToGo(nil)
        } else {
            // Init menu button action for menu
            if let revealVC = self.revealViewController() {
                self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
                //self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
                //self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
            }
        }
        
        //        player = AVPlayer(URL: NSURL(string: "\(BaseUrlSounds)Directional/to-the-left2.wav")!)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GetDirectionVC.playerDidFinishPlaying(_:)),
        //                                                         name: AVPlayerItemDidPlayToEndTimeNotification, object: player!.currentItem)
        
        
        let camera = GMSCameraPosition.cameraWithLatitude(53.9,longitude: 27.5667, zoom: 6)
        self.googleMapsView.animateToCameraPosition(camera)
        
        if LocationManager.sharedInstance.hasLastKnownLocation == false {
            LocationManager.sharedInstance.onFirstLocationUpdateWithCompletionHandler { (latitude, longitude, status, verboseMessage, error) in
                print(latitude,longitude,status)
                CLocation = CLLocation(latitude: latitude, longitude: longitude)
                self.googleMapsView.camera = GMSCameraPosition(target: CLocation!.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            }
        } else {
            self.googleMapsView.camera = GMSCameraPosition(target: CLocation!.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        }
        
        //self.googleMapsView.delegate = self
        self.googleMapsView.myLocationEnabled = true
        self.googleMapsView.settings.myLocationButton = true
        
        
//        AudioItems?.append(AudioItem(soundURLs: [AudioQuality.Medium : NSURL(string: "\(BaseUrlSounds)Directional/to-the-left2.wav")!])!)
//        AudioItems?.append(AudioItem(soundURLs: [AudioQuality.Medium : NSURL(string: "\(BaseUrlSounds)Directional/to-the-right.wav")!])!)
//        AudioItems?.append(AudioItem(soundURLs: [AudioQuality.Medium : NSURL(string: "\(BaseUrlSounds)Directional/to-the-left2.wav")!])!)
//        AudioItems?.append(AudioItem(soundURLs: [AudioQuality.Medium : NSURL(string: "\(BaseUrlSounds)Directional/to-the-right.wav")!])!)
//        AudioItems?.append(AudioItem(soundURLs: [AudioQuality.Medium : NSURL(string: "\(BaseUrlSounds)Directional/to-the-left2.wav")!])!)
//        player.mode = .NoRepeat
//        player.playItems(AudioItems!, startAtIndex: 0)
        
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        print("Video Finished")
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField .resignFirstResponder()
        if textField.tag == 0 {
            fromClicked = true
        } else {
            fromClicked = false
        }
        let searchController = UISearchController(searchResultsController: searchResultController)
        searchController.searchBar.delegate = self
        self.presentViewController(searchController, animated: true, completion: nil)
    }
    
    func locateWithLongitude(lon: Double, andLatitude lat: Double, andTitle title: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if self.fromClicked {
                self.txtFrom.text = title
                self.navigationItem.prompt = String(format: "From :%f,%f",lat,lon)
            } else {
                self.txtTo.text = title
                self.navigationItem.title = String(format: "TO :%f,%f",lat,lon)
            }
        }
    }
    
    func searchBar(searchBar: UISearchBar,
                   textDidChange searchText: String){
        let placesClient = GMSPlacesClient()
        placesClient.autocompleteQuery(searchText, bounds: nil, filter: nil) { (results, error:NSError?) -> Void in
            self.resultsArray.removeAll()
            if results == nil {
                return
            }
            for result in results!{
                if let result = result as? GMSAutocompletePrediction {
                    self.resultsArray.append(result.attributedFullText.string)
                }
            }
            self.searchResultController.reloadDataWithArray(self.resultsArray)
        }
    }
    
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.init(colorLiteralRed: 0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            polylineRenderer.lineWidth = 3
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
    
    func removeAllPlacemarkFromMap(shouldRemoveUserLocation shouldRemoveUserLocation:Bool){
        //        if let mapView = self.googleMapsView {
        //            for annotation in mapView.annotations{
        //                if shouldRemoveUserLocation {
        //                    if annotation as? MKUserLocation !=  mapView.userLocation {
        //                        mapView.removeAnnotation(annotation as MKAnnotation)
        //                    }
        //                }
        //                let overlays = mapView.overlays
        //                mapView.removeOverlays(overlays)
        //            }
        //        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actinoSetFromCurrentLocation(sender: AnyObject) {
        if let curLocation = CLocation
            where curLocation.coordinate.latitude != 0
                && curLocation.coordinate.longitude != 0
        {
            txtFrom.text = "Current Location"
        } else {
            SVProgressHUD.showInfoWithStatus("Oops, We are unable to find your location.. \n you can try to search")
        }
    }
    
    @IBAction func actionGoToBack(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func clickToGetDirection(sender: AnyObject) {
        if self.tableData.count > 0 {
            self .performSegueWithIdentifier("direction", sender: self)
            //self.DirectionDetailTableViewCell.hidden = false;
        }
    }
    
    @IBAction func actionStartRoute(sender: AnyObject)
    {
        if self.btnStartRoute.enabled
            && self.btnStartRoute.tag == 1
        {
            self.btnRefresh.hidden = true
            self.btnStartRoute.setTitle("Stop Route", forState: .Normal)
            self.btnStartRoute.backgroundColor = clrGreen
            self.btnStartRoute.tag = 2;
            
            let camera = GMSCameraPosition.cameraWithLatitude(LocationManager.sharedInstance.latitude,longitude: LocationManager.sharedInstance.longitude, zoom: 1)
            self.googleMapsView.animateToCameraPosition(camera)
            
            print("Start monitoring route")
            startObservingRoute()
        } else if self.btnStartRoute.enabled
            && self.btnStartRoute.tag == 2
        {
            self.btnRefresh.hidden = false
            self.btnStartRoute.setTitle("Start Route", forState: .Normal)
            self.btnStartRoute.backgroundColor = clrRed
            self.btnStartRoute.tag = 1;
            
            print("stop monitoring route")
            stopObservingRoute()
        }
    }
    
    
    func onEveryTwentyMinutesOfRoute()
    {
        //recordTimer?.invalidate()
        print("onEveryTwentyMinutesOfRoute \(routeTimer)")
        
        if let mp3Url = NSURL(string: "\(BaseUrlSounds)General-Categories/home-and-office-stores.wav") {
            //            mp3Urls.append(mp3Url)
            if let AudioIdem = AudioItem(soundURLs: [AudioQuality.Medium : mp3Url]) {
                player.mode = .NoRepeat
                player.playItem(AudioIdem)
            }
        }
    }
    
    func startObservingRoute()
    {
        //Start 20 Minute timer
        routeTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(GetDirectionVC.onEveryTwentyMinutesOfRoute), userInfo: nil, repeats: true)
        
        self.directionDetail = self.tableData.objectForKey("steps") as! NSArray
        print("",self.directionDetail)
        var routePos = 0
        let dictTable:NSDictionary = self.directionDetail[0] as! NSDictionary
        print("\n\n\n",dictTable)
        
        //cell.directionDetail.text =  dictTable["instructions"] as? String
        //let distance = dictTable["distance"] as! NSString
        let nextTurn = dictTable["end_location"] as! NSDictionary
        var nextTurnLocation = CLLocation(latitude: nextTurn["lat"] as? CLLocationDegrees ?? 0, longitude: nextTurn["lng"] as? CLLocationDegrees ?? 0)
        
        markerNextTurn.groundAnchor = CGPoint(x: 0.5, y: 1)
        markerNextTurn.appearAnimation = kGMSMarkerAnimationPop
        markerNextTurn.icon = UIImage(named: "pin_blue")
        markerNextTurn.title = dictTable.objectForKey("instructions") as! NSString as String
        markerNextTurn.position = nextTurnLocation.coordinate
        markerNextTurn.map = self.googleMapsView
        
        let camera = GMSCameraPosition.cameraWithLatitude(LocationManager.sharedInstance.latitude,longitude: LocationManager.sharedInstance.longitude, zoom: 15)
        self.googleMapsView.animateToCameraPosition(camera)
        
        LocationManager.sharedInstance.startUpdatingLocationWithCompletionHandler { (latitude, longitude, status, verboseMessage, error) in
            CLocation = CLLocation(latitude: latitude, longitude: longitude)
            print("Updating Location To Detect Turns : ",LocationManager.sharedInstance.latitude," - ",LocationManager.sharedInstance.longitude)
            
            print("Distance : ",nextTurnLocation.distanceFromLocation(LocationManager.sharedInstance.CLocation!))
            if nextTurnLocation.distanceFromLocation(LocationManager.sharedInstance.CLocation!) < 10
                && self.directionDetail.count > routePos
            {
                routePos += 1
                let dictTable:NSDictionary = self.directionDetail[routePos] as! NSDictionary
                print("\n\n\n",dictTable)
                let nextTurn = dictTable["end_location"] as! NSDictionary
                nextTurnLocation = CLLocation(latitude: nextTurn["lat"] as? CLLocationDegrees ?? 0, longitude: nextTurn["lng"] as? CLLocationDegrees ?? 0)
                self.markerNextTurn.position = nextTurnLocation.coordinate
                self.markerNextTurn.title = dictTable.objectForKey("instructions") as! NSString as String
                
                let camera = GMSCameraPosition.cameraWithLatitude(LocationManager.sharedInstance.latitude,longitude: LocationManager.sharedInstance.longitude, zoom: 15)
                self.googleMapsView.animateToCameraPosition(camera)
                
                //Turn right - /Directional/to-the-right.wav
                //Turn left - /Directional/to-the-left.wav
                //Keep right to - /Directional/to-the-right.wav
                //Keep left to - /Directional/to-the-left.wav
                
                // To play sound on base of instruction
                self.playSoundForInstruction(dictTable.objectForKey("instructions") as? NSString as? String)
            }
        }
    }
    
    func stopObservingRoute() {
        self.btnRefresh.hidden = false
        LocationManager.sharedInstance.startUpdatingLocationWithCompletionHandler(nil)
        markerNextTurn.map = nil
        
        //Stop 20 Minute timer
        routeTimer?.invalidate()
    }
    
    func playSoundForInstruction(instruction:String?) {
        guard let inst = instruction else {
            print("Instruction not found")
            return
        }
        
        print("Playing Sound for instruction : \(inst)")
        //self.AddAudioToQueue(ofUrl: "http://www.notchrisrock.com/gps/api/sounds/Route/route.wav")
        
        print(">>> >> > > Select Sound based on SettingMain & SettingSub : \(Myfilters.SettingMain)  \(Myfilters.SettingSub)")
        
        AudioItems = []
        
        // Start Route
//        if inst.containsString("StartRoute") {
//            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/lets-go.wav")
//        }
        
//        "And" = "&"
//        "A" = "a"
//        "B" = "b"
//        "C" = "c"
//        "D" = "d"
//        "E" = "e"
//        "F" = "f"
//        "G" = "g"
//        "H" = "h"
//        "I" = "i"
//        "J" = "j"
//        "K" = "k"
//        "L" = "l"
//        "M" = "m"
//        "N" = "n"
//        "O" = "o"
//        "P" = "p"
//        "Q" = "q"
//        "R" = "r"
//        "S" = "s"
//        "T" = "t"
//        "U" = "u"
//        "V" = "v"
//        "W" = "w"
//        "X" = "x"
//        "Y" = "y"
//        "Z" = "z"
//        " " = "-"
        
        // General Statements
        if inst.containsString("Airport") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/airports.wav")
        }
        if inst.containsString("Amusement Park") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/amuzement-parks.wav")
        }
        if inst.containsString("ATM") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/ATM.wav")
        }
        if inst.containsString("ATMs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/ATMs.wav")
        }
        if inst.containsString("Bank") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/banks.wav")
        }
        if inst.containsString("Barbershop") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/barbershops.wav")
        }
        if inst.containsString("Bars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/bars.wav")
        }
        if inst.containsString("Beauty") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/beauty-shops.wav")
        }
        if inst.containsString("Beer") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/beer.wav")
        }
        if inst.containsString("Bus Stops") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/bus-stops.wav")
        }
        if inst.containsString("Car Rental") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/car-rental.wav")
        }
        if inst.containsString("Clothing Store") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/clothing-stores.wav")
        }
        if inst.containsString("Coffee Shops") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/coffeeshops.wav")
        }
        if inst.containsString("Convenience Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/conv-stores.wav")
        }
        if inst.containsString("Department Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/department-stores.wav")
        }
        if inst.containsString("Desserts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/desserts.wav")
        }
        if inst.containsString("Drugstores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/drugstores.wav")
        }
        if inst.containsString("Dry Cleaners") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/dry-cleaners.wav")
        }
        if inst.containsString("Fast Food") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/fast-food.wav")
        }
        if inst.containsString("Fitness Centers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/fitness-centers.wav")
        }
        if inst.containsString("Gas Stations") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/gas-stations.wav")
        }
        if inst.containsString("Grocery Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/groceries-stores.wav")
        }
        if inst.containsString("Home & Office Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/home-and-office-stores.wav")
        }
        if inst.containsString("Home Services") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/home-services.wav")
        }
        if inst.containsString("Hospitals") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/hospitals.wav")
        }
        if inst.containsString("Hotels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/hotels.wav")
        }
        if inst.containsString("Landmarks") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/landmarks.wav")
        }
        if inst.containsString("Laundry") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/laundry.wav")
        }
        if inst.containsString("Movies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/movies.wav")
        }
        if inst.containsString("Museums") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/museums.wav")
        }
        if inst.containsString("Nightclubs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/nightclubs.wav")
        }
        if inst.containsString("Parking") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/parking.wav")
        }
        if inst.containsString("Parks") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/parks.wav")
        }
        if inst.containsString("Pet Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/pet-stores.wav")
        }
        if inst.containsString("Pharmacies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/pharmacies.wav")
        }
        if inst.containsString("Post Offices") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/post-offices.wav")
        }
        if inst.containsString("Restaurants") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/restaurants.wav")
        }
        if inst.containsString("Sporting Goods") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/sporting-goods.wav")
        }
        if inst.containsString("Tea & Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/tea-and-juice.wav")
        }
        if inst.containsString("Transit Stations") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/transit-stations.wav")
        }
        if inst.containsString("Wine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/wine.wav")
        }
        
        // Directional Statements
        if inst.containsString("Turn right") || inst.containsString("turns left") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-right.wav")
        } else if inst.containsString("Turn left") || inst.containsString("turns right") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-left.wav")
        } else if inst.containsString("Turn right onto") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-right2.wav")
        } else if inst.containsString("Turn left onto") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-left2.wav")
        }
        
        // Highway
        if inst.containsString("highway") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Highway/highway.wav")
        }
        
        // Food
        if inst.containsString("5 Guys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/5-guys.wav")
        }
        if inst.containsString("7/11") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/7-11.wav")
        }
        if inst.containsString("A&W") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/a&w.wav")
        }
        if inst.containsString("Applebees") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        if inst.containsString("Arbys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/arbys.wav")
        }
        if inst.containsString("Backyard Burgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/backyardburgers.wav")
        }
        if inst.containsString("Bakers Dozen Donuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bakers-dozen-donuts.wav")
        }
        if inst.containsString("Bar-B-Cutie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bar-b-cutie.wav")
        }
        if inst.containsString("Bar Burrito") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/barburrito.wav")
        }
        if inst.containsString("Baskin Robbins") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/baskin-robbins.wav")
        }
        if inst.containsString("Beaver Tails") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/beavertails.wav")
        }
        if inst.containsString("Ben & Florentine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-florentine.wav")
        }
        if inst.containsString("Ben & Jerrys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-jerrys.wav")
        }
        if inst.containsString("Benjys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/benjys.wav")
        }
        if inst.containsString("Big Boy") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/big-boy.wav")
        }
        if inst.containsString("BJs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bjs.wav")
        }
        if inst.containsString("Blimpie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/blimpie3.wav")
        }
        if inst.containsString("Bob Evans") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bob-evans.wav")
        }
        if inst.containsString("Bojangles") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bojangles.wav")
        }
        if inst.containsString("Bonefish Grill") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bonefish-grill.wav")
        }
        if inst.containsString("Booster-Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/booster-juice.wav")
        }
        if inst.containsString("Boston Market") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-market.wav")
        }
        if inst.containsString("Boston Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-pizza.wav")
        }
        if inst.containsString("Burger Baron") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-baron.wav")
        }
        if inst.containsString("Burger King") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-king.wav")
        }
        if inst.containsString("BW3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/BW3.wav")
        }
        if inst.containsString("C Lovers Fish-N-Chips") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/c-lovers-fish-n-chips.wav")
        }
        if inst.containsString("Captain Ds Seafood") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Capt-Ds-Seafood.wav")
        }
        if inst.containsString("Captain Submarine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/captain-submarine.wav")
        }
        if inst.containsString("Captains Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/capts-sub.wav")
        }
        if inst.containsString("Carls Jr") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carls-jr.wav")
        }
        if inst.containsString("Carrabbas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carrabbas.wav")
        }
        if inst.containsString("Checkers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/checkers.wav")
        }
        if inst.containsString("Cheddars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheddars.wav")
        }
        if inst.containsString("Cheesecake Factory") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheesecake-factory.wav")
        }
        if inst.containsString("Chez Ashton") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chez-aston.wav")
        }
        if inst.containsString("Chic-Fil-A") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chic-fil-a.wav")
        }
        if inst.containsString("Chicken Cottage") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-cottage.wav")
        }
        if inst.containsString("Chicken Delight") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-delight.wav")
        }
        if inst.containsString("Chilis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chilis.wav")
        }
        if inst.containsString("Chipotle") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chipotle.wav")
        }
        if inst.containsString("Chuck-E-Cheese") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chuck-e-cheese.wav")
        }
        if inst.containsString("Churchs Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/churchs-chicken.wav")
        }
        if inst.containsString("Cicis Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cicis-pizza.wav")
        }
        if inst.containsString("Cinnabun") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cinnabun.wav")
        }
        if inst.containsString("Circle K") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/circle-k.wav")
        }
        if inst.containsString("Coffee Time") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/coffeetime.wav")
        }
        if inst.containsString("Cora") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cora.wav")
        }
        if inst.containsString("Country Style") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/countrystyle.wav")
        }
        if inst.containsString("Cows Ice Cream") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cows-ice-cream.wav")
        }
        if inst.containsString("CPK") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cpk.wav")
        }
        if inst.containsString("Cracker Barrel") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cracker-barrel.wav")
        }
        if inst.containsString("Culvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/culvers.wav")
        }
        if inst.containsString("Dairy Queen") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dairy-queen.wav")
        }
        if inst.containsString("Del Taco") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/del-taco")
        }
        if inst.containsString("Dennys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dennys.wav")
        }
        if inst.containsString("Dic Anns Hamburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dic-ann-hamburgers.wav")
        }
        if inst.containsString("Dixie Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-chicken.wav")
        }
        if inst.containsString("Dixie Lee Fried Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-lee-fried-chicken.wav")
        }
        if inst.containsString("Dominos") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dominos.wav")
        }
        if inst.containsString("Donut Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/donut-diner.wav")
        }
        if inst.containsString("Dunkin Donuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dunkin-donuts.wav")
        }
        if inst.containsString("East Side Marios") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/east-side-marios.wav")
        }
        if inst.containsString("Eat Restaurant") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/eat-restaurant.wav")
        }
        if inst.containsString("Edo Japan") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/edo-japan.wav")
        }
        if inst.containsString("Eds Easy Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        if inst.containsString("eds-easy-diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        if inst.containsString("Einstein Brothers Bagels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/einstein-bros-bagels.wav")
        }
        if inst.containsString("Extreme Pita") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/extreme-pita.wav")
        }
        if inst.containsString("Famous Daves") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/famous-daves.wav")
        }
        if inst.containsString("Fast Eddies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fast-eddies.wav")
        }
        if inst.containsString("Firehouse Subs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/firehouse-subs.wav")
        }
        if inst.containsString("Friendlys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/friendlys.wav")
        }
        if inst.containsString("Fryers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fryers.wav")
        }
        if inst.containsString("Gojis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/gojis.wav")
        }
        if inst.containsString("Golden Corral") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/golden-corral.wav")
        }
        if inst.containsString("Greco Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/greco-pizza.wav")
        }
        if inst.containsString("Hardees") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hardees.wav")
        }
        if inst.containsString("Harveys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/harveys.wav")
        }
        if inst.containsString("Heros Cert Burgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/heros-cert-burgers.wav")
        }
        if inst.containsString("Ho Lee Chow") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ho-lee-chow.wav")
        }
        if inst.containsString("Hooters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hooters.wav")
        }
        if inst.containsString("Humptys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/humptys.wav")
        }
        if inst.containsString("IHOP") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ihop.wav")
        }
        if inst.containsString("In-And-Out-Burger") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/in-and-out-burger.wav")
        }
        if inst.containsString("Jack In The Box") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jack-in-the-box.wav")
        }
        if inst.containsString("Jamba Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jamba-juice.wav")
        }
        if inst.containsString("Jasons Deli") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jasons-deli.wav")
        }
        if inst.containsString("Jimmy Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-johns.wav")
        }
        if inst.containsString("Jimmy The Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-the-greek.wav")
        }
        if inst.containsString("Jugo Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jugo-juice.wav")
        }
        if inst.containsString("Kaspas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kaspas.wav")
        }
        if inst.containsString("KFC") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kfc.wav")
        }
        if inst.containsString("Krispy Kreme Doughnuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krispy-kreme-dougnuts.wav")
        }
        if inst.containsString("Krystal") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krystal.wav")
        }
        if inst.containsString("Labelle Prov") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/labelle-prov.wav")
        }
        if inst.containsString("Licks Homeburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/licks-homeburgers.wav")
        }
        if inst.containsString("Little Caesars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-caesars.wav")
        }
        if inst.containsString("Little Chef") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-chef.wav")
        }
        if inst.containsString("Logans Roadhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/logans-roadhouse.wav")
        }
        if inst.containsString("Long John Silvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/long-john-silvers.wav")
        }
        if inst.containsString("Longhorn Steakhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/longhorn-steakhouse.wav")
        }
        if inst.containsString("Macaroni") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/macaroni-grill.wav")
        }
        if inst.containsString("Manchu Wok") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/manchu-wok.wav")
        }
        if inst.containsString("Mary Browns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mary-browns.wav")
        }
        if inst.containsString("McDonalds") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mcdonalds.wav")
        }
        if inst.containsString("Millies Cookies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/millies-cookies.wav")
        }
        if inst.containsString("Moes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/moes.wav")
        }
        if inst.containsString("Morleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/morleys.wav")
        }
        if inst.containsString("Mr. Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-greek.wav")
        }
        if inst.containsString("Mr. Mikes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-mikes.wav")
        }
        if inst.containsString("Mr. Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-sub.wav")
        }
        if inst.containsString("NY Fries") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ny-fries.wav")
        }
        if inst.containsString("Ocharleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Ocharleys.wav")
        }
        if inst.containsString("Olive Garden") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/olive-garden.wav")
        }
        if inst.containsString("On The Border") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/on-the-border.wav")
        }
        if inst.containsString("Orange Julius") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/orange-julius.wav")
        }
        if inst.containsString("Outback") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/outback.wav")
        }
        if inst.containsString("Panago") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panago.wav")
        }
        if inst.containsString("Panda Express") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panda-express.wav")
        }
        if inst.containsString("Panera Bread") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panera-bread.wav")
        }
        if inst.containsString("Papa Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/papa-johns.wav")
        }
        
        
        
        // Interstate
        if inst.containsString("I-10") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i10.wav")
        }
        if inst.containsString("I-105") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i105.wav")
        }
        if inst.containsString("I-110") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i110.wav")
        }
        if inst.containsString("I-115") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i115.wav")
        }
        if inst.containsString("I-12") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i12.wav")
        }
        if inst.containsString("I-124") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i124.wav")
        }
        if inst.containsString("I-126") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i126.wav")
        }
        if inst.containsString("I-129") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i129.wav")
        }
        if inst.containsString("I-130") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i130.wav")
        }
        if inst.containsString("I-135") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i135.wav")
        }
        if inst.containsString("I-140") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i140.wav")
        }
        if inst.containsString("I-15") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i15.wav")
        }
        if inst.containsString("I-155") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i155.wav")
        }
        if inst.containsString("I-16") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i16.wav")
        }
        if inst.containsString("I-164") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i164.wav")
        }
        if inst.containsString("I-165") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i165.wav")
        }
        if inst.containsString("I-169") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i169.wav")
        }
        if inst.containsString("I-17") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i17.wav")
        }
        if inst.containsString("I-170") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i170.wav")
        }
        if inst.containsString("I-172") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i172.wav")
        }
        if inst.containsString("I-175") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i175.wav")
        }
        if inst.containsString("I-176") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i176.wav")
        }
        if inst.containsString("I-180") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i180.wav")
        }
        if inst.containsString("I-182") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i182.wav")
        }
        if inst.containsString("I-184") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i184.wav")
        }
        if inst.containsString("I-185") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i185.wav")
        }
        if inst.containsString("I-189") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i189.wav")
        }
        if inst.containsString("I-19") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i19.wav")
        }
        if inst.containsString("I-190") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i190.wav")
        }
        if inst.containsString("I-194") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i194.wav")
        }
        if inst.containsString("I-195") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i195.wav")
        }
        if inst.containsString("I-196") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i196.wav")
        }
        if inst.containsString("I-2") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i2.wav")
        }
        if inst.containsString("I-20") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i20.wav")
        }
        if inst.containsString("I-205") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i205.wav")
        }
        if inst.containsString("I-210") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i210.wav")
        }
        if inst.containsString("I-215") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i215.wav")
        }
        if inst.containsString("I-22") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i22.wav")
        }
        if inst.containsString("I-220") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i220.wav")
        }
        if inst.containsString("I-222") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i222.wav")
        }
        if inst.containsString("I-225") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i225.wav")
        }
        if inst.containsString("I-229") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i229.wav")
        }
        if inst.containsString("I-235") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i235.wav")
        }
        if inst.containsString("I-238") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i238.wav")
        }
        if inst.containsString("I-24") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i24.wav")
        }
        if inst.containsString("I-240") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i240.wav")
        }
        if inst.containsString("I-244") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i244.wav")
        }
        if inst.containsString("I-25") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i25.wav")
        }
        if inst.containsString("I-255") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i255.wav")
        }
        if inst.containsString("I-26") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i26.wav")
        }
        if inst.containsString("I-264") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i264.wav")
        }
        if inst.containsString("I-265") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i265.wav")
        }
        if inst.containsString("I-269") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i269.wav")
        }
        if inst.containsString("I-27") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i27.wav")
        }
        if inst.containsString("I-270") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i270.wav")
        }
        if inst.containsString("I-271") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i271.wav")
        }
        if inst.containsString("I-274") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i274.wav")
        }
        if inst.containsString("I-275") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i275.wav")
        }
        if inst.containsString("I-276") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i276.wav")
        }
        if inst.containsString("I-277") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i277.wav")
        }
        if inst.containsString("I-278") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i278.wav")
        }
        if inst.containsString("I-279") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i279.wav")
        }
        if inst.containsString("I-280") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i280.wav")
        }
        if inst.containsString("I-283") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i283.wav")
        }
        if inst.containsString("I-285") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i285.wav")
        }
        if inst.containsString("I-287") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i287.wav")
        }
        if inst.containsString("I-29") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i29.wav")
        }
        if inst.containsString("I-290") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i290.wav")
        }
        if inst.containsString("I-291") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i291.wav")
        }
        if inst.containsString("I-293") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i293.wav")
        }
        if inst.containsString("I-294") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i294.wav")
        }
        if inst.containsString("I-295") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i295.wav")
        }
        if inst.containsString("I-296") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i296.wav")
        }
        if inst.containsString("I-30") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i30.wav")
        }
        
        // Food Types & Reviews
        if inst.containsString("African") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/african.wav")
        }
        if inst.containsString("American") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/american.wav")
        }
        if inst.containsString("Argentinian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/argentinian.wav")
        }
        if inst.containsString("Asian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/asian.wav")
        }
        if inst.containsString("Bagels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/bagels.wav")
        }
        if inst.containsString("Bakery") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/bakeries.wav")
        }
        if inst.containsString("Barbeque") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/bbq")
        }
        if inst.containsString("Brazilian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/brazilian.wav")
        }
        if inst.containsString("Breakfast") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/breakfast.wav")
        }
        if inst.containsString("Cajun") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/cajun.wav")
        }
        if inst.containsString("Caribbean") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/carribean.wav")
        }
        if inst.containsString("Cheesecake") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/cheesecake.wav")
        }
        if inst.containsString("Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/chicken.wav")
        }
        if inst.containsString("Chinese") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/chinese.wav")
        }
        if inst.containsString("Coffee") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/coffee.wav")
        }
        if inst.containsString("Colombian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/colombian.wav")
        }
        if inst.containsString("Cuban") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/african.wav")
        }
        if inst.containsString("Delis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/desserts.wav")
        }
        if inst.containsString("Diners") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/diners.wav")
        }
        if inst.containsString("Dominican") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/dominican.wav")
        }
        if inst.containsString("Ecuadorian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/ecuadorian.wav")
        }
        if inst.containsString("Egyptian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/egyptian.wav")
        }
        if inst.containsString("El-Savadoran") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/el-savadoarn.wav")
        }
        if inst.containsString("Ethiopian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/ethiopian.wav")
        }
        if inst.containsString("Ethnic") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/ethnic.wav")
        }
        if inst.containsString("Expensive") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/expensive.wav")
        }
        if inst.containsString("Fast Food") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/fast-food.wav")
        }
        if inst.containsString("Filipino") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/filipino.wav")
        }
        if inst.containsString("Fine Dining") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/find-dining.wav")
        }
        if inst.containsString("Food Truck") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/food-trucks.wav")
        }
        if inst.containsString("French") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/french.wav")
        }
        if inst.containsString("Yogurt") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/frozen-yogurt.wav")
        }
        if inst.containsString("Gluten Free") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/gluten-free.wav")
        }
        if inst.containsString("Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/greek.wav")
        }
        if inst.containsString("Grocery Items") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/grocery-items.wav")
        }
        if inst.containsString("Grocery") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/grocery.wav")
        }
        if inst.containsString("Halal") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/halal.wav")
        }
        if inst.containsString("Hamburger") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/hamburger.wav")
        }
        
        // Distance Statements
        if inst.containsString("feet") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/feet.wav")
        }
        if inst.containsString("foot") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/foot.wav")
        }
        if inst.containsString("kilometer") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/kilometer.wav")
        }
        if inst.containsString("kilometers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/kilometers.wav")
        }
        if inst.containsString("meter") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/meter.wav")
        }
        if inst.containsString("meters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/meters.wav")
        }
        if inst.containsString("mile") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/mile.wav")
        }
        if inst.containsString("miles") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/miles.wav")
        }
        if inst.containsString("milimeter") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/milimeter.wav")
        }
        if inst.containsString("milimeters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/milimeters.wav")
        }
        if inst.containsString("minute") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/minute1.wav")
        }
        if inst.containsString("minutes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/minutes2.wav")
        }
        if inst.containsString("yard") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/yard.wav")
        }
        if inst.containsString("yards") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/yards.wav")
        }
        
        // Fractional Numbers
        if inst.containsString(".1") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.1.wav")
        }
        if inst.containsString(".2") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.2.wav")
        }
        if inst.containsString(".3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.3.wav")
        }
        if inst.containsString(".4") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.4.wav")
        }
        if inst.containsString(".5") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.5.wav")
        }
        if inst.containsString(".6") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.6.wav")
        }
        if inst.containsString(".7") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.7.wav")
        }
        if inst.containsString(".8") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.8.wav")
        }
        if inst.containsString(".9") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.9.wav")
        }
        
        // Number Statements
        if inst.containsString("1") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/1.wav")
        }
        if inst.containsString("2") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/2.wav")
        }
        if inst.containsString("3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/3.wav")
        }
        if inst.containsString("4") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/4.wav")
        }
        if inst.containsString("5") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/5.wav")
        }
        if inst.containsString("6") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/6.wav")
        }
        if inst.containsString("7") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/7.wav")
        }
        if inst.containsString("8") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/8.wav")
        }
        if inst.containsString("9") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/9.wav")
        }
        if inst.containsString("10") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/10.wav")
        }
        if inst.containsString("11") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/11.wav")
        }
        if inst.containsString("12") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/12.wav")
        }
        if inst.containsString("13") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/13.wav")
        }
        if inst.containsString("14") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/14.wav")
        }
        if inst.containsString("15") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/15.wav")
        }
        if inst.containsString("16") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/16.wav")
        }
        if inst.containsString("17") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/17.wav")
        }
        if inst.containsString("18") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/18.wav")
        }
        if inst.containsString("19") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/19.wav")
        }
        if inst.containsString("20") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/20.wav")
        }
        if inst.containsString("21") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/21.wav")
        }
        if inst.containsString("22") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/22.wav")
        }
        if inst.containsString("23") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/23.wav")
        }
        if inst.containsString("24") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/24.wav")
        }
        if inst.containsString("25") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/25.wav")
        }
        if inst.containsString("26") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/26.wav")
        }
        if inst.containsString("27") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/27.wav")
        }
        if inst.containsString("28") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/28.wav")
        }
        if inst.containsString("29") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/29.wav")
        }
        if inst.containsString("30") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/30.wav")
        }
        if inst.containsString("31") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/31.wav")
        }
        if inst.containsString("32") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/32.wav")
        }
        if inst.containsString("33") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/33.wav")
        }
        if inst.containsString("34") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/34.wav")
        }
        if inst.containsString("35") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/35.wav")
        }
        if inst.containsString("36") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/36.wav")
        }
        if inst.containsString("37") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/37.wav")
        }
        if inst.containsString("38") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/38.wav")
        }
        if inst.containsString("39") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/39.wav")
        }
        if inst.containsString("40") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/40.wav")
        }
        if inst.containsString("41") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/41.wav")
        }
        if inst.containsString("42") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/42.wav")
        }
        if inst.containsString("43") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/43.wav")
        }
        if inst.containsString("44") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/44.wav")
        }
        if inst.containsString("45") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/45.wav")
        }
        if inst.containsString("46") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/46.wav")
        }
        if inst.containsString("47") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/47.wav")
        }
        if inst.containsString("48") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/48.wav")
        }
        if inst.containsString("49") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/49.wav")
        }
        if inst.containsString("50") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/50.wav")
        }
        if inst.containsString("51") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/51.wav")
        }
        if inst.containsString("52") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/52.wav")
        }
        if inst.containsString("53") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/53.wav")
        }
        if inst.containsString("54") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/54.wav")
        }
        if inst.containsString("55") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/55.wav")
        }
        if inst.containsString("56") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/56.wav")
        }
        if inst.containsString("57") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/57.wav")
        }
        if inst.containsString("58") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/58.wav")
        }
        if inst.containsString("59") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/59.wav")
        }
        if inst.containsString("60") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/60.wav")
        }
        if inst.containsString("61") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/61.wav")
        }
        if inst.containsString("62") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/62.wav")
        }
        if inst.containsString("63") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/63.wav")
        }
        if inst.containsString("64") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/64.wav")
        }
        if inst.containsString("65") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/65.wav")
        }
        if inst.containsString("66") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsString("67") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/67.wav")
        }
        if inst.containsString("68") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/68.wav")
        }
        if inst.containsString("69") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/69.wav")
        }
        if inst.containsString("70") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/70.wav")
        }
        if inst.containsString("71") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/71.wav")
        }
        if inst.containsString("72") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/72.wav")
        }
        if inst.containsString("73") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/73.wav")
        }
        if inst.containsString("74") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/74.wav")
        }
        if inst.containsString("75") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/75.wav")
        }
        if inst.containsString("76") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/76.wav")
        }
        if inst.containsString("77") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsString("78") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/78.wav")
        }
        if inst.containsString("79") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/79.wav")
        }
        if inst.containsString("80") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/80.wav")
        }
        if inst.containsString("81") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/81.wav")
        }
        if inst.containsString("82") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/82.wav")
        }
        if inst.containsString("83") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/83.wav")
        }
        if inst.containsString("84") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/84.wav")
        }
        if inst.containsString("85") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/85.wav")
        }
        if inst.containsString("86") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/86.wav")
        }
        if inst.containsString("87") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/87.wav")
        }
        if inst.containsString("88") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("89") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/89.wav")
        }
        if inst.containsString("90") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/90.wav")
        }
        if inst.containsString("91") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/91.wav")
        }
        if inst.containsString("92") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/92.wav")
        }
        if inst.containsString("93") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/93.wav")
        }
        if inst.containsString("94") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/94.wav")
        }
        if inst.containsString("95") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/95.wav")
        }
        if inst.containsString("96") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/96.wav")
        }
        if inst.containsString("97") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/97.wav")
        }
        if inst.containsString("98") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/98.wav")
        }
        if inst.containsString("99") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("100") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/100.wav")
        }
        if inst.containsString("101") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/101.wav")
        }
        if inst.containsString("102") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/102.wav")
        }
        if inst.containsString("103") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/103.wav")
        }
        if inst.containsString("104") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/104.wav")
        }
        if inst.containsString("105") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/105.wav")
        }
        if inst.containsString("106") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/106.wav")
        }
        if inst.containsString("107") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/107.wav")
        }
        if inst.containsString("108") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/108.wav")
        }
        if inst.containsString("109") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/109.wav")
        }
        if inst.containsString("110") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/110.wav")
        }
        if inst.containsString("111") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/111.wav")
        }
        if inst.containsString("112") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/112.wav")
        }
        if inst.containsString("113") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/113.wav")
        }
        if inst.containsString("114") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/114.wav")
        }
        if inst.containsString("115") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/115.wav")
        }
        if inst.containsString("116") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/116.wav")
        }
        if inst.containsString("117") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/117.wav")
        }
        if inst.containsString("118") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/118.wav")
        }
        if inst.containsString("119") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/119.wav")
        }
        if inst.containsString("120") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/120.wav")
        }
        if inst.containsString("121") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/121.wav")
        }
        if inst.containsString("122") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/122.wav")
        }
        if inst.containsString("123") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/123.wav")
        }
        if inst.containsString("124") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/124.wav")
        }
        if inst.containsString("125") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/125.wav")
        }
        if inst.containsString("126") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/126.wav")
        }
        if inst.containsString("127") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/127.wav")
        }
        if inst.containsString("128") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/128.wav")
        }
        if inst.containsString("129") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/129.wav")
        }
        if inst.containsString("130") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/130.wav")
        }
        if inst.containsString("131") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/131.wav")
        }
        if inst.containsString("132") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/132.wav")
        }
        if inst.containsString("133") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/133.wav")
        }
        if inst.containsString("134") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/134.wav")
        }
        if inst.containsString("135") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/135.wav")
        }
        if inst.containsString("136") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/136.wav")
        }
        if inst.containsString("137") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/137.wav")
        }
        if inst.containsString("138") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/138.wav")
        }
        if inst.containsString("139") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/139.wav")
        }
        if inst.containsString("140") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/140.wav")
        }
        if inst.containsString("141") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/141.wav")
        }
        if inst.containsString("142") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/142.wav")
        }
        if inst.containsString("143") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/143.wav")
        }
        if inst.containsString("144") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/144.wav")
        }
        if inst.containsString("145") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/145.wav")
        }
        if inst.containsString("146") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/146.wav")
        }
        if inst.containsString("147") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/147.wav")
        }
        if inst.containsString("148") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/148.wav")
        }
        if inst.containsString("149") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/149.wav")
        }
        if inst.containsString("150") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/150.wav")
        }
        if inst.containsString("151") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/151.wav")
        }
        if inst.containsString("152") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/152.wav")
        }
        if inst.containsString("153") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/153.wav")
        }
        if inst.containsString("154") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/154.wav")
        }
        if inst.containsString("155") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/155.wav")
        }
        if inst.containsString("156") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/156.wav")
        }
        if inst.containsString("157") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/157.wav")
        }
        if inst.containsString("158") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/158.wav")
        }
        if inst.containsString("159") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/159.wav")
        }
        if inst.containsString("160") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/160.wav")
        }
        if inst.containsString("161") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/161.wav")
        }
        if inst.containsString("162") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/162.wav")
        }
        if inst.containsString("163") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/163.wav")
        }
        if inst.containsString("164") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/164.wav")
        }
        if inst.containsString("165") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/165.wav")
        }
        if inst.containsString("166") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/166.wav")
        }
        if inst.containsString("167") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/167.wav")
        }
        if inst.containsString("168") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/168.wav")
        }
        if inst.containsString("169") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/169.wav")
        }
        if inst.containsString("170") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/170.wav")
        }
        if inst.containsString("171") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/171.wav")
        }
        if inst.containsString("172") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/172.wav")
        }
        if inst.containsString("173") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/173.wav")
        }
        if inst.containsString("174") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/174.wav")
        }
        if inst.containsString("175") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/175.wav")
        }
        if inst.containsString("176") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/176.wav")
        }
        if inst.containsString("177") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/177.wav")
        }
        if inst.containsString("178") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/178.wav")
        }
        if inst.containsString("179") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/179.wav")
        }
        if inst.containsString("180") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/180.wav")
        }
        if inst.containsString("181") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/181.wav")
        }
        if inst.containsString("182") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/182.wav")
        }
        if inst.containsString("183") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/183.wav")
        }
        if inst.containsString("184") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/184.wav")
        }
        if inst.containsString("185") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/185.wav")
        }
        if inst.containsString("186") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/186.wav")
        }
        if inst.containsString("187") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/187.wav")
        }
        if inst.containsString("188") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/188.wav")
        }
        if inst.containsString("189") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/189.wav")
        }
        if inst.containsString("190") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/190.wav")
        }
        if inst.containsString("191") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/191.wav")
        }
        if inst.containsString("192") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/192.wav")
        }
        if inst.containsString("193") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/193.wav")
        }
        if inst.containsString("194") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/194.wav")
        }
        if inst.containsString("195") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/195.wav")
        }
        if inst.containsString("196") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/196.wav")
        }
        if inst.containsString("197") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/197.wav")
        }
        if inst.containsString("198") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/198.wav")
        }
        if inst.containsString("199") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/199.wav")
        }
        if inst.containsString("200") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/200.wav")
        }
        if inst.containsString("201") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/201.wav")
        }
        if inst.containsString("202") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/202.wav")
        }
        if inst.containsString("203") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/203.wav")
        }
        if inst.containsString("204") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/204.wav")
        }
        if inst.containsString("205") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/205.wav")
        }
        if inst.containsString("206") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/206.wav")
        }
        if inst.containsString("207") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/207.wav")
        }
        if inst.containsString("208") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/208.wav")
        }
        if inst.containsString("209") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/209.wav")
        }
        if inst.containsString("210") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/210.wav")
        }
        if inst.containsString("211") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/211.wav")
        }
        if inst.containsString("212") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/212.wav")
        }
        if inst.containsString("213") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/213.wav")
        }
        if inst.containsString("214") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/214.wav")
        }
        if inst.containsString("215") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/215.wav")
        }
        if inst.containsString("216") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/216.wav")
        }
        if inst.containsString("217") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/217.wav")
        }
        if inst.containsString("218") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/218.wav")
        }
        if inst.containsString("219") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/219.wav")
        }
        if inst.containsString("220") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/220.wav")
        }
        if inst.containsString("221") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/221.wav")
        }
        if inst.containsString("222") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/222.wav")
        }
        if inst.containsString("223") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/223.wav")
        }
        if inst.containsString("224") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/224.wav")
        }
        if inst.containsString("225") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/225.wav")
        }
        if inst.containsString("226") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/226.wav")
        }
        if inst.containsString("227") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/227.wav")
        }
        if inst.containsString("228") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/228.wav")
        }
        if inst.containsString("229") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/229.wav")
        }
        if inst.containsString("230") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/230.wav")
        }
        if inst.containsString("231") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/231.wav")
        }
        if inst.containsString("232") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/232.wav")
        }
        if inst.containsString("233") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/233.wav")
        }
        if inst.containsString("234") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/234.wav")
        }
        if inst.containsString("235") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/235.wav")
        }
        if inst.containsString("236") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/236.wav")
        }
        if inst.containsString("237") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/237.wav")
        }
        if inst.containsString("238") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/238.wav")
        }
        if inst.containsString("239") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/239.wav")
        }
        if inst.containsString("240") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/240.wav")
        }
        if inst.containsString("241") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/241.wav")
        }
        if inst.containsString("242") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/242.wav")
        }
        if inst.containsString("243") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/243.wav")
        }
        if inst.containsString("244") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/244.wav")
        }
        if inst.containsString("245") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/245.wav")
        }
        if inst.containsString("246") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/246.wav")
        }
        if inst.containsString("247") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/247.wav")
        }
        if inst.containsString("248") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/248.wav")
        }
        if inst.containsString("249") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/249.wav")
        }
        if inst.containsString("250") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/250.wav")
        }
        if inst.containsString("251") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/251.wav")
        }
        if inst.containsString("252") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/252.wav")
        }
        if inst.containsString("253") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/253.wav")
        }
        if inst.containsString("254") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/254.wav")
        }
        if inst.containsString("255") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/255.wav")
        }
        if inst.containsString("256") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/256.wav")
        }
        if inst.containsString("257") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/257.wav")
        }
        if inst.containsString("258") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/258.wav")
        }
        if inst.containsString("259") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/259.wav")
        }
        if inst.containsString("260") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/260.wav")
        }
        if inst.containsString("261") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/261.wav")
        }
        if inst.containsString("262") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/262.wav")
        }
        if inst.containsString("263") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/263.wav")
        }
        if inst.containsString("264") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/264.wav")
        }
        if inst.containsString("265") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/265.wav")
        }
        if inst.containsString("266") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/266.wav")
        }
        if inst.containsString("267") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/267.wav")
        }
        if inst.containsString("268") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/268.wav")
        }
        if inst.containsString("269") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/269.wav")
        }
        if inst.containsString("270") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/270.wav")
        }
        if inst.containsString("271") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/271.wav")
        }
        if inst.containsString("272") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/272.wav")
        }
        if inst.containsString("273") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/273.wav")
        }
        if inst.containsString("274") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/274.wav")
        }
        if inst.containsString("275") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/275.wav")
        }
        if inst.containsString("276") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/276.wav")
        }
        if inst.containsString("277") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/277.wav")
        }
        if inst.containsString("278") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/278.wav")
        }
        if inst.containsString("279") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/279.wav")
        }
        if inst.containsString("280") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/280.wav")
        }
        if inst.containsString("281") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/281.wav")
        }
        if inst.containsString("282") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/282.wav")
        }
        if inst.containsString("283") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/283.wav")
        }
        if inst.containsString("284") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/284.wav")
        }
        if inst.containsString("285") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/285.wav")
        }
        if inst.containsString("286") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/286.wav")
        }
        if inst.containsString("287") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/287.wav")
        }
        if inst.containsString("288") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/288.wav")
        }
        if inst.containsString("289") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/289.wav")
        }
        if inst.containsString("290") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/290.wav")
        }
        if inst.containsString("291") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/291.wav")
        }
        if inst.containsString("292") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/292.wav")
        }
        if inst.containsString("293") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/293.wav")
        }
        if inst.containsString("294") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/294.wav")
        }
        if inst.containsString("295") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/295.wav")
        }
        if inst.containsString("296") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/296.wav")
        }
        if inst.containsString("297") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/297.wav")
        }
        if inst.containsString("298") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/298.wav")
        }
        if inst.containsString("299") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/299.wav")
        }
        if inst.containsString("300") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/300.wav")
        }
        if inst.containsString("301") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/301.wav")
        }
        if inst.containsString("302") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/302.wav")
        }
        if inst.containsString("303") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/303.wav")
        }
        if inst.containsString("304") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/304.wav")
        }
        if inst.containsString("305") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/305.wav")
        }
        if inst.containsString("306") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/306.wav")
        }
        if inst.containsString("307") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/307.wav")
        }
        if inst.containsString("308") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/308.wav")
        }
        if inst.containsString("309") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/309.wav")
        }
        if inst.containsString("310") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/310.wav")
        }
        if inst.containsString("311") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/311.wav")
        }
        if inst.containsString("312") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/312.wav")
        }
        if inst.containsString("313") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/313.wav")
        }
        if inst.containsString("314") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/314.wav")
        }
        if inst.containsString("315") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/315.wav")
        }
        if inst.containsString("316") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/316.wav")
        }
        if inst.containsString("317") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/317.wav")
        }
        if inst.containsString("318") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/318.wav")
        }
        if inst.containsString("319") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/319.wav")
        }
        if inst.containsString("320") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/320.wav")
        }
        if inst.containsString("321") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/321.wav")
        }
        if inst.containsString("322") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/322.wav")
        }
        if inst.containsString("323") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/323.wav")
        }
        if inst.containsString("324") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/324.wav")
        }
        if inst.containsString("325") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/325.wav")
        }
        if inst.containsString("326") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/326.wav")
        }
        if inst.containsString("327") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/327.wav")
        }
        if inst.containsString("328") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/328.wav")
        }
        if inst.containsString("329") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/329.wav")
        }
        if inst.containsString("330") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/330.wav")
        }
        if inst.containsString("331") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/331.wav")
        }
        if inst.containsString("332") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/332.wav")
        }
        if inst.containsString("333") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/333.wav")
        }
        if inst.containsString("334") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/334.wav")
        }
        if inst.containsString("335") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/335.wav")
        }
        if inst.containsString("336") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/336.wav")
        }
        if inst.containsString("337") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/337.wav")
        }
        if inst.containsString("338") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/338.wav")
        }
        if inst.containsString("339") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/339.wav")
        }
        if inst.containsString("340") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/340.wav")
        }
        if inst.containsString("341") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/341.wav")
        }
        if inst.containsString("342") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/342.wav")
        }
        if inst.containsString("343") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/343.wav")
        }
        if inst.containsString("344") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/344.wav")
        }
        if inst.containsString("345") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/345.wav")
        }
        if inst.containsString("346") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/346.wav")
        }
        if inst.containsString("347") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/347.wav")
        }
        if inst.containsString("348") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/348.wav")
        }
        if inst.containsString("349") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/349.wav")
        }
        if inst.containsString("350") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/350.wav")
        }
        if inst.containsString("351") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/351.wav")
        }
        if inst.containsString("352") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/352.wav")
        }
        if inst.containsString("353") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/353.wav")
        }
        if inst.containsString("354") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/354.wav")
        }
        if inst.containsString("355") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/355.wav")
        }
        if inst.containsString("356") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/356.wav")
        }
        if inst.containsString("357") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/357.wav")
        }
        if inst.containsString("358") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/358.wav")
        }
        if inst.containsString("359") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/359.wav")
        }
        if inst.containsString("360") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/360.wav")
        }
        if inst.containsString("361") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/361.wav")
        }
        if inst.containsString("362") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/362.wav")
        }
        if inst.containsString("363") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/363.wav")
        }
        if inst.containsString("364") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/364.wav")
        }
        if inst.containsString("365") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/365.wav")
        }
        if inst.containsString("366") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/366.wav")
        }
        if inst.containsString("367") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/367.wav")
        }
        if inst.containsString("368") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/368.wav")
        }
        if inst.containsString("369") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/369.wav")
        }
        if inst.containsString("370") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/370.wav")
        }
        if inst.containsString("371") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/371.wav")
        }
        if inst.containsString("372") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/372.wav")
        }
        if inst.containsString("373") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/373.wav")
        }
        if inst.containsString("374") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/374.wav")
        }
        if inst.containsString("375") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/375.wav")
        }
        if inst.containsString("376") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/376.wav")
        }
        if inst.containsString("377") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/377.wav")
        }
        if inst.containsString("378") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/378.wav")
        }
        if inst.containsString("379") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/379.wav")
        }
        if inst.containsString("380") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/380.wav")
        }
        if inst.containsString("381") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/381.wav")
        }
        if inst.containsString("382") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/382.wav")
        }
        if inst.containsString("383") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/383.wav")
        }
        if inst.containsString("384") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/384.wav")
        }
        if inst.containsString("385") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/385.wav")
        }
        if inst.containsString("386") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/386.wav")
        }
        if inst.containsString("387") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/387.wav")
        }
        if inst.containsString("388") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/388.wav")
        }
        if inst.containsString("389") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/389.wav")
        }
        if inst.containsString("390") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/390.wav")
        }
        if inst.containsString("391") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/391.wav")
        }
        if inst.containsString("392") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/392.wav")
        }
        if inst.containsString("393") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/393.wav")
        }
        if inst.containsString("394") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/394.wav")
        }
        if inst.containsString("395") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/395.wav")
        }
        if inst.containsString("396") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/396.wav")
        }
        if inst.containsString("397") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/397.wav")
        }
        if inst.containsString("398") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/398.wav")
        }
        if inst.containsString("399") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/399.wav")
        }
        if inst.containsString("400") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/400.wav")
        }
        if inst.containsString("401") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/401.wav")
        }
        if inst.containsString("402") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/402.wav")
        }
        if inst.containsString("403") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/403.wav")
        }
        if inst.containsString("404") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/404.wav")
        }
        if inst.containsString("405") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/405.wav")
        }
        if inst.containsString("406") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/406.wav")
        }
        if inst.containsString("407") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/407.wav")
        }
        if inst.containsString("408") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/408.wav")
        }
        if inst.containsString("409") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/409.wav")
        }
        if inst.containsString("410") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/410.wav")
        }
        if inst.containsString("411") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/411.wav")
        }
        if inst.containsString("412") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/412.wav")
        }
        if inst.containsString("413") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/413.wav")
        }
        if inst.containsString("414") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/414.wav")
        }
        if inst.containsString("415") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/415.wav")
        }
        if inst.containsString("416") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/416.wav")
        }
        if inst.containsString("417") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/417.wav")
        }
        if inst.containsString("418") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/418.wav")
        }
        if inst.containsString("419") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/419.wav")
        }
        if inst.containsString("42") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/42.wav")
        }
        if inst.containsString("421") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/421.wav")
        }
        if inst.containsString("422") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/422.wav")
        }
        if inst.containsString("423") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/423.wav")
        }
        if inst.containsString("424") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/424.wav")
        }
        if inst.containsString("425") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/425.wav")
        }
        if inst.containsString("426") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/426.wav")
        }
        if inst.containsString("427") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/427.wav")
        }
        if inst.containsString("428") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/428.wav")
        }
        if inst.containsString("429") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/429.wav")
        }
        if inst.containsString("430") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/430.wav")
        }
        if inst.containsString("43") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/43.wav")
        }
        if inst.containsString("431") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/431.wav")
        }
        if inst.containsString("432") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/432.wav")
        }
        if inst.containsString("433") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/433.wav")
        }
        if inst.containsString("434") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/434.wav")
        }
        if inst.containsString("435") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/435.wav")
        }
        if inst.containsString("436") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/436.wav")
        }
        if inst.containsString("437") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/437.wav")
        }
        if inst.containsString("438") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/438.wav")
        }
        if inst.containsString("439") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/439.wav")
        }
        if inst.containsString("44") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/44.wav")
        }
        if inst.containsString("440") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/440.wav")
        }
        if inst.containsString("441") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/441.wav")
        }
        if inst.containsString("442") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/442.wav")
        }
        if inst.containsString("443") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/443.wav")
        }
        if inst.containsString("444") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/444.wav")
        }
        if inst.containsString("445") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/445.wav")
        }
        if inst.containsString("446") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/446.wav")
        }
        if inst.containsString("447") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/447.wav")
        }
        if inst.containsString("448") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/448.wav")
        }
        if inst.containsString("449") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/449.wav")
        }
        if inst.containsString("450") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/450.wav")
        }
        if inst.containsString("45") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/45.wav")
        }
        if inst.containsString("451") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/451.wav")
        }
        if inst.containsString("452") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/452.wav")
        }
        if inst.containsString("453") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/433.wav")
        }
        if inst.containsString("454") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/454.wav")
        }
        if inst.containsString("455") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/455.wav")
        }
        if inst.containsString("456") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/456.wav")
        }
        if inst.containsString("457") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/457.wav")
        }
        if inst.containsString("458") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/458.wav")
        }
        if inst.containsString("459") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/459.wav")
        }
        if inst.containsString("46") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/46.wav")
        }
        if inst.containsString("461") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/461.wav")
        }
        if inst.containsString("462") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/462.wav")
        }
        if inst.containsString("463") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/463.wav")
        }
        if inst.containsString("464") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/464.wav")
        }
        if inst.containsString("465") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/465.wav")
        }
        if inst.containsString("466") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/466.wav")
        }
        if inst.containsString("467") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/467.wav")
        }
        if inst.containsString("468") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/468.wav")
        }
        if inst.containsString("469") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/469.wav")
        }
        if inst.containsString("47") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/47.wav")
        }
        if inst.containsString("471") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/471.wav")
        }
        if inst.containsString("472") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/472.wav")
        }
        if inst.containsString("473") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/473.wav")
        }
        if inst.containsString("474") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/474.wav")
        }
        if inst.containsString("475") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/475.wav")
        }
        if inst.containsString("476") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/476.wav")
        }
        if inst.containsString("477") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/477.wav")
        }
        if inst.containsString("478") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/478.wav")
        }
        if inst.containsString("479") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/479.wav")
        }
        if inst.containsString("48") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/48.wav")
        }
        if inst.containsString("481") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/481.wav")
        }
        if inst.containsString("482") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/482.wav")
        }
        if inst.containsString("483") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/483.wav")
        }
        if inst.containsString("484") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/484.wav")
        }
        if inst.containsString("485") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/485.wav")
        }
        if inst.containsString("486") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/486.wav")
        }
        if inst.containsString("487") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/487.wav")
        }
        if inst.containsString("488") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/488.wav")
        }
        if inst.containsString("489") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/489.wav")
        }
        if inst.containsString("490") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/490.wav")
        }
        if inst.containsString("49") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/49.wav")
        }
        if inst.containsString("491") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/491.wav")
        }
        if inst.containsString("492") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/492.wav")
        }
        if inst.containsString("493") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/493.wav")
        }
        if inst.containsString("494") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/494.wav")
        }
        if inst.containsString("495") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/495.wav")
        }
        if inst.containsString("496") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/496.wav")
        }
        if inst.containsString("497") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/497.wav")
        }
        if inst.containsString("498") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/498.wav")
        }
        if inst.containsString("499") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/499.wav")
        }
        if inst.containsString("50") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/50.wav")
        }
        if inst.containsString("500") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/500.wav")
        }
        if inst.containsString("501") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/501.wav")
        }
        if inst.containsString("502") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/502.wav")
        }
        if inst.containsString("503") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/503.wav")
        }
        if inst.containsString("504") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/504.wav")
        }
        if inst.containsString("505") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/505.wav")
        }
        if inst.containsString("506") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/506.wav")
        }
        if inst.containsString("507") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/507.wav")
        }
        if inst.containsString("508") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/508.wav")
        }
        if inst.containsString("509") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/509.wav")
        }
        if inst.containsString("510") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/510.wav")
        }
        if inst.containsString("511") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/511.wav")
        }
        if inst.containsString("512") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/512.wav")
        }
        if inst.containsString("513") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/513.wav")
        }
        if inst.containsString("514") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/514.wav")
        }
        if inst.containsString("515") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/515.wav")
        }
        if inst.containsString("516") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/516.wav")
        }
        if inst.containsString("517") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/517.wav")
        }
        if inst.containsString("518") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/518.wav")
        }
        if inst.containsString("519") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/519.wav")
        }
        if inst.containsString("52") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/52.wav")
        }
        if inst.containsString("521") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/521.wav")
        }
        if inst.containsString("522") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/522.wav")
        }
        if inst.containsString("523") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/523.wav")
        }
        if inst.containsString("524") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/524.wav")
        }
        if inst.containsString("525") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/525.wav")
        }
        if inst.containsString("526") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/526.wav")
        }
        if inst.containsString("527") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/527.wav")
        }
        if inst.containsString("528") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/528.wav")
        }
        if inst.containsString("529") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/529.wav")
        }
        if inst.containsString("530") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/530.wav")
        }
        if inst.containsString("53") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/53.wav")
        }
        if inst.containsString("531") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/531.wav")
        }
        if inst.containsString("532") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/532.wav")
        }
        if inst.containsString("533") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/533.wav")
        }
        if inst.containsString("534") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/534.wav")
        }
        if inst.containsString("535") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/535.wav")
        }
        if inst.containsString("536") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/536.wav")
        }
        if inst.containsString("537") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/537.wav")
        }
        if inst.containsString("538") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/538.wav")
        }
        if inst.containsString("539") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/539.wav")
        }
        if inst.containsString("54") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/54.wav")
        }
        if inst.containsString("540") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/540.wav")
        }
        if inst.containsString("541") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/541.wav")
        }
        if inst.containsString("542") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/542.wav")
        }
        if inst.containsString("543") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/543.wav")
        }
        if inst.containsString("544") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/544.wav")
        }
        if inst.containsString("545") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/545.wav")
        }
        if inst.containsString("546") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/546.wav")
        }
        if inst.containsString("547") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/547.wav")
        }
        if inst.containsString("548") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/548.wav")
        }
        if inst.containsString("549") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/549.wav")
        }
        if inst.containsString("550") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/550.wav")
        }
        if inst.containsString("55") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/55.wav")
        }
        if inst.containsString("551") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/551.wav")
        }
        if inst.containsString("552") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/552.wav")
        }
        if inst.containsString("553") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/533.wav")
        }
        if inst.containsString("554") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/554.wav")
        }
        if inst.containsString("555") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/555.wav")
        }
        if inst.containsString("556") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/556.wav")
        }
        if inst.containsString("557") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/557.wav")
        }
        if inst.containsString("558") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/558.wav")
        }
        if inst.containsString("559") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/559.wav")
        }
        if inst.containsString("56") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/56.wav")
        }
        if inst.containsString("560") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsString("561") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/561.wav")
        }
        if inst.containsString("562") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/562.wav")
        }
        if inst.containsString("563") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/563.wav")
        }
        if inst.containsString("564") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/564.wav")
        }
        if inst.containsString("565") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/565.wav")
        }
        if inst.containsString("566") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/566.wav")
        }
        if inst.containsString("567") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/567.wav")
        }
        if inst.containsString("568") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/568.wav")
        }
        if inst.containsString("569") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/569.wav")
        }
        if inst.containsString("57") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/57.wav")
        }
        if inst.containsString("571") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/571.wav")
        }
        if inst.containsString("572") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/572.wav")
        }
        if inst.containsString("573") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/573.wav")
        }
        if inst.containsString("574") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/574.wav")
        }
        if inst.containsString("575") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/575.wav")
        }
        if inst.containsString("576") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/576.wav")
        }
        if inst.containsString("577") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/577.wav")
        }
        if inst.containsString("578") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/578.wav")
        }
        if inst.containsString("579") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/579.wav")
        }
        if inst.containsString("58") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/58.wav")
        }
        if inst.containsString("581") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/581.wav")
        }
        if inst.containsString("582") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/582.wav")
        }
        if inst.containsString("583") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/583.wav")
        }
        if inst.containsString("584") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/584.wav")
        }
        if inst.containsString("585") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/585.wav")
        }
        if inst.containsString("586") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/586.wav")
        }
        if inst.containsString("587") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/587.wav")
        }
        if inst.containsString("588") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/588.wav")
        }
        if inst.containsString("589") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/589.wav")
        }
        if inst.containsString("590") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/590.wav")
        }
        if inst.containsString("59") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/59.wav")
        }
        if inst.containsString("591") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/591.wav")
        }
        if inst.containsString("592") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/592.wav")
        }
        if inst.containsString("593") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/593.wav")
        }
        if inst.containsString("594") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/594.wav")
        }
        if inst.containsString("595") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/595.wav")
        }
        if inst.containsString("596") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/596.wav")
        }
        if inst.containsString("597") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/597.wav")
        }
        if inst.containsString("598") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/598.wav")
        }
        if inst.containsString("599") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/599.wav")
        }
        if inst.containsString("60") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/60.wav")
        }
        if inst.containsString("600") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/600.wav")
        }
        if inst.containsString("601") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/601.wav")
        }
        if inst.containsString("602") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/602.wav")
        }
        if inst.containsString("603") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/603.wav")
        }
        if inst.containsString("604") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/604.wav")
        }
        if inst.containsString("605") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/606.wav")
        }
        if inst.containsString("606") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/606.wav")
        }
        if inst.containsString("607") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/607.wav")
        }
        if inst.containsString("608") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/608.wav")
        }
        if inst.containsString("609") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/609.wav")
        }
        if inst.containsString("610") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/610.wav")
        }
        if inst.containsString("611") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/611.wav")
        }
        if inst.containsString("612") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/612.wav")
        }
        if inst.containsString("613") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/613.wav")
        }
        if inst.containsString("614") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/614.wav")
        }
        if inst.containsString("615") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/616.wav")
        }
        if inst.containsString("616") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/616.wav")
        }
        if inst.containsString("617") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/617.wav")
        }
        if inst.containsString("618") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/618.wav")
        }
        if inst.containsString("619") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/619.wav")
        }
        if inst.containsString("62") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/62.wav")
        }
        if inst.containsString("621") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/621.wav")
        }
        if inst.containsString("622") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/622.wav")
        }
        if inst.containsString("623") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/623.wav")
        }
        if inst.containsString("624") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/624.wav")
        }
        if inst.containsString("625") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/626.wav")
        }
        if inst.containsString("626") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/626.wav")
        }
        if inst.containsString("627") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/627.wav")
        }
        if inst.containsString("628") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/628.wav")
        }
        if inst.containsString("629") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/629.wav")
        }
        if inst.containsString("630") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/630.wav")
        }
        if inst.containsString("63") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/63.wav")
        }
        if inst.containsString("631") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/631.wav")
        }
        if inst.containsString("632") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/632.wav")
        }
        if inst.containsString("633") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/633.wav")
        }
        if inst.containsString("634") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/634.wav")
        }
        if inst.containsString("635") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/636.wav")
        }
        if inst.containsString("636") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/636.wav")
        }
        if inst.containsString("637") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/637.wav")
        }
        if inst.containsString("638") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/638.wav")
        }
        if inst.containsString("639") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/639.wav")
        }
        if inst.containsString("64") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/64.wav")
        }
        if inst.containsString("640") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/640.wav")
        }
        if inst.containsString("641") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/641.wav")
        }
        if inst.containsString("642") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/642.wav")
        }
        if inst.containsString("643") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/643.wav")
        }
        if inst.containsString("644") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/644.wav")
        }
        if inst.containsString("645") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/646.wav")
        }
        if inst.containsString("646") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/646.wav")
        }
        if inst.containsString("647") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/647.wav")
        }
        if inst.containsString("648") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/648.wav")
        }
        if inst.containsString("649") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/649.wav")
        }
        if inst.containsString("650") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/660.wav")
        }
        if inst.containsString("65") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsString("651") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/661.wav")
        }
        if inst.containsString("652") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/662.wav")
        }
        if inst.containsString("653") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/633.wav")
        }
        if inst.containsString("654") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/664.wav")
        }
        if inst.containsString("655") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsString("656") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsString("657") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/667.wav")
        }
        if inst.containsString("658") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/668.wav")
        }
        if inst.containsString("659") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/669.wav")
        }
        if inst.containsString("66") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsString("660") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsString("661") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/661.wav")
        }
        if inst.containsString("662") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/662.wav")
        }
        if inst.containsString("663") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/663.wav")
        }
        if inst.containsString("664") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/664.wav")
        }
        if inst.containsString("665") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsString("666") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsString("667") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/667.wav")
        }
        if inst.containsString("668") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/668.wav")
        }
        if inst.containsString("669") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/669.wav")
        }
        if inst.containsString("67") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/67.wav")
        }
        if inst.containsString("671") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/671.wav")
        }
        if inst.containsString("672") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/672.wav")
        }
        if inst.containsString("673") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/673.wav")
        }
        if inst.containsString("674") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/674.wav")
        }
        if inst.containsString("675") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/676.wav")
        }
        if inst.containsString("676") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/676.wav")
        }
        if inst.containsString("677") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/677.wav")
        }
        if inst.containsString("678") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/678.wav")
        }
        if inst.containsString("679") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/679.wav")
        }
        if inst.containsString("68") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/68.wav")
        }
        if inst.containsString("681") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/681.wav")
        }
        if inst.containsString("682") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/682.wav")
        }
        if inst.containsString("683") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/683.wav")
        }
        if inst.containsString("684") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/684.wav")
        }
        if inst.containsString("685") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/686.wav")
        }
        if inst.containsString("686") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/686.wav")
        }
        if inst.containsString("687") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/687.wav")
        }
        if inst.containsString("688") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/688.wav")
        }
        if inst.containsString("689") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/689.wav")
        }
        if inst.containsString("690") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/690.wav")
        }
        if inst.containsString("69") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/69.wav")
        }
        if inst.containsString("691") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/691.wav")
        }
        if inst.containsString("692") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/692.wav")
        }
        if inst.containsString("693") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/693.wav")
        }
        if inst.containsString("694") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/694.wav")
        }
        if inst.containsString("695") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/696.wav")
        }
        if inst.containsString("696") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/696.wav")
        }
        if inst.containsString("697") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/697.wav")
        }
        if inst.containsString("698") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/698.wav")
        }
        if inst.containsString("699") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/699.wav")
        }
        if inst.containsString("70") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/70.wav")
        }
        if inst.containsString("700") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/700.wav")
        }
        if inst.containsString("701") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/701.wav")
        }
        if inst.containsString("702") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/702.wav")
        }
        if inst.containsString("703") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/703.wav")
        }
        if inst.containsString("704") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/704.wav")
        }
        if inst.containsString("705") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/707.wav")
        }
        if inst.containsString("706") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/707.wav")
        }
        if inst.containsString("707") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/707.wav")
        }
        if inst.containsString("708") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/708.wav")
        }
        if inst.containsString("709") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/709.wav")
        }
        if inst.containsString("710") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/710.wav")
        }
        if inst.containsString("711") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/711.wav")
        }
        if inst.containsString("712") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/712.wav")
        }
        if inst.containsString("713") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/713.wav")
        }
        if inst.containsString("714") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/714.wav")
        }
        if inst.containsString("715") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/717.wav")
        }
        if inst.containsString("716") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/717.wav")
        }
        if inst.containsString("717") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/717.wav")
        }
        if inst.containsString("718") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/718.wav")
        }
        if inst.containsString("719") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/719.wav")
        }
        if inst.containsString("72") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/72.wav")
        }
        if inst.containsString("721") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/721.wav")
        }
        if inst.containsString("722") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/722.wav")
        }
        if inst.containsString("723") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/723.wav")
        }
        if inst.containsString("724") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/724.wav")
        }
        if inst.containsString("725") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/727.wav")
        }
        if inst.containsString("726") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/727.wav")
        }
        if inst.containsString("727") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/727.wav")
        }
        if inst.containsString("728") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/728.wav")
        }
        if inst.containsString("729") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/729.wav")
        }
        if inst.containsString("730") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/730.wav")
        }
        if inst.containsString("73") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/73.wav")
        }
        if inst.containsString("731") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/731.wav")
        }
        if inst.containsString("732") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/732.wav")
        }
        if inst.containsString("733") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/733.wav")
        }
        if inst.containsString("734") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/734.wav")
        }
        if inst.containsString("735") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/737.wav")
        }
        if inst.containsString("736") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/737.wav")
        }
        if inst.containsString("737") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/737.wav")
        }
        if inst.containsString("738") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/738.wav")
        }
        if inst.containsString("739") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/739.wav")
        }
        if inst.containsString("74") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/74.wav")
        }
        if inst.containsString("740") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/740.wav")
        }
        if inst.containsString("741") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/741.wav")
        }
        if inst.containsString("742") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/742.wav")
        }
        if inst.containsString("743") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/743.wav")
        }
        if inst.containsString("744") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/744.wav")
        }
        if inst.containsString("745") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/747.wav")
        }
        if inst.containsString("746") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/747.wav")
        }
        if inst.containsString("747") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/747.wav")
        }
        if inst.containsString("748") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/748.wav")
        }
        if inst.containsString("749") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/749.wav")
        }
        if inst.containsString("750") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/770.wav")
        }
        if inst.containsString("75") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsString("751") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/771.wav")
        }
        if inst.containsString("752") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/772.wav")
        }
        if inst.containsString("753") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/733.wav")
        }
        if inst.containsString("754") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/774.wav")
        }
        if inst.containsString("755") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("756") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("757") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("758") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/778.wav")
        }
        if inst.containsString("759") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/779.wav")
        }
        if inst.containsString("76") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsString("760") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsString("761") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/771.wav")
        }
        if inst.containsString("762") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/772.wav")
        }
        if inst.containsString("763") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/773.wav")
        }
        if inst.containsString("764") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/774.wav")
        }
        if inst.containsString("765") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("766") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("767") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("768") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/778.wav")
        }
        if inst.containsString("769") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/779.wav")
        }
        if inst.containsString("77") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsString("770") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("771") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/771.wav")
        }
        if inst.containsString("772") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/772.wav")
        }
        if inst.containsString("773") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/773.wav")
        }
        if inst.containsString("774") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/774.wav")
        }
        if inst.containsString("775") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("776") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("777") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsString("778") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/778.wav")
        }
        if inst.containsString("779") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/779.wav")
        }
        if inst.containsString("78") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/78.wav")
        }
        if inst.containsString("780") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("781") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/781.wav")
        }
        if inst.containsString("782") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/782.wav")
        }
        if inst.containsString("783") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/783.wav")
        }
        if inst.containsString("784") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/784.wav")
        }
        if inst.containsString("785") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/787.wav")
        }
        if inst.containsString("786") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/787.wav")
        }
        if inst.containsString("787") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/787.wav")
        }
        if inst.containsString("788") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/788.wav")
        }
        if inst.containsString("789") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/789.wav")
        }
        if inst.containsString("790") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/790.wav")
        }
        if inst.containsString("79") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/79.wav")
        }
        if inst.containsString("791") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/791.wav")
        }
        if inst.containsString("792") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/792.wav")
        }
        if inst.containsString("793") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/793.wav")
        }
        if inst.containsString("794") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/794.wav")
        }
        if inst.containsString("795") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/797.wav")
        }
        if inst.containsString("796") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/797.wav")
        }
        if inst.containsString("797") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/797.wav")
        }
        if inst.containsString("798") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/798.wav")
        }
        if inst.containsString("799") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/799.wav")
        }
        if inst.containsString("80") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/80.wav")
        }
        if inst.containsString("800") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/800.wav")
        }
        if inst.containsString("801") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/801.wav")
        }
        if inst.containsString("802") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/802.wav")
        }
        if inst.containsString("803") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/803.wav")
        }
        if inst.containsString("804") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/804.wav")
        }
        if inst.containsString("805") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsString("806") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsString("807") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsString("808") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsString("809") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/809.wav")
        }
        if inst.containsString("810") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/810.wav")
        }
        if inst.containsString("811") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/811.wav")
        }
        if inst.containsString("812") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/812.wav")
        }
        if inst.containsString("813") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/813.wav")
        }
        if inst.containsString("814") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/814.wav")
        }
        if inst.containsString("815") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsString("816") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsString("817") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsString("818") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsString("819") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/819.wav")
        }
        if inst.containsString("82") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/82.wav")
        }
        if inst.containsString("821") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/821.wav")
        }
        if inst.containsString("822") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/822.wav")
        }
        if inst.containsString("823") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/823.wav")
        }
        if inst.containsString("824") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/824.wav")
        }
        if inst.containsString("825") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsString("826") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsString("827") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsString("828") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsString("829") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/829.wav")
        }
        if inst.containsString("830") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/830.wav")
        }
        if inst.containsString("83") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/83.wav")
        }
        if inst.containsString("831") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/831.wav")
        }
        if inst.containsString("832") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/832.wav")
        }
        if inst.containsString("833") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/833.wav")
        }
        if inst.containsString("834") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/834.wav")
        }
        if inst.containsString("835") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsString("836") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsString("837") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsString("838") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsString("839") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/839.wav")
        }
        if inst.containsString("84") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/84.wav")
        }
        if inst.containsString("840") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/840.wav")
        }
        if inst.containsString("841") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/841.wav")
        }
        if inst.containsString("842") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/842.wav")
        }
        if inst.containsString("843") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/843.wav")
        }
        if inst.containsString("844") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/844.wav")
        }
        if inst.containsString("845") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsString("846") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsString("847") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsString("848") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsString("849") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/849.wav")
        }
        if inst.containsString("850") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/880.wav")
        }
        if inst.containsString("85") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("851") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsString("852") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsString("853") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/833.wav")
        }
        if inst.containsString("854") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsString("855") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("856") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("857") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("858") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("859") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsString("86") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("860") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("861") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsString("862") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsString("863") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/883.wav")
        }
        if inst.containsString("864") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsString("865") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("866") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("867") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("868") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("869") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsString("87") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("870") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("871") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsString("872") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsString("873") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/883.wav")
        }
        if inst.containsString("874") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsString("875") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("876") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("877") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("878") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("879") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsString("88") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("880") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsString("881") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsString("882") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsString("883") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/883.wav")
        }
        if inst.containsString("884") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsString("885") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("886") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("887") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("888") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsString("889") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsString("890") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/890.wav")
        }
        if inst.containsString("89") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/89.wav")
        }
        if inst.containsString("891") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/891.wav")
        }
        if inst.containsString("892") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/892.wav")
        }
        if inst.containsString("893") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/893.wav")
        }
        if inst.containsString("894") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/894.wav")
        }
        if inst.containsString("895") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsString("896") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsString("897") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsString("898") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsString("899") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/899.wav")
        }
        if inst.containsString("90") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/90.wav")
        }
        if inst.containsString("900") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/900.wav")
        }
        if inst.containsString("901") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/901.wav")
        }
        if inst.containsString("902") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/902.wav")
        }
        if inst.containsString("903") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/903.wav")
        }
        if inst.containsString("904") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/904.wav")
        }
        if inst.containsString("905") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsString("906") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsString("907") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsString("908") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsString("909") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsString("910") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/910.wav")
        }
        if inst.containsString("911") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/911.wav")
        }
        if inst.containsString("912") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/912.wav")
        }
        if inst.containsString("913") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/913.wav")
        }
        if inst.containsString("914") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/914.wav")
        }
        if inst.containsString("915") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsString("916") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsString("917") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsString("918") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsString("919") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsString("92") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/92.wav")
        }
        if inst.containsString("921") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/921.wav")
        }
        if inst.containsString("922") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/922.wav")
        }
        if inst.containsString("923") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/923.wav")
        }
        if inst.containsString("924") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/924.wav")
        }
        if inst.containsString("925") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsString("926") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsString("927") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsString("928") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsString("929") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsString("930") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/930.wav")
        }
        if inst.containsString("93") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/93.wav")
        }
        if inst.containsString("931") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/931.wav")
        }
        if inst.containsString("932") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/932.wav")
        }
        if inst.containsString("933") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/933.wav")
        }
        if inst.containsString("934") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/934.wav")
        }
        if inst.containsString("935") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsString("936") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsString("937") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsString("938") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsString("939") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsString("94") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/94.wav")
        }
        if inst.containsString("940") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/940.wav")
        }
        if inst.containsString("941") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/941.wav")
        }
        if inst.containsString("942") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/942.wav")
        }
        if inst.containsString("943") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/943.wav")
        }
        if inst.containsString("944") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/944.wav")
        }
        if inst.containsString("945") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsString("946") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsString("947") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsString("948") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsString("949") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsString("950") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/990.wav")
        }
        if inst.containsString("95") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("951") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsString("952") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsString("953") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/933.wav")
        }
        if inst.containsString("954") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsString("955") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("956") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("957") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("958") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("959") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("96") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("960") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("961") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsString("962") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsString("963") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsString("964") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsString("965") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("966") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("967") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("968") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("969") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("97") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("970") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("971") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsString("972") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsString("973") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsString("974") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsString("975") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("976") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("977") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("978") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("979") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("98") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("980") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("981") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsString("982") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsString("983") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsString("984") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsString("985") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("986") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("987") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("988") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("989") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("990") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/990.wav")
        }
        if inst.containsString("99") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsString("991") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsString("992") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsString("993") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsString("994") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsString("995") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("996") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("997") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("998") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsString("999") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        
        
        StartPlaying()
    }
    
    func AddAudioToQueue(ofUrl url:String)
    {
        print("AddAudioToQueue : \(url)")
        
        if let mp3Url = NSURL(string: url) {
            //            mp3Urls.append(mp3Url)
            if let AudioIdem = AudioItem(soundURLs: [AudioQuality.Medium : mp3Url]) {
                AudioItems?.append(AudioIdem)
            }
        }
    }
    
    func StartPlaying() {
        
        //AudioItems to play multiple audio in queue
        guard let AudioItems1 = AudioItems where AudioItems1.count > 0 else {
            return
        }
        player.stop()
        player.mode = .NoRepeat
        player.playItems(AudioItems1, startAtIndex: 0)
        
        //AVPlayer to play single audio
        //        guard let mp3Url = AudioItems1.first else {
        //            return
        //        }
        //        print("playing soung for url : \(mp3Url)")
        //        do {
        //
        //            let playerItem = AVPlayerItem(URL: mp3Url.mediumQualityURL.URL)
        //
        //            self.audioPlayer = try AVPlayer(playerItem:playerItem)
        //            audioPlayer?.volume = 1.0
        //            audioPlayer?.play()
        //        } catch let error as NSError {
        //            self.audioPlayer = nil
        //            print(error.localizedDescription)
        //        } catch {
        //            print("AVAudioPlayer init failed")
        //        }
    }
    
    
    @IBAction func ClickToGo(sender: AnyObject?)
    {
        if self.btnStartRoute.enabled
            && self.btnStartRoute.tag == 2
        {
            self.btnStartRoute.setTitle("Start Route", forState: .Normal)
            self.btnStartRoute.backgroundColor = clrRed
            self.btnStartRoute.tag = 1;
            
            print("stop monitoring route")
            stopObservingRoute()
        }
        
        if isValidPincode()
        {
            //(from: txtFrom.text!, to: txtTo.text!)
            let from = (txtFrom.text! == "Current Location") ? "\(CLocation!.coordinate.latitude),\(CLocation!.coordinate.longitude)" : txtFrom.text!
            mapManager.directionsUsingGoogle(from: from, to: txtTo.text!) { (route,encodedPolyLine ,directionInformation, boundingRegion, error) -> () in
                
                if(error != nil)
                {
                    print(error)
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.btnGetDirection.enabled = true
                        self.btnGetDirection.backgroundColor = clrRed
                        self.btnStartRoute.enabled = true
                        self.btnStartRoute.backgroundColor = clrRed
                        self.btnStartRoute.tag = 1;
                        
                        let start_location = directionInformation?.objectForKey("start_location") as! NSDictionary
                        let originLat = start_location.objectForKey("lat")?.doubleValue
                        let originLng = start_location.objectForKey("lng")?.doubleValue
                        
                        let end_location = directionInformation?.objectForKey("end_location") as! NSDictionary
                        let destLat = end_location.objectForKey("lat")?.doubleValue
                        let destLng = end_location.objectForKey("lng")?.doubleValue
                        
                        let coordOrigin = CLLocationCoordinate2D(latitude: originLat!, longitude: originLng!)
                        let coordDesitination = CLLocationCoordinate2D(latitude: destLat!, longitude: destLng!)
                        
                        let markerOrigin = GMSMarker()
                        markerOrigin.groundAnchor = CGPoint(x: 0.5, y: 1)
                        markerOrigin.appearAnimation = kGMSMarkerAnimationPop
                        markerOrigin.icon = UIImage(named: "default_marker.png")
                        markerOrigin.title = directionInformation?.objectForKey("start_address") as! NSString as String
                        markerOrigin.snippet = directionInformation?.objectForKey("duration") as! NSString as String
                        markerOrigin.position = coordOrigin
                        
                        let markerDest = GMSMarker()
                        markerDest.groundAnchor = CGPoint(x: 0.5, y: 1)
                        markerDest.appearAnimation = kGMSMarkerAnimationPop
                        markerDest.icon = UIImage(named: "default_marker.png")
                        markerDest.title = directionInformation?.objectForKey("end_address") as! NSString as String
                        markerDest.snippet = directionInformation?.objectForKey("distance") as! NSString as String
                        markerDest.position = coordDesitination
                        
                        let camera = GMSCameraPosition.cameraWithLatitude(coordOrigin.latitude,longitude: coordOrigin.longitude, zoom: 10)
                        self.googleMapsView.animateToCameraPosition(camera)
                        
                        if let map = self.googleMapsView
                        {
                            map.clear()
                            if let encodedPolyLineStr = encodedPolyLine {
                                let path = GMSMutablePath(fromEncodedPath: encodedPolyLineStr)
                                let polyLine = GMSPolyline(path: path)
                                polyLine.strokeWidth = 5
                                polyLine.strokeColor = clrGreen
                                polyLine.map = self.googleMapsView
                            }
                            
                            markerOrigin.map = self.googleMapsView
                            markerDest.map = self.googleMapsView
                            
                            print(directionInformation)
                            self.tableData = directionInformation!
                        }
                    }
                    
                }
            }
        }
    }
    
    func addPolyLineWithEncodedStringInMap(json: JSON)
    {
        
        if let routes = json["routes"].array
            where routes.count > 0
        {
            let overViewPolyLine = routes[0]["overview_polyline"]["points"].string
            print(overViewPolyLine)
            if overViewPolyLine != nil{
                //self.addPolyLineWithEncodedStringInMap(overViewPolyLine!)
                let path = GMSMutablePath(fromEncodedPath: overViewPolyLine!)
                let polyLine = GMSPolyline(path: path)
                polyLine.strokeWidth = 5
                polyLine.strokeColor = clrGreen
                polyLine.map = self.googleMapsView
            }
        } else {
            self.googleMapsView.clear()
        }
        
        
    }
    
    func isValidPincode() -> Bool {
        if txtFrom.text?.characters.count == 0
        {
            self .showAlert("Please enter your source address")
            return false
        }else if txtTo.text?.characters.count == 0
        {
            self .showAlert("Please enter your destination address")
            return false
        }
        return true
    }
    func showAlert(value:NSString)
    {
        let alert = UIAlertController(title: "Please enter your source address", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let viewController: DirectionDetailVC = segue.destinationViewController as? DirectionDetailVC {
            viewController.directionInfo = self.tableData
        }
        
        
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}

