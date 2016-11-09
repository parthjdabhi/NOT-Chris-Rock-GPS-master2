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

import SOMotionDetector

class GetDirectionVC: UIViewController,UITextFieldDelegate,UISearchBarDelegate, LocateOnTheMap, GMSMapViewDelegate {
    
    // MARK: -
    // MARK: Vars
    
    var searchResultController:SearchResultsController!
    var resultsArray = [String]()
    var fromClicked = Bool()
    var mapManager = DirectionManager()
    var tableData = NSDictionary()
    var directionDetail = NSArray()
    var polyline: MKPolyline = MKPolyline()
    let markerNextTurn = GMSMarker()
    
    
    var bizForRoute: Business?
    var routeTimer:NSTimer?
    
    @IBOutlet var btnMenu: UIButton?
    //@IBOutlet weak var drawMap: MKMapView!
    @IBOutlet weak var googleMapsView : GMSMapView!
    @IBOutlet weak var txtTo: UITextField!
    @IBOutlet weak var txtFrom: UITextField!
    @IBOutlet weak var lblSpeed: UILabel!
    @IBOutlet weak var btnGetDirection: UIButton!
    @IBOutlet weak var btnStartRoute: UIButton!
    @IBOutlet weak var btnRefresh: UIButton!
    
    @IBOutlet weak var Const_P_headerviewHeight: NSLayoutConstraint!
    //@IBOutlet weak var Const_P_lblToLeading: NSLayoutConstraint!
    //@IBOutlet weak var Const_P_btnCLocTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var Const_P_SRouteLead: NSLayoutConstraint!
    @IBOutlet weak var Const_P_SRouteBottom: NSLayoutConstraint!
    
    // MARK: -
    // MARK: Orientation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            let orient = UIApplication.sharedApplication().statusBarOrientation
            
            switch orient {
            case .Portrait:
                print("Portrait")
                self.ApplyportraitConstraint()
                break
            default:
                print("LandScape")
                self.applyLandScapeConstraint()
                break
            }
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            print("rotation completed")
        })
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
    func ApplyportraitConstraint(){
        
        Const_P_headerviewHeight.constant = 64
        
        Const_P_SRouteLead.constant = 8
        Const_P_SRouteBottom.constant = 8
        
        //self.view.addConstraint(self.portrateConstraint3)
        //self.view.removeConstraint(self.landScapeConstraint)
    }
    
    func applyLandScapeConstraint(){
        
        Const_P_headerviewHeight.constant = 44
        
        Const_P_SRouteLead.constant = 0
        Const_P_SRouteBottom.constant = (-1 * (self.btnStartRoute.frame.height))
        
        //self.view.removeConstraint(self.portrateConstraint3)
        //self.view.addConstraint(self.landScapeConstraint)
        
    }
    
    // MARK: -
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchResultController = SearchResultsController()
        searchResultController.delegate = self
        
        googleMapsView.delegate = self
        
        
        btnGetDirection.enabled = false
        btnGetDirection.backgroundColor = UIColor.darkGrayColor()
        btnStartRoute.enabled = false
        btnStartRoute.backgroundColor = UIColor.darkGrayColor()
        self.btnStartRoute.tag == 1
        
        txtFrom.text = "Current Location"
        //txtFrom.text = "Santo Domingo"
        self.lblSpeed.text = ""
        
        
        let btnCLocation = UIButton(frame: CGRectMake(0, 0, 22, 22))
        btnCLocation.setBackgroundImage(UIImage(named: "ic_qu_direction_mylocation"), forState: .Normal)
//        btnCLocation.per
        btnCLocation.addTarget(self, action: #selector(GetDirectionVC.actinoSetFromCurrentLocation(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        let paddingRight = UIView(frame: CGRectMake(0, 0, 24, 22))
        paddingRight.backgroundColor = UIColor.clearColor()
        paddingRight.addSubview(btnCLocation)
        btnCLocation.center = paddingRight.center
        txtFrom.rightView = paddingRight
        txtFrom.rightViewMode = UITextFieldViewMode .Always
        
        //txtFrom.setRightMargin()
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
        
        LocationManager.sharedInstance.DidUpdateHeadingHandler = {(newHeading: CLHeading) -> Void in
            print(newHeading)
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
    
    func removeAllPlacemarkFromMap(shouldRemoveUserLocation shouldRemoveUserLocation:Bool) {
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
    
    // MARK: - GMSMapViewDelegate
    
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        print(position.target)
//        let camera = googleMapsView.camera
//        let camera1 = GMSCameraPosition(target: camera.target, zoom: camera.zoom, bearing: camera.bearing + 10, viewingAngle: camera.viewingAngle)
//        //var camera = googleMapsView.camera
//        //camera.bearing = camera.bearing + 10
//        googleMapsView.animateToCameraPosition(camera1)
        
    }
    
    func mapView(mapView: GMSMapView, willMove gesture: Bool) {
        if (gesture) {
            mapView.selectedMarker = nil
            //self.btnDirection.hidden = true
        }
    }
    
    
    // MARK: - IBAction
    
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
    
    // MARK: -
    // MARK: Custom Method
    
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
        routeTimer = NSTimer.scheduledTimerWithTimeInterval(20*60, target: self, selector: #selector(GetDirectionVC.onEveryTwentyMinutesOfRoute), userInfo: nil, repeats: true)
        
        self.directionDetail = self.tableData.objectForKey("steps") as! NSArray
        print("",self.directionDetail)
        var routePos = 0
        let dictTable:NSDictionary = self.directionDetail[0] as! NSDictionary
        print(" startObservingRoute \n\n\n startObservingRoute",dictTable)
        
        
        let instructions = (dictTable.objectForKey("html_instructions") as? NSString ?? "") as String + " (" + ((dictTable.objectForKey("duration") as? NSString ?? "") as String) + " - " + ((dictTable.objectForKey("distance") as? NSString ?? "") as String) + ")"
        self.lblSpeed.setHTMLFromString(instructions)
        
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
        
        
        
        let camera = GMSCameraPosition.cameraWithLatitude(LocationManager.sharedInstance.latitude,longitude: LocationManager.sharedInstance.longitude, zoom: 19)
        self.googleMapsView.camera = camera  //animateToCameraPosition(camera)
        
        LocationManager.sharedInstance.startUpdatingLocationWithCompletionHandler { (latitude, longitude, status, verboseMessage, error) in
        
            print("Speed : ",CLocation?.speed)
            
            if let speed = CLocation?.speed {
                //self.lblSpeed.text = "Speed \(speed)  KMPH \(speed * 3.6)"
            }
            print("\n")
            
            CLocation = CLLocation(latitude: latitude, longitude: longitude)
            print("Updating Location To Detect Turns : ",LocationManager.sharedInstance.latitude," - ",LocationManager.sharedInstance.longitude)
            
            //let FromCLocation = CLLocation(latitude: self.googleMapsView.camera.target.latitude , longitude: self.googleMapsView.camera.target.longitude)
            let camera = self.googleMapsView.camera
            let camera1 = GMSCameraPosition(target: CLocation!.coordinate, zoom: camera.zoom, bearing: getBearingBetweenTwoPoints(CLocation!, point2: nextTurnLocation), viewingAngle: camera.viewingAngle)
            //var camera = googleMapsView.camera
            //camera.bearing = camera.bearing + 10
            self.googleMapsView.animateToCameraPosition(camera1)
            
            
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
                
                //html_instructions
                let instructions = (dictTable.objectForKey("html_instructions") as? NSString ?? "") as String + " (" + ((dictTable.objectForKey("duration") as? NSString ?? "") as String) + " - " + ((dictTable.objectForKey("distance") as? NSString ?? "") as String) + ")"
                self.lblSpeed.setHTMLFromString(instructions)
                
                let camera = GMSCameraPosition.cameraWithLatitude(LocationManager.sharedInstance.latitude,longitude: LocationManager.sharedInstance.longitude, zoom: self.googleMapsView.camera.zoom)
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
//        if inst.containsIgnoringCase("StartRoute") {
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
        if inst.containsIgnoringCase("Airport") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/airports.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("airport", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Amusement Park") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/amuzement-parks.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("airport", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("ATM") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/ATM.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("ATM", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("ATMs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/ATMs.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("airport", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Bank") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/banks.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Barbershop") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/barbershops.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("barbershops", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Bars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/bars.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("bars", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Beauty") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/beauty-shops.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("beauty-shops", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Beer") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/beer.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("beer", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Bus Stops") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/bus-stops.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("bus-stops", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Car Rental") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/car-rental.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("car-rental", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Clothing Store") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/clothing-stores.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("clothing-stores", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Coffee Shops") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/coffeeshops.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("coffeeshops", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Convenience Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/conv-stores.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("conv-stores", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Department Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/department-stores.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("department-stores", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Desserts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/desserts.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("desserts", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Drugstores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/drugstores.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("drugstores", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Dry Cleaners") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/dry-cleaners.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("dry-cleaners", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Fast Food") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/fast-food.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("fast-food", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Fitness Centers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/fitness-centers.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("fitness-centers", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Gas Stations") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/gas-stations.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("gas-stations", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Grocery Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/groceries-stores.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("groceries-stores", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Home & Office Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/home-and-office-stores.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("home-and-office-stores", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Home Services") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/home-services.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("home-services", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Hospitals") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/hospitals.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("hospitals", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Hotels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/hotels.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("hotels", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Landmarks") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/landmarks.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("landmarks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Laundry") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/laundry.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("laundry", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Movies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/movies.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Museums") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/museums.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Nightclubs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/nightclubs.wav")
//            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Parking") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/parking.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Parks") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/parks.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Pet Stores") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/pet-stores.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Pharmacies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/pharmacies.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Post Offices") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/post-offices.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Restaurants") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/restaurants.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Sporting Goods") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/sporting-goods.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Tea & Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/tea-and-juice.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Transit Stations") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/transit-stations.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        if inst.containsIgnoringCase("Wine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)General-Categories/wine.wav")
            //self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("banks", withExtension: "wav")?.absoluteString)
        }
        
        // Directional Statements
        if inst.containsIgnoringCase("Turn right") || inst.containsIgnoringCase("turns left") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-right.wav")
        } else if inst.containsIgnoringCase("Turn left") || inst.containsIgnoringCase("turns right") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-left.wav")
        } else if inst.containsIgnoringCase("Turn right onto") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-right2.wav")
        } else if inst.containsIgnoringCase("Turn left onto") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/to-the-left2.wav")
        }
        
        // Highway
        if inst.containsIgnoringCase("highway") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Highway/highway.wav")
        }
        
        // Food store name
        if inst.containsIgnoringCase("5 Guys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/5-guys.wav")
        }
        else if inst.containsIgnoringCase("7/11") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/7-11.wav")
        }
        else if inst.containsIgnoringCase("A&W") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/a&w.wav")
        }
        else if inst.containsIgnoringCase("Applebees") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        else if inst.containsIgnoringCase("Arbys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/arbys.wav")
        }
        else if inst.containsIgnoringCase("Backyard Burgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/backyardburgers.wav")
        }
        else if inst.containsIgnoringCase("Bakers Dozen Donuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bakers-dozen-donuts.wav")
        }
        else if inst.containsIgnoringCase("Bar-B-Cutie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bar-b-cutie.wav")
        }
        else if inst.containsIgnoringCase("Bar Burrito") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/barburrito.wav")
        }
        else if inst.containsIgnoringCase("Baskin Robbins") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/baskin-robbins.wav")
        }
        else if inst.containsIgnoringCase("Beaver Tails") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/beavertails.wav")
        }
        else if inst.containsIgnoringCase("Ben & Florentine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-florentine.wav")
        }
        else if inst.containsIgnoringCase("Ben & Jerrys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-jerrys.wav")
        }
        else if inst.containsIgnoringCase("Benjys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/benjys.wav")
        }
        else if inst.containsIgnoringCase("Big Boy") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/big-boy.wav")
        }
        else if inst.containsIgnoringCase("BJs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bjs.wav")
        }
        else if inst.containsIgnoringCase("Blimpie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/blimpie3.wav")
        }
        else if inst.containsIgnoringCase("Bob Evans") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bob-evans.wav")
        }
        else if inst.containsIgnoringCase("Bojangles") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bojangles.wav")
        }
        else if inst.containsIgnoringCase("Bonefish Grill") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bonefish-grill.wav")
        }
        else if inst.containsIgnoringCase("Booster-Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/booster-juice.wav")
        }
        else if inst.containsIgnoringCase("Boston Market") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-market.wav")
        }
        else if inst.containsIgnoringCase("Boston Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-pizza.wav")
        }
        else if inst.containsIgnoringCase("Burger Baron") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-baron.wav")
        }
        else if inst.containsIgnoringCase("Burger King") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-king.wav")
        }
        else if inst.containsIgnoringCase("BW3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/BW3.wav")
        }
        else if inst.containsIgnoringCase("C Lovers Fish-N-Chips") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/c-lovers-fish-n-chips.wav")
        }
        else if inst.containsIgnoringCase("Captain Ds Seafood") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Capt-Ds-Seafood.wav")
        }
        else if inst.containsIgnoringCase("Captain Submarine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/captain-submarine.wav")
        }
        else if inst.containsIgnoringCase("Captains Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/capts-sub.wav")
        }
        else if inst.containsIgnoringCase("Carls Jr") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carls-jr.wav")
        }
        else if inst.containsIgnoringCase("Carrabbas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carrabbas.wav")
        }
        else if inst.containsIgnoringCase("Checkers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/checkers.wav")
        }
        else if inst.containsIgnoringCase("Cheddars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheddars.wav")
        }
        else if inst.containsIgnoringCase("Cheesecake Factory") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheesecake-factory.wav")
        }
        else if inst.containsIgnoringCase("Chez Ashton") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chez-aston.wav")
        }
        else if inst.containsIgnoringCase("Chic-Fil-A") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chic-fil-a.wav")
        }
        else if inst.containsIgnoringCase("Chicken Cottage") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-cottage.wav")
        }
        else if inst.containsIgnoringCase("Chicken Delight") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-delight.wav")
        }
        else if inst.containsIgnoringCase("Chilis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chilis.wav")
        }
        else if inst.containsIgnoringCase("Chipotle") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chipotle.wav")
        }
        else if inst.containsIgnoringCase("Chuck-E-Cheese") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chuck-e-cheese.wav")
        }
        else if inst.containsIgnoringCase("Churchs Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/churchs-chicken.wav")
        }
        else if inst.containsIgnoringCase("Cicis Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cicis-pizza.wav")
        }
        else if inst.containsIgnoringCase("Cinnabun") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cinnabun.wav")
        }
        else if inst.containsIgnoringCase("Circle K") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/circle-k.wav")
        }
        else if inst.containsIgnoringCase("Coffee Time") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/coffeetime.wav")
        }
        else if inst.containsIgnoringCase("Cora") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cora.wav")
        }
        else if inst.containsIgnoringCase("Country Style") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/countrystyle.wav")
        }
        else if inst.containsIgnoringCase("Cows Ice Cream") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cows-ice-cream.wav")
        }
        else if inst.containsIgnoringCase("CPK") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cpk.wav")
        }
        else if inst.containsIgnoringCase("Cracker Barrel") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cracker-barrel.wav")
        }
        else if inst.containsIgnoringCase("Culvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/culvers.wav")
        }
        else if inst.containsIgnoringCase("Dairy Queen") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dairy-queen.wav")
        }
        else if inst.containsIgnoringCase("Del Taco") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/del-taco")
        }
        else if inst.containsIgnoringCase("Dennys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dennys.wav")
        }
        else if inst.containsIgnoringCase("Dic Anns Hamburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dic-ann-hamburgers.wav")
        }
        else if inst.containsIgnoringCase("Dixie Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-chicken.wav")
        }
        else if inst.containsIgnoringCase("Dixie Lee Fried Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-lee-fried-chicken.wav")
        }
        else if inst.containsIgnoringCase("Dominos") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dominos.wav")
        }
        else if inst.containsIgnoringCase("Donut Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/donut-diner.wav")
        }
        else if inst.containsIgnoringCase("Dunkin Donuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dunkin-donuts.wav")
        }
        else if inst.containsIgnoringCase("East Side Marios") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/east-side-marios.wav")
        }
        else if inst.containsIgnoringCase("Eat Restaurant") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/eat-restaurant.wav")
        }
        else if inst.containsIgnoringCase("Edo Japan") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/edo-japan.wav")
        }
        else if inst.containsIgnoringCase("Eds Easy Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        else if inst.containsIgnoringCase("eds-easy-diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        else if inst.containsIgnoringCase("Einstein Brothers Bagels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/einstein-bros-bagels.wav")
        }
        else if inst.containsIgnoringCase("Extreme Pita") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/extreme-pita.wav")
        }
        else if inst.containsIgnoringCase("Famous Daves") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/famous-daves.wav")
        }
        else if inst.containsIgnoringCase("Fast Eddies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fast-eddies.wav")
        }
        else if inst.containsIgnoringCase("Firehouse Subs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/firehouse-subs.wav")
        }
        else if inst.containsIgnoringCase("Friendlys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/friendlys.wav")
        }
        else if inst.containsIgnoringCase("Fryers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fryers.wav")
        }
        else if inst.containsIgnoringCase("Gojis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/gojis.wav")
        }
        else if inst.containsIgnoringCase("Golden Corral") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/golden-corral.wav")
        }
        else if inst.containsIgnoringCase("Greco Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/greco-pizza.wav")
        }
        else if inst.containsIgnoringCase("Hardees") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hardees.wav")
        }
        else if inst.containsIgnoringCase("Harveys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/harveys.wav")
        }
        else if inst.containsIgnoringCase("Heros Cert Burgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/heros-cert-burgers.wav")
        }
        else if inst.containsIgnoringCase("Ho Lee Chow") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ho-lee-chow.wav")
        }
        else if inst.containsIgnoringCase("Hooters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hooters.wav")
        }
        else if inst.containsIgnoringCase("Humptys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/humptys.wav")
        }
        else if inst.containsIgnoringCase("IHOP") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ihop.wav")
        }
        else if inst.containsIgnoringCase("In-And-Out-Burger") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/in-and-out-burger.wav")
        }
        else if inst.containsIgnoringCase("Jack In The Box") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jack-in-the-box.wav")
        }
        else if inst.containsIgnoringCase("Jamba Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jamba-juice.wav")
        }
        else if inst.containsIgnoringCase("Jasons Deli") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jasons-deli.wav")
        }
        else if inst.containsIgnoringCase("Jimmy Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-johns.wav")
        }
        else if inst.containsIgnoringCase("Jimmy The Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-the-greek.wav")
        }
        else if inst.containsIgnoringCase("Jugo Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jugo-juice.wav")
        }
        else if inst.containsIgnoringCase("Kaspas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kaspas.wav")
        }
        else if inst.containsIgnoringCase("KFC") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kfc.wav")
        }
        else if inst.containsIgnoringCase("Krispy Kreme Doughnuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krispy-kreme-dougnuts.wav")
        }
        else if inst.containsIgnoringCase("Krystal") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krystal.wav")
        }
        else if inst.containsIgnoringCase("Labelle Prov") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/labelle-prov.wav")
        }
        else if inst.containsIgnoringCase("Licks Homeburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/licks-homeburgers.wav")
        }
        else if inst.containsIgnoringCase("Little Caesars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-caesars.wav")
        }
        else if inst.containsIgnoringCase("Little Chef") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-chef.wav")
        }
        else if inst.containsIgnoringCase("Logans Roadhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/logans-roadhouse.wav")
        }
        else if inst.containsIgnoringCase("Long John Silvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/long-john-silvers.wav")
        }
        else if inst.containsIgnoringCase("Longhorn Steakhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/longhorn-steakhouse.wav")
        }
        else if inst.containsIgnoringCase("Macaroni") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/macaroni-grill.wav")
        }
        else if inst.containsIgnoringCase("Manchu Wok") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/manchu-wok.wav")
        }
        else if inst.containsIgnoringCase("Mary Browns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mary-browns.wav")
        }
        else if inst.containsIgnoringCase("McDonalds") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mcdonalds.wav")
        }
        else if inst.containsIgnoringCase("Millies Cookies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/millies-cookies.wav")
        }
        else if inst.containsIgnoringCase("Moes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/moes.wav")
        }
        else if inst.containsIgnoringCase("Morleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/morleys.wav")
        }
        else if inst.containsIgnoringCase("Mr. Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-greek.wav")
        }
        else if inst.containsIgnoringCase("Mr. Mikes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-mikes.wav")
        }
        else if inst.containsIgnoringCase("Mr. Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-sub.wav")
        }
        else if inst.containsIgnoringCase("NY Fries") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ny-fries.wav")
        }
        else if inst.containsIgnoringCase("Ocharleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Ocharleys.wav")
        }
        else if inst.containsIgnoringCase("Olive Garden") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/olive-garden.wav")
        }
        else if inst.containsIgnoringCase("On The Border") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/on-the-border.wav")
        }
        else if inst.containsIgnoringCase("Orange Julius") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/orange-julius.wav")
        }
        else if inst.containsIgnoringCase("Outback") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/outback.wav")
        }
        else if inst.containsIgnoringCase("Panago") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panago.wav")
        }
        else if inst.containsIgnoringCase("Panda Express") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panda-express.wav")
        }
        else if inst.containsIgnoringCase("Panera Bread") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panera-bread.wav")
        }
        else if inst.containsIgnoringCase("Papa Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/papa-johns.wav")
        }
        
        
        
        // Interstate
        if inst.containsIgnoringCase("I-10") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i10.wav")
        }
        if inst.containsIgnoringCase("I-105") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i105.wav")
        }
        if inst.containsIgnoringCase("I-110") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i110.wav")
        }
        if inst.containsIgnoringCase("I-115") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i115.wav")
        }
        if inst.containsIgnoringCase("I-12") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i12.wav")
        }
        if inst.containsIgnoringCase("I-124") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i124.wav")
        }
        if inst.containsIgnoringCase("I-126") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i126.wav")
        }
        if inst.containsIgnoringCase("I-129") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i129.wav")
        }
        if inst.containsIgnoringCase("I-130") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i130.wav")
        }
        if inst.containsIgnoringCase("I-135") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i135.wav")
        }
        if inst.containsIgnoringCase("I-140") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i140.wav")
        }
        if inst.containsIgnoringCase("I-15") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i15.wav")
        }
        if inst.containsIgnoringCase("I-155") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i155.wav")
        }
        if inst.containsIgnoringCase("I-16") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i16.wav")
        }
        if inst.containsIgnoringCase("I-164") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i164.wav")
        }
        if inst.containsIgnoringCase("I-165") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i165.wav")
        }
        if inst.containsIgnoringCase("I-169") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i169.wav")
        }
        if inst.containsIgnoringCase("I-17") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i17.wav")
        }
        if inst.containsIgnoringCase("I-170") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i170.wav")
        }
        if inst.containsIgnoringCase("I-172") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i172.wav")
        }
        if inst.containsIgnoringCase("I-175") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i175.wav")
        }
        if inst.containsIgnoringCase("I-176") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i176.wav")
        }
        if inst.containsIgnoringCase("I-180") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i180.wav")
        }
        if inst.containsIgnoringCase("I-182") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i182.wav")
        }
        if inst.containsIgnoringCase("I-184") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i184.wav")
        }
        if inst.containsIgnoringCase("I-185") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i185.wav")
        }
        if inst.containsIgnoringCase("I-189") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i189.wav")
        }
        if inst.containsIgnoringCase("I-19") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i19.wav")
        }
        if inst.containsIgnoringCase("I-190") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i190.wav")
        }
        if inst.containsIgnoringCase("I-194") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i194.wav")
        }
        if inst.containsIgnoringCase("I-195") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i195.wav")
        }
        if inst.containsIgnoringCase("I-196") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i196.wav")
        }
        if inst.containsIgnoringCase("I-2") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i2.wav")
        }
        if inst.containsIgnoringCase("I-20") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i20.wav")
        }
        if inst.containsIgnoringCase("I-205") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i205.wav")
        }
        if inst.containsIgnoringCase("I-210") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i210.wav")
        }
        if inst.containsIgnoringCase("I-215") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i215.wav")
        }
        if inst.containsIgnoringCase("I-22") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i22.wav")
        }
        if inst.containsIgnoringCase("I-220") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i220.wav")
        }
        if inst.containsIgnoringCase("I-222") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i222.wav")
        }
        if inst.containsIgnoringCase("I-225") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i225.wav")
        }
        if inst.containsIgnoringCase("I-229") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i229.wav")
        }
        if inst.containsIgnoringCase("I-235") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i235.wav")
        }
        if inst.containsIgnoringCase("I-238") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i238.wav")
        }
        if inst.containsIgnoringCase("I-24") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i24.wav")
        }
        if inst.containsIgnoringCase("I-240") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i240.wav")
        }
        if inst.containsIgnoringCase("I-244") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i244.wav")
        }
        if inst.containsIgnoringCase("I-25") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i25.wav")
        }
        if inst.containsIgnoringCase("I-255") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i255.wav")
        }
        if inst.containsIgnoringCase("I-26") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i26.wav")
        }
        if inst.containsIgnoringCase("I-264") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i264.wav")
        }
        if inst.containsIgnoringCase("I-265") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i265.wav")
        }
        if inst.containsIgnoringCase("I-269") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i269.wav")
        }
        if inst.containsIgnoringCase("I-27") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i27.wav")
        }
        if inst.containsIgnoringCase("I-270") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i270.wav")
        }
        if inst.containsIgnoringCase("I-271") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i271.wav")
        }
        if inst.containsIgnoringCase("I-274") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i274.wav")
        }
        if inst.containsIgnoringCase("I-275") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i275.wav")
        }
        if inst.containsIgnoringCase("I-276") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i276.wav")
        }
        if inst.containsIgnoringCase("I-277") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i277.wav")
        }
        if inst.containsIgnoringCase("I-278") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i278.wav")
        }
        if inst.containsIgnoringCase("I-279") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i279.wav")
        }
        if inst.containsIgnoringCase("I-280") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i280.wav")
        }
        if inst.containsIgnoringCase("I-283") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i283.wav")
        }
        if inst.containsIgnoringCase("I-285") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i285.wav")
        }
        if inst.containsIgnoringCase("I-287") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i287.wav")
        }
        if inst.containsIgnoringCase("I-29") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i29.wav")
        }
        if inst.containsIgnoringCase("I-290") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i290.wav")
        }
        if inst.containsIgnoringCase("I-291") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i291.wav")
        }
        if inst.containsIgnoringCase("I-293") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i293.wav")
        }
        if inst.containsIgnoringCase("I-294") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i294.wav")
        }
        if inst.containsIgnoringCase("I-295") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i295.wav")
        }
        if inst.containsIgnoringCase("I-296") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i296.wav")
        }
        if inst.containsIgnoringCase("I-30") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Interstate/i30.wav")
        }
        
        // Food Types & Reviews
        if inst.containsIgnoringCase("African") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/african.wav")
        }
        if inst.containsIgnoringCase("American") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/american.wav")
        }
        if inst.containsIgnoringCase("Argentinian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/argentinian.wav")
        }
        if inst.containsIgnoringCase("Asian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/asian.wav")
        }
        if inst.containsIgnoringCase("Bagels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/bagels.wav")
        }
        if inst.containsIgnoringCase("Bakery") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/bakeries.wav")
        }
        if inst.containsIgnoringCase("Barbeque") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/bbq")
        }
        if inst.containsIgnoringCase("Brazilian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/brazilian.wav")
        }
        if inst.containsIgnoringCase("Breakfast") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/breakfast.wav")
        }
        if inst.containsIgnoringCase("Cajun") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/cajun.wav")
        }
        if inst.containsIgnoringCase("Caribbean") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/carribean.wav")
        }
        if inst.containsIgnoringCase("Cheesecake") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/cheesecake.wav")
        }
        if inst.containsIgnoringCase("Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/chicken.wav")
        }
        if inst.containsIgnoringCase("Chinese") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/chinese.wav")
        }
        if inst.containsIgnoringCase("Coffee") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/coffee.wav")
        }
        if inst.containsIgnoringCase("Colombian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/colombian.wav")
        }
        if inst.containsIgnoringCase("Cuban") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/african.wav")
        }
        if inst.containsIgnoringCase("Delis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/desserts.wav")
        }
        if inst.containsIgnoringCase("Diners") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/diners.wav")
        }
        if inst.containsIgnoringCase("Dominican") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/dominican.wav")
        }
        if inst.containsIgnoringCase("Ecuadorian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/ecuadorian.wav")
        }
        if inst.containsIgnoringCase("Egyptian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/egyptian.wav")
        }
        if inst.containsIgnoringCase("El-Savadoran") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/el-savadoarn.wav")
        }
        if inst.containsIgnoringCase("Ethiopian") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/ethiopian.wav")
        }
        if inst.containsIgnoringCase("Ethnic") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/ethnic.wav")
        }
        if inst.containsIgnoringCase("Expensive") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/expensive.wav")
        }
        if inst.containsIgnoringCase("Fast Food") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/fast-food.wav")
        }
        if inst.containsIgnoringCase("Filipino") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/filipino.wav")
        }
        if inst.containsIgnoringCase("Fine Dining") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/find-dining.wav")
        }
        if inst.containsIgnoringCase("Food Truck") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/food-trucks.wav")
        }
        if inst.containsIgnoringCase("French") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/french.wav")
        }
        if inst.containsIgnoringCase("Yogurt") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/frozen-yogurt.wav")
        }
        if inst.containsIgnoringCase("Gluten Free") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/gluten-free.wav")
        }
        if inst.containsIgnoringCase("Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/greek.wav")
        }
        if inst.containsIgnoringCase("Grocery Items") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/grocery-items.wav")
        }
        if inst.containsIgnoringCase("Grocery") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/grocery.wav")
        }
        if inst.containsIgnoringCase("Halal") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/halal.wav")
        }
        if inst.containsIgnoringCase("Hamburger") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)FoodFinder-Statements/hamburger.wav")
        }
        
        // Distance Statements
        if inst.containsIgnoringCase("feet") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/feet.wav")
        }
        if inst.containsIgnoringCase("foot") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/foot.wav")
        }
        if inst.containsIgnoringCase("kilometer") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/kilometer.wav")
        }
        if inst.containsIgnoringCase("kilometers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/kilometers.wav")
        }
        if inst.containsIgnoringCase("meter") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/meter.wav")
        }
        if inst.containsIgnoringCase("meters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/meters.wav")
        }
        if inst.containsIgnoringCase("mile") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/mile.wav")
        }
        if inst.containsIgnoringCase("miles") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/miles.wav")
        }
        if inst.containsIgnoringCase("milimeter") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/milimeter.wav")
        }
        if inst.containsIgnoringCase("milimeters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/milimeters.wav")
        }
        if inst.containsIgnoringCase("minute") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/minute1.wav")
        }
        if inst.containsIgnoringCase("minutes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/minutes2.wav")
        }
        if inst.containsIgnoringCase("yard") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/yard.wav")
        }
        if inst.containsIgnoringCase("yards") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Distance-Statements/yards.wav")
        }
        
        // Fractional Numbers
        if inst.containsIgnoringCase(".1") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.1.wav")
        }
        if inst.containsIgnoringCase(".2") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.2.wav")
        }
        if inst.containsIgnoringCase(".3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.3.wav")
        }
        if inst.containsIgnoringCase(".4") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.4.wav")
        }
        if inst.containsIgnoringCase(".5") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.5.wav")
        }
        if inst.containsIgnoringCase(".6") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.6.wav")
        }
        if inst.containsIgnoringCase(".7") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.7.wav")
        }
        if inst.containsIgnoringCase(".8") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.8.wav")
        }
        if inst.containsIgnoringCase(".9") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-10_fractional/0.9.wav")
        }
        
        // Number Statements
        if inst.containsIgnoringCase("1") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/1.wav")
        }
        if inst.containsIgnoringCase("2") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/2.wav")
        }
        if inst.containsIgnoringCase("3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/3.wav")
        }
        if inst.containsIgnoringCase("4") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/4.wav")
        }
        if inst.containsIgnoringCase("5") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/5.wav")
        }
        if inst.containsIgnoringCase("6") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/6.wav")
        }
        if inst.containsIgnoringCase("7") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/7.wav")
        }
        if inst.containsIgnoringCase("8") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/8.wav")
        }
        if inst.containsIgnoringCase("9") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/9.wav")
        }
        if inst.containsIgnoringCase("10") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/10.wav")
        }
        if inst.containsIgnoringCase("11") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/11.wav")
        }
        if inst.containsIgnoringCase("12") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/12.wav")
        }
        if inst.containsIgnoringCase("13") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/13.wav")
        }
        if inst.containsIgnoringCase("14") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/14.wav")
        }
        if inst.containsIgnoringCase("15") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/15.wav")
        }
        if inst.containsIgnoringCase("16") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/16.wav")
        }
        if inst.containsIgnoringCase("17") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/17.wav")
        }
        if inst.containsIgnoringCase("18") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/18.wav")
        }
        if inst.containsIgnoringCase("19") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/19.wav")
        }
        if inst.containsIgnoringCase("20") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/20.wav")
        }
        if inst.containsIgnoringCase("21") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/21.wav")
        }
        if inst.containsIgnoringCase("22") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/22.wav")
        }
        if inst.containsIgnoringCase("23") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/23.wav")
        }
        if inst.containsIgnoringCase("24") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/24.wav")
        }
        if inst.containsIgnoringCase("25") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/25.wav")
        }
        if inst.containsIgnoringCase("26") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/26.wav")
        }
        if inst.containsIgnoringCase("27") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/27.wav")
        }
        if inst.containsIgnoringCase("28") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/28.wav")
        }
        if inst.containsIgnoringCase("29") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/29.wav")
        }
        if inst.containsIgnoringCase("30") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/30.wav")
        }
        if inst.containsIgnoringCase("31") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/31.wav")
        }
        if inst.containsIgnoringCase("32") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/32.wav")
        }
        if inst.containsIgnoringCase("33") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/33.wav")
        }
        if inst.containsIgnoringCase("34") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/34.wav")
        }
        if inst.containsIgnoringCase("35") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/35.wav")
        }
        if inst.containsIgnoringCase("36") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/36.wav")
        }
        if inst.containsIgnoringCase("37") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/37.wav")
        }
        if inst.containsIgnoringCase("38") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/38.wav")
        }
        if inst.containsIgnoringCase("39") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/39.wav")
        }
        if inst.containsIgnoringCase("40") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/40.wav")
        }
        if inst.containsIgnoringCase("41") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/41.wav")
        }
        if inst.containsIgnoringCase("42") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/42.wav")
        }
        if inst.containsIgnoringCase("43") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/43.wav")
        }
        if inst.containsIgnoringCase("44") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/44.wav")
        }
        if inst.containsIgnoringCase("45") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/45.wav")
        }
        if inst.containsIgnoringCase("46") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/46.wav")
        }
        if inst.containsIgnoringCase("47") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/47.wav")
        }
        if inst.containsIgnoringCase("48") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/48.wav")
        }
        if inst.containsIgnoringCase("49") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/49.wav")
        }
        if inst.containsIgnoringCase("50") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/50.wav")
        }
        if inst.containsIgnoringCase("51") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/51.wav")
        }
        if inst.containsIgnoringCase("52") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/52.wav")
        }
        if inst.containsIgnoringCase("53") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/53.wav")
        }
        if inst.containsIgnoringCase("54") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/54.wav")
        }
        if inst.containsIgnoringCase("55") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/55.wav")
        }
        if inst.containsIgnoringCase("56") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/56.wav")
        }
        if inst.containsIgnoringCase("57") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/57.wav")
        }
        if inst.containsIgnoringCase("58") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/58.wav")
        }
        if inst.containsIgnoringCase("59") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/59.wav")
        }
        if inst.containsIgnoringCase("60") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/60.wav")
        }
        if inst.containsIgnoringCase("61") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/61.wav")
        }
        if inst.containsIgnoringCase("62") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/62.wav")
        }
        if inst.containsIgnoringCase("63") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/63.wav")
        }
        if inst.containsIgnoringCase("64") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/64.wav")
        }
        if inst.containsIgnoringCase("65") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/65.wav")
        }
        if inst.containsIgnoringCase("66") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsIgnoringCase("67") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/67.wav")
        }
        if inst.containsIgnoringCase("68") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/68.wav")
        }
        if inst.containsIgnoringCase("69") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/69.wav")
        }
        if inst.containsIgnoringCase("70") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/70.wav")
        }
        if inst.containsIgnoringCase("71") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/71.wav")
        }
        if inst.containsIgnoringCase("72") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/72.wav")
        }
        if inst.containsIgnoringCase("73") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/73.wav")
        }
        if inst.containsIgnoringCase("74") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/74.wav")
        }
        if inst.containsIgnoringCase("75") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/75.wav")
        }
        if inst.containsIgnoringCase("76") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/76.wav")
        }
        if inst.containsIgnoringCase("77") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsIgnoringCase("78") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/78.wav")
        }
        if inst.containsIgnoringCase("79") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/79.wav")
        }
        if inst.containsIgnoringCase("80") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/80.wav")
        }
        if inst.containsIgnoringCase("81") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/81.wav")
        }
        if inst.containsIgnoringCase("82") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/82.wav")
        }
        if inst.containsIgnoringCase("83") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/83.wav")
        }
        if inst.containsIgnoringCase("84") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/84.wav")
        }
        if inst.containsIgnoringCase("85") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/85.wav")
        }
        if inst.containsIgnoringCase("86") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/86.wav")
        }
        if inst.containsIgnoringCase("87") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/87.wav")
        }
        if inst.containsIgnoringCase("88") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("89") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/89.wav")
        }
        if inst.containsIgnoringCase("90") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/90.wav")
        }
        if inst.containsIgnoringCase("91") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/91.wav")
        }
        if inst.containsIgnoringCase("92") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/92.wav")
        }
        if inst.containsIgnoringCase("93") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/93.wav")
        }
        if inst.containsIgnoringCase("94") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/94.wav")
        }
        if inst.containsIgnoringCase("95") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/95.wav")
        }
        if inst.containsIgnoringCase("96") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/96.wav")
        }
        if inst.containsIgnoringCase("97") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/97.wav")
        }
        if inst.containsIgnoringCase("98") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/98.wav")
        }
        if inst.containsIgnoringCase("99") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("100") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/100.wav")
        }
        if inst.containsIgnoringCase("101") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/101.wav")
        }
        if inst.containsIgnoringCase("102") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/102.wav")
        }
        if inst.containsIgnoringCase("103") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/103.wav")
        }
        if inst.containsIgnoringCase("104") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/104.wav")
        }
        if inst.containsIgnoringCase("105") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/105.wav")
        }
        if inst.containsIgnoringCase("106") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/106.wav")
        }
        if inst.containsIgnoringCase("107") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/107.wav")
        }
        if inst.containsIgnoringCase("108") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/108.wav")
        }
        if inst.containsIgnoringCase("109") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/109.wav")
        }
        if inst.containsIgnoringCase("110") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/110.wav")
        }
        if inst.containsIgnoringCase("111") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/111.wav")
        }
        if inst.containsIgnoringCase("112") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/112.wav")
        }
        if inst.containsIgnoringCase("113") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/113.wav")
        }
        if inst.containsIgnoringCase("114") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/114.wav")
        }
        if inst.containsIgnoringCase("115") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/115.wav")
        }
        if inst.containsIgnoringCase("116") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/116.wav")
        }
        if inst.containsIgnoringCase("117") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/117.wav")
        }
        if inst.containsIgnoringCase("118") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/118.wav")
        }
        if inst.containsIgnoringCase("119") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/119.wav")
        }
        if inst.containsIgnoringCase("120") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/120.wav")
        }
        if inst.containsIgnoringCase("121") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/121.wav")
        }
        if inst.containsIgnoringCase("122") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/122.wav")
        }
        if inst.containsIgnoringCase("123") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/123.wav")
        }
        if inst.containsIgnoringCase("124") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/124.wav")
        }
        if inst.containsIgnoringCase("125") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/125.wav")
        }
        if inst.containsIgnoringCase("126") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/126.wav")
        }
        if inst.containsIgnoringCase("127") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/127.wav")
        }
        if inst.containsIgnoringCase("128") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/128.wav")
        }
        if inst.containsIgnoringCase("129") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/129.wav")
        }
        if inst.containsIgnoringCase("130") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/130.wav")
        }
        if inst.containsIgnoringCase("131") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/131.wav")
        }
        if inst.containsIgnoringCase("132") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/132.wav")
        }
        if inst.containsIgnoringCase("133") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/133.wav")
        }
        if inst.containsIgnoringCase("134") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/134.wav")
        }
        if inst.containsIgnoringCase("135") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/135.wav")
        }
        if inst.containsIgnoringCase("136") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/136.wav")
        }
        if inst.containsIgnoringCase("137") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/137.wav")
        }
        if inst.containsIgnoringCase("138") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/138.wav")
        }
        if inst.containsIgnoringCase("139") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/139.wav")
        }
        if inst.containsIgnoringCase("140") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/140.wav")
        }
        if inst.containsIgnoringCase("141") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/141.wav")
        }
        if inst.containsIgnoringCase("142") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/142.wav")
        }
        if inst.containsIgnoringCase("143") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/143.wav")
        }
        if inst.containsIgnoringCase("144") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/144.wav")
        }
        if inst.containsIgnoringCase("145") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/145.wav")
        }
        if inst.containsIgnoringCase("146") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/146.wav")
        }
        if inst.containsIgnoringCase("147") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/147.wav")
        }
        if inst.containsIgnoringCase("148") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/148.wav")
        }
        if inst.containsIgnoringCase("149") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/149.wav")
        }
        if inst.containsIgnoringCase("150") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/150.wav")
        }
        if inst.containsIgnoringCase("151") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/151.wav")
        }
        if inst.containsIgnoringCase("152") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/152.wav")
        }
        if inst.containsIgnoringCase("153") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/153.wav")
        }
        if inst.containsIgnoringCase("154") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/154.wav")
        }
        if inst.containsIgnoringCase("155") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/155.wav")
        }
        if inst.containsIgnoringCase("156") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/156.wav")
        }
        if inst.containsIgnoringCase("157") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/157.wav")
        }
        if inst.containsIgnoringCase("158") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/158.wav")
        }
        if inst.containsIgnoringCase("159") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/159.wav")
        }
        if inst.containsIgnoringCase("160") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/160.wav")
        }
        if inst.containsIgnoringCase("161") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/161.wav")
        }
        if inst.containsIgnoringCase("162") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/162.wav")
        }
        if inst.containsIgnoringCase("163") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/163.wav")
        }
        if inst.containsIgnoringCase("164") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/164.wav")
        }
        if inst.containsIgnoringCase("165") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/165.wav")
        }
        if inst.containsIgnoringCase("166") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/166.wav")
        }
        if inst.containsIgnoringCase("167") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/167.wav")
        }
        if inst.containsIgnoringCase("168") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/168.wav")
        }
        if inst.containsIgnoringCase("169") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/169.wav")
        }
        if inst.containsIgnoringCase("170") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/170.wav")
        }
        if inst.containsIgnoringCase("171") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/171.wav")
        }
        if inst.containsIgnoringCase("172") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/172.wav")
        }
        if inst.containsIgnoringCase("173") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/173.wav")
        }
        if inst.containsIgnoringCase("174") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/174.wav")
        }
        if inst.containsIgnoringCase("175") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/175.wav")
        }
        if inst.containsIgnoringCase("176") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/176.wav")
        }
        if inst.containsIgnoringCase("177") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/177.wav")
        }
        if inst.containsIgnoringCase("178") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/178.wav")
        }
        if inst.containsIgnoringCase("179") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/179.wav")
        }
        if inst.containsIgnoringCase("180") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/180.wav")
        }
        if inst.containsIgnoringCase("181") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/181.wav")
        }
        if inst.containsIgnoringCase("182") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/182.wav")
        }
        if inst.containsIgnoringCase("183") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/183.wav")
        }
        if inst.containsIgnoringCase("184") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/184.wav")
        }
        if inst.containsIgnoringCase("185") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/185.wav")
        }
        if inst.containsIgnoringCase("186") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/186.wav")
        }
        if inst.containsIgnoringCase("187") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/187.wav")
        }
        if inst.containsIgnoringCase("188") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/188.wav")
        }
        if inst.containsIgnoringCase("189") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/189.wav")
        }
        if inst.containsIgnoringCase("190") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/190.wav")
        }
        if inst.containsIgnoringCase("191") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/191.wav")
        }
        if inst.containsIgnoringCase("192") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/192.wav")
        }
        if inst.containsIgnoringCase("193") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/193.wav")
        }
        if inst.containsIgnoringCase("194") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/194.wav")
        }
        if inst.containsIgnoringCase("195") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/195.wav")
        }
        if inst.containsIgnoringCase("196") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/196.wav")
        }
        if inst.containsIgnoringCase("197") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/197.wav")
        }
        if inst.containsIgnoringCase("198") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/198.wav")
        }
        if inst.containsIgnoringCase("199") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/199.wav")
        }
        if inst.containsIgnoringCase("200") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/200.wav")
        }
        if inst.containsIgnoringCase("201") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/201.wav")
        }
        if inst.containsIgnoringCase("202") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/202.wav")
        }
        if inst.containsIgnoringCase("203") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/203.wav")
        }
        if inst.containsIgnoringCase("204") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/204.wav")
        }
        if inst.containsIgnoringCase("205") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/205.wav")
        }
        if inst.containsIgnoringCase("206") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/206.wav")
        }
        if inst.containsIgnoringCase("207") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/207.wav")
        }
        if inst.containsIgnoringCase("208") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/208.wav")
        }
        if inst.containsIgnoringCase("209") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/209.wav")
        }
        if inst.containsIgnoringCase("210") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/210.wav")
        }
        if inst.containsIgnoringCase("211") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/211.wav")
        }
        if inst.containsIgnoringCase("212") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/212.wav")
        }
        if inst.containsIgnoringCase("213") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/213.wav")
        }
        if inst.containsIgnoringCase("214") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/214.wav")
        }
        if inst.containsIgnoringCase("215") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/215.wav")
        }
        if inst.containsIgnoringCase("216") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/216.wav")
        }
        if inst.containsIgnoringCase("217") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/217.wav")
        }
        if inst.containsIgnoringCase("218") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/218.wav")
        }
        if inst.containsIgnoringCase("219") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/219.wav")
        }
        if inst.containsIgnoringCase("220") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/220.wav")
        }
        if inst.containsIgnoringCase("221") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/221.wav")
        }
        if inst.containsIgnoringCase("222") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/222.wav")
        }
        if inst.containsIgnoringCase("223") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/223.wav")
        }
        if inst.containsIgnoringCase("224") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/224.wav")
        }
        if inst.containsIgnoringCase("225") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/225.wav")
        }
        if inst.containsIgnoringCase("226") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/226.wav")
        }
        if inst.containsIgnoringCase("227") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/227.wav")
        }
        if inst.containsIgnoringCase("228") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/228.wav")
        }
        if inst.containsIgnoringCase("229") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/229.wav")
        }
        if inst.containsIgnoringCase("230") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/230.wav")
        }
        if inst.containsIgnoringCase("231") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/231.wav")
        }
        if inst.containsIgnoringCase("232") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/232.wav")
        }
        if inst.containsIgnoringCase("233") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/233.wav")
        }
        if inst.containsIgnoringCase("234") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/234.wav")
        }
        if inst.containsIgnoringCase("235") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/235.wav")
        }
        if inst.containsIgnoringCase("236") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/236.wav")
        }
        if inst.containsIgnoringCase("237") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/237.wav")
        }
        if inst.containsIgnoringCase("238") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/238.wav")
        }
        if inst.containsIgnoringCase("239") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/239.wav")
        }
        if inst.containsIgnoringCase("240") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/240.wav")
        }
        if inst.containsIgnoringCase("241") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/241.wav")
        }
        if inst.containsIgnoringCase("242") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/242.wav")
        }
        if inst.containsIgnoringCase("243") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/243.wav")
        }
        if inst.containsIgnoringCase("244") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/244.wav")
        }
        if inst.containsIgnoringCase("245") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/245.wav")
        }
        if inst.containsIgnoringCase("246") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/246.wav")
        }
        if inst.containsIgnoringCase("247") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/247.wav")
        }
        if inst.containsIgnoringCase("248") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/248.wav")
        }
        if inst.containsIgnoringCase("249") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/249.wav")
        }
        if inst.containsIgnoringCase("250") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/250.wav")
        }
        if inst.containsIgnoringCase("251") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/251.wav")
        }
        if inst.containsIgnoringCase("252") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/252.wav")
        }
        if inst.containsIgnoringCase("253") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/253.wav")
        }
        if inst.containsIgnoringCase("254") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/254.wav")
        }
        if inst.containsIgnoringCase("255") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/255.wav")
        }
        if inst.containsIgnoringCase("256") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/256.wav")
        }
        if inst.containsIgnoringCase("257") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/257.wav")
        }
        if inst.containsIgnoringCase("258") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/258.wav")
        }
        if inst.containsIgnoringCase("259") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/259.wav")
        }
        if inst.containsIgnoringCase("260") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/260.wav")
        }
        if inst.containsIgnoringCase("261") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/261.wav")
        }
        if inst.containsIgnoringCase("262") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/262.wav")
        }
        if inst.containsIgnoringCase("263") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/263.wav")
        }
        if inst.containsIgnoringCase("264") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/264.wav")
        }
        if inst.containsIgnoringCase("265") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/265.wav")
        }
        if inst.containsIgnoringCase("266") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/266.wav")
        }
        if inst.containsIgnoringCase("267") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/267.wav")
        }
        if inst.containsIgnoringCase("268") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/268.wav")
        }
        if inst.containsIgnoringCase("269") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/269.wav")
        }
        if inst.containsIgnoringCase("270") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/270.wav")
        }
        if inst.containsIgnoringCase("271") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/271.wav")
        }
        if inst.containsIgnoringCase("272") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/272.wav")
        }
        if inst.containsIgnoringCase("273") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/273.wav")
        }
        if inst.containsIgnoringCase("274") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/274.wav")
        }
        if inst.containsIgnoringCase("275") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/275.wav")
        }
        if inst.containsIgnoringCase("276") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/276.wav")
        }
        if inst.containsIgnoringCase("277") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/277.wav")
        }
        if inst.containsIgnoringCase("278") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/278.wav")
        }
        if inst.containsIgnoringCase("279") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/279.wav")
        }
        if inst.containsIgnoringCase("280") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/280.wav")
        }
        if inst.containsIgnoringCase("281") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/281.wav")
        }
        if inst.containsIgnoringCase("282") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/282.wav")
        }
        if inst.containsIgnoringCase("283") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/283.wav")
        }
        if inst.containsIgnoringCase("284") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/284.wav")
        }
        if inst.containsIgnoringCase("285") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/285.wav")
        }
        if inst.containsIgnoringCase("286") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/286.wav")
        }
        if inst.containsIgnoringCase("287") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/287.wav")
        }
        if inst.containsIgnoringCase("288") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/288.wav")
        }
        if inst.containsIgnoringCase("289") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/289.wav")
        }
        if inst.containsIgnoringCase("290") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/290.wav")
        }
        if inst.containsIgnoringCase("291") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/291.wav")
        }
        if inst.containsIgnoringCase("292") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/292.wav")
        }
        if inst.containsIgnoringCase("293") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/293.wav")
        }
        if inst.containsIgnoringCase("294") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/294.wav")
        }
        if inst.containsIgnoringCase("295") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/295.wav")
        }
        if inst.containsIgnoringCase("296") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/296.wav")
        }
        if inst.containsIgnoringCase("297") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/297.wav")
        }
        if inst.containsIgnoringCase("298") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/298.wav")
        }
        if inst.containsIgnoringCase("299") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/299.wav")
        }
        if inst.containsIgnoringCase("300") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/300.wav")
        }
        if inst.containsIgnoringCase("301") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/301.wav")
        }
        if inst.containsIgnoringCase("302") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/302.wav")
        }
        if inst.containsIgnoringCase("303") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/303.wav")
        }
        if inst.containsIgnoringCase("304") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/304.wav")
        }
        if inst.containsIgnoringCase("305") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/305.wav")
        }
        if inst.containsIgnoringCase("306") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/306.wav")
        }
        if inst.containsIgnoringCase("307") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/307.wav")
        }
        if inst.containsIgnoringCase("308") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/308.wav")
        }
        if inst.containsIgnoringCase("309") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/309.wav")
        }
        if inst.containsIgnoringCase("310") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/310.wav")
        }
        if inst.containsIgnoringCase("311") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/311.wav")
        }
        if inst.containsIgnoringCase("312") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/312.wav")
        }
        if inst.containsIgnoringCase("313") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/313.wav")
        }
        if inst.containsIgnoringCase("314") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/314.wav")
        }
        if inst.containsIgnoringCase("315") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/315.wav")
        }
        if inst.containsIgnoringCase("316") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/316.wav")
        }
        if inst.containsIgnoringCase("317") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/317.wav")
        }
        if inst.containsIgnoringCase("318") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/318.wav")
        }
        if inst.containsIgnoringCase("319") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/319.wav")
        }
        if inst.containsIgnoringCase("320") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/320.wav")
        }
        if inst.containsIgnoringCase("321") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/321.wav")
        }
        if inst.containsIgnoringCase("322") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/322.wav")
        }
        if inst.containsIgnoringCase("323") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/323.wav")
        }
        if inst.containsIgnoringCase("324") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/324.wav")
        }
        if inst.containsIgnoringCase("325") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/325.wav")
        }
        if inst.containsIgnoringCase("326") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/326.wav")
        }
        if inst.containsIgnoringCase("327") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/327.wav")
        }
        if inst.containsIgnoringCase("328") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/328.wav")
        }
        if inst.containsIgnoringCase("329") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/329.wav")
        }
        if inst.containsIgnoringCase("330") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/330.wav")
        }
        if inst.containsIgnoringCase("331") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/331.wav")
        }
        if inst.containsIgnoringCase("332") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/332.wav")
        }
        if inst.containsIgnoringCase("333") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/333.wav")
        }
        if inst.containsIgnoringCase("334") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/334.wav")
        }
        if inst.containsIgnoringCase("335") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/335.wav")
        }
        if inst.containsIgnoringCase("336") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/336.wav")
        }
        if inst.containsIgnoringCase("337") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/337.wav")
        }
        if inst.containsIgnoringCase("338") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/338.wav")
        }
        if inst.containsIgnoringCase("339") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/339.wav")
        }
        if inst.containsIgnoringCase("340") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/340.wav")
        }
        if inst.containsIgnoringCase("341") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/341.wav")
        }
        if inst.containsIgnoringCase("342") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/342.wav")
        }
        if inst.containsIgnoringCase("343") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/343.wav")
        }
        if inst.containsIgnoringCase("344") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/344.wav")
        }
        if inst.containsIgnoringCase("345") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/345.wav")
        }
        if inst.containsIgnoringCase("346") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/346.wav")
        }
        if inst.containsIgnoringCase("347") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/347.wav")
        }
        if inst.containsIgnoringCase("348") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/348.wav")
        }
        if inst.containsIgnoringCase("349") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/349.wav")
        }
        if inst.containsIgnoringCase("350") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/350.wav")
        }
        if inst.containsIgnoringCase("351") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/351.wav")
        }
        if inst.containsIgnoringCase("352") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/352.wav")
        }
        if inst.containsIgnoringCase("353") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/353.wav")
        }
        if inst.containsIgnoringCase("354") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/354.wav")
        }
        if inst.containsIgnoringCase("355") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/355.wav")
        }
        if inst.containsIgnoringCase("356") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/356.wav")
        }
        if inst.containsIgnoringCase("357") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/357.wav")
        }
        if inst.containsIgnoringCase("358") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/358.wav")
        }
        if inst.containsIgnoringCase("359") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/359.wav")
        }
        if inst.containsIgnoringCase("360") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/360.wav")
        }
        if inst.containsIgnoringCase("361") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/361.wav")
        }
        if inst.containsIgnoringCase("362") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/362.wav")
        }
        if inst.containsIgnoringCase("363") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/363.wav")
        }
        if inst.containsIgnoringCase("364") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/364.wav")
        }
        if inst.containsIgnoringCase("365") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/365.wav")
        }
        if inst.containsIgnoringCase("366") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/366.wav")
        }
        if inst.containsIgnoringCase("367") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/367.wav")
        }
        if inst.containsIgnoringCase("368") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/368.wav")
        }
        if inst.containsIgnoringCase("369") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/369.wav")
        }
        if inst.containsIgnoringCase("370") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/370.wav")
        }
        if inst.containsIgnoringCase("371") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/371.wav")
        }
        if inst.containsIgnoringCase("372") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/372.wav")
        }
        if inst.containsIgnoringCase("373") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/373.wav")
        }
        if inst.containsIgnoringCase("374") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/374.wav")
        }
        if inst.containsIgnoringCase("375") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/375.wav")
        }
        if inst.containsIgnoringCase("376") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/376.wav")
        }
        if inst.containsIgnoringCase("377") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/377.wav")
        }
        if inst.containsIgnoringCase("378") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/378.wav")
        }
        if inst.containsIgnoringCase("379") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/379.wav")
        }
        if inst.containsIgnoringCase("380") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/380.wav")
        }
        if inst.containsIgnoringCase("381") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/381.wav")
        }
        if inst.containsIgnoringCase("382") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/382.wav")
        }
        if inst.containsIgnoringCase("383") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/383.wav")
        }
        if inst.containsIgnoringCase("384") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/384.wav")
        }
        if inst.containsIgnoringCase("385") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/385.wav")
        }
        if inst.containsIgnoringCase("386") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/386.wav")
        }
        if inst.containsIgnoringCase("387") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/387.wav")
        }
        if inst.containsIgnoringCase("388") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/388.wav")
        }
        if inst.containsIgnoringCase("389") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/389.wav")
        }
        if inst.containsIgnoringCase("390") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/390.wav")
        }
        if inst.containsIgnoringCase("391") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/391.wav")
        }
        if inst.containsIgnoringCase("392") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/392.wav")
        }
        if inst.containsIgnoringCase("393") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/393.wav")
        }
        if inst.containsIgnoringCase("394") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/394.wav")
        }
        if inst.containsIgnoringCase("395") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/395.wav")
        }
        if inst.containsIgnoringCase("396") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/396.wav")
        }
        if inst.containsIgnoringCase("397") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/397.wav")
        }
        if inst.containsIgnoringCase("398") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/398.wav")
        }
        if inst.containsIgnoringCase("399") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/399.wav")
        }
        if inst.containsIgnoringCase("400") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/400.wav")
        }
        if inst.containsIgnoringCase("401") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/401.wav")
        }
        if inst.containsIgnoringCase("402") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/402.wav")
        }
        if inst.containsIgnoringCase("403") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/403.wav")
        }
        if inst.containsIgnoringCase("404") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/404.wav")
        }
        if inst.containsIgnoringCase("405") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/405.wav")
        }
        if inst.containsIgnoringCase("406") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/406.wav")
        }
        if inst.containsIgnoringCase("407") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/407.wav")
        }
        if inst.containsIgnoringCase("408") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/408.wav")
        }
        if inst.containsIgnoringCase("409") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/409.wav")
        }
        if inst.containsIgnoringCase("410") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/410.wav")
        }
        if inst.containsIgnoringCase("411") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/411.wav")
        }
        if inst.containsIgnoringCase("412") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/412.wav")
        }
        if inst.containsIgnoringCase("413") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/413.wav")
        }
        if inst.containsIgnoringCase("414") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/414.wav")
        }
        if inst.containsIgnoringCase("415") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/415.wav")
        }
        if inst.containsIgnoringCase("416") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/416.wav")
        }
        if inst.containsIgnoringCase("417") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/417.wav")
        }
        if inst.containsIgnoringCase("418") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/418.wav")
        }
        if inst.containsIgnoringCase("419") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/419.wav")
        }
        if inst.containsIgnoringCase("42") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/42.wav")
        }
        if inst.containsIgnoringCase("421") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/421.wav")
        }
        if inst.containsIgnoringCase("422") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/422.wav")
        }
        if inst.containsIgnoringCase("423") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/423.wav")
        }
        if inst.containsIgnoringCase("424") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/424.wav")
        }
        if inst.containsIgnoringCase("425") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/425.wav")
        }
        if inst.containsIgnoringCase("426") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/426.wav")
        }
        if inst.containsIgnoringCase("427") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/427.wav")
        }
        if inst.containsIgnoringCase("428") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/428.wav")
        }
        if inst.containsIgnoringCase("429") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/429.wav")
        }
        if inst.containsIgnoringCase("430") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/430.wav")
        }
        if inst.containsIgnoringCase("43") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/43.wav")
        }
        if inst.containsIgnoringCase("431") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/431.wav")
        }
        if inst.containsIgnoringCase("432") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/432.wav")
        }
        if inst.containsIgnoringCase("433") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/433.wav")
        }
        if inst.containsIgnoringCase("434") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/434.wav")
        }
        if inst.containsIgnoringCase("435") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/435.wav")
        }
        if inst.containsIgnoringCase("436") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/436.wav")
        }
        if inst.containsIgnoringCase("437") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/437.wav")
        }
        if inst.containsIgnoringCase("438") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/438.wav")
        }
        if inst.containsIgnoringCase("439") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/439.wav")
        }
        if inst.containsIgnoringCase("44") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/44.wav")
        }
        if inst.containsIgnoringCase("440") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/440.wav")
        }
        if inst.containsIgnoringCase("441") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/441.wav")
        }
        if inst.containsIgnoringCase("442") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/442.wav")
        }
        if inst.containsIgnoringCase("443") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/443.wav")
        }
        if inst.containsIgnoringCase("444") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/444.wav")
        }
        if inst.containsIgnoringCase("445") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/445.wav")
        }
        if inst.containsIgnoringCase("446") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/446.wav")
        }
        if inst.containsIgnoringCase("447") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/447.wav")
        }
        if inst.containsIgnoringCase("448") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/448.wav")
        }
        if inst.containsIgnoringCase("449") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/449.wav")
        }
        if inst.containsIgnoringCase("450") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/450.wav")
        }
        if inst.containsIgnoringCase("45") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/45.wav")
        }
        if inst.containsIgnoringCase("451") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/451.wav")
        }
        if inst.containsIgnoringCase("452") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/452.wav")
        }
        if inst.containsIgnoringCase("453") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/433.wav")
        }
        if inst.containsIgnoringCase("454") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/454.wav")
        }
        if inst.containsIgnoringCase("455") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/455.wav")
        }
        if inst.containsIgnoringCase("456") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/456.wav")
        }
        if inst.containsIgnoringCase("457") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/457.wav")
        }
        if inst.containsIgnoringCase("458") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/458.wav")
        }
        if inst.containsIgnoringCase("459") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/459.wav")
        }
        if inst.containsIgnoringCase("46") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/46.wav")
        }
        if inst.containsIgnoringCase("461") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/461.wav")
        }
        if inst.containsIgnoringCase("462") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/462.wav")
        }
        if inst.containsIgnoringCase("463") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/463.wav")
        }
        if inst.containsIgnoringCase("464") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/464.wav")
        }
        if inst.containsIgnoringCase("465") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/465.wav")
        }
        if inst.containsIgnoringCase("466") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/466.wav")
        }
        if inst.containsIgnoringCase("467") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/467.wav")
        }
        if inst.containsIgnoringCase("468") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/468.wav")
        }
        if inst.containsIgnoringCase("469") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/469.wav")
        }
        if inst.containsIgnoringCase("47") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/47.wav")
        }
        if inst.containsIgnoringCase("471") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/471.wav")
        }
        if inst.containsIgnoringCase("472") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/472.wav")
        }
        if inst.containsIgnoringCase("473") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/473.wav")
        }
        if inst.containsIgnoringCase("474") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/474.wav")
        }
        if inst.containsIgnoringCase("475") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/475.wav")
        }
        if inst.containsIgnoringCase("476") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/476.wav")
        }
        if inst.containsIgnoringCase("477") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/477.wav")
        }
        if inst.containsIgnoringCase("478") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/478.wav")
        }
        if inst.containsIgnoringCase("479") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/479.wav")
        }
        if inst.containsIgnoringCase("48") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/48.wav")
        }
        if inst.containsIgnoringCase("481") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/481.wav")
        }
        if inst.containsIgnoringCase("482") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/482.wav")
        }
        if inst.containsIgnoringCase("483") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/483.wav")
        }
        if inst.containsIgnoringCase("484") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/484.wav")
        }
        if inst.containsIgnoringCase("485") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/485.wav")
        }
        if inst.containsIgnoringCase("486") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/486.wav")
        }
        if inst.containsIgnoringCase("487") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/487.wav")
        }
        if inst.containsIgnoringCase("488") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/488.wav")
        }
        if inst.containsIgnoringCase("489") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/489.wav")
        }
        if inst.containsIgnoringCase("490") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/490.wav")
        }
        if inst.containsIgnoringCase("49") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/49.wav")
        }
        if inst.containsIgnoringCase("491") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/491.wav")
        }
        if inst.containsIgnoringCase("492") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/492.wav")
        }
        if inst.containsIgnoringCase("493") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/493.wav")
        }
        if inst.containsIgnoringCase("494") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/494.wav")
        }
        if inst.containsIgnoringCase("495") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/495.wav")
        }
        if inst.containsIgnoringCase("496") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/496.wav")
        }
        if inst.containsIgnoringCase("497") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/497.wav")
        }
        if inst.containsIgnoringCase("498") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/498.wav")
        }
        if inst.containsIgnoringCase("499") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/499.wav")
        }
        if inst.containsIgnoringCase("50") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/50.wav")
        }
        if inst.containsIgnoringCase("500") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/500.wav")
        }
        if inst.containsIgnoringCase("501") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/501.wav")
        }
        if inst.containsIgnoringCase("502") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/502.wav")
        }
        if inst.containsIgnoringCase("503") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/503.wav")
        }
        if inst.containsIgnoringCase("504") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/504.wav")
        }
        if inst.containsIgnoringCase("505") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/505.wav")
        }
        if inst.containsIgnoringCase("506") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/506.wav")
        }
        if inst.containsIgnoringCase("507") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/507.wav")
        }
        if inst.containsIgnoringCase("508") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/508.wav")
        }
        if inst.containsIgnoringCase("509") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/509.wav")
        }
        if inst.containsIgnoringCase("510") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/510.wav")
        }
        if inst.containsIgnoringCase("511") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/511.wav")
        }
        if inst.containsIgnoringCase("512") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/512.wav")
        }
        if inst.containsIgnoringCase("513") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/513.wav")
        }
        if inst.containsIgnoringCase("514") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/514.wav")
        }
        if inst.containsIgnoringCase("515") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/515.wav")
        }
        if inst.containsIgnoringCase("516") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/516.wav")
        }
        if inst.containsIgnoringCase("517") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/517.wav")
        }
        if inst.containsIgnoringCase("518") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/518.wav")
        }
        if inst.containsIgnoringCase("519") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/519.wav")
        }
        if inst.containsIgnoringCase("52") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/52.wav")
        }
        if inst.containsIgnoringCase("521") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/521.wav")
        }
        if inst.containsIgnoringCase("522") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/522.wav")
        }
        if inst.containsIgnoringCase("523") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/523.wav")
        }
        if inst.containsIgnoringCase("524") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/524.wav")
        }
        if inst.containsIgnoringCase("525") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/525.wav")
        }
        if inst.containsIgnoringCase("526") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/526.wav")
        }
        if inst.containsIgnoringCase("527") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/527.wav")
        }
        if inst.containsIgnoringCase("528") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/528.wav")
        }
        if inst.containsIgnoringCase("529") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/529.wav")
        }
        if inst.containsIgnoringCase("530") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/530.wav")
        }
        if inst.containsIgnoringCase("53") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/53.wav")
        }
        if inst.containsIgnoringCase("531") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/531.wav")
        }
        if inst.containsIgnoringCase("532") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/532.wav")
        }
        if inst.containsIgnoringCase("533") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/533.wav")
        }
        if inst.containsIgnoringCase("534") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/534.wav")
        }
        if inst.containsIgnoringCase("535") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/535.wav")
        }
        if inst.containsIgnoringCase("536") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/536.wav")
        }
        if inst.containsIgnoringCase("537") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/537.wav")
        }
        if inst.containsIgnoringCase("538") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/538.wav")
        }
        if inst.containsIgnoringCase("539") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/539.wav")
        }
        if inst.containsIgnoringCase("54") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/54.wav")
        }
        if inst.containsIgnoringCase("540") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/540.wav")
        }
        if inst.containsIgnoringCase("541") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/541.wav")
        }
        if inst.containsIgnoringCase("542") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/542.wav")
        }
        if inst.containsIgnoringCase("543") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/543.wav")
        }
        if inst.containsIgnoringCase("544") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/544.wav")
        }
        if inst.containsIgnoringCase("545") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/545.wav")
        }
        if inst.containsIgnoringCase("546") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/546.wav")
        }
        if inst.containsIgnoringCase("547") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/547.wav")
        }
        if inst.containsIgnoringCase("548") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/548.wav")
        }
        if inst.containsIgnoringCase("549") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/549.wav")
        }
        if inst.containsIgnoringCase("550") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/550.wav")
        }
        if inst.containsIgnoringCase("55") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/55.wav")
        }
        if inst.containsIgnoringCase("551") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/551.wav")
        }
        if inst.containsIgnoringCase("552") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/552.wav")
        }
        if inst.containsIgnoringCase("553") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/533.wav")
        }
        if inst.containsIgnoringCase("554") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/554.wav")
        }
        if inst.containsIgnoringCase("555") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/555.wav")
        }
        if inst.containsIgnoringCase("556") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/556.wav")
        }
        if inst.containsIgnoringCase("557") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/557.wav")
        }
        if inst.containsIgnoringCase("558") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/558.wav")
        }
        if inst.containsIgnoringCase("559") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/559.wav")
        }
        if inst.containsIgnoringCase("56") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/56.wav")
        }
        if inst.containsIgnoringCase("560") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsIgnoringCase("561") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/561.wav")
        }
        if inst.containsIgnoringCase("562") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/562.wav")
        }
        if inst.containsIgnoringCase("563") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/563.wav")
        }
        if inst.containsIgnoringCase("564") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/564.wav")
        }
        if inst.containsIgnoringCase("565") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/565.wav")
        }
        if inst.containsIgnoringCase("566") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/566.wav")
        }
        if inst.containsIgnoringCase("567") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/567.wav")
        }
        if inst.containsIgnoringCase("568") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/568.wav")
        }
        if inst.containsIgnoringCase("569") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/569.wav")
        }
        if inst.containsIgnoringCase("57") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/57.wav")
        }
        if inst.containsIgnoringCase("571") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/571.wav")
        }
        if inst.containsIgnoringCase("572") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/572.wav")
        }
        if inst.containsIgnoringCase("573") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/573.wav")
        }
        if inst.containsIgnoringCase("574") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/574.wav")
        }
        if inst.containsIgnoringCase("575") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/575.wav")
        }
        if inst.containsIgnoringCase("576") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/576.wav")
        }
        if inst.containsIgnoringCase("577") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/577.wav")
        }
        if inst.containsIgnoringCase("578") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/578.wav")
        }
        if inst.containsIgnoringCase("579") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/579.wav")
        }
        if inst.containsIgnoringCase("58") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/58.wav")
        }
        if inst.containsIgnoringCase("581") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/581.wav")
        }
        if inst.containsIgnoringCase("582") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/582.wav")
        }
        if inst.containsIgnoringCase("583") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/583.wav")
        }
        if inst.containsIgnoringCase("584") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/584.wav")
        }
        if inst.containsIgnoringCase("585") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/585.wav")
        }
        if inst.containsIgnoringCase("586") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/586.wav")
        }
        if inst.containsIgnoringCase("587") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/587.wav")
        }
        if inst.containsIgnoringCase("588") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/588.wav")
        }
        if inst.containsIgnoringCase("589") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/589.wav")
        }
        if inst.containsIgnoringCase("590") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/590.wav")
        }
        if inst.containsIgnoringCase("59") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/59.wav")
        }
        if inst.containsIgnoringCase("591") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/591.wav")
        }
        if inst.containsIgnoringCase("592") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/592.wav")
        }
        if inst.containsIgnoringCase("593") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/593.wav")
        }
        if inst.containsIgnoringCase("594") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/594.wav")
        }
        if inst.containsIgnoringCase("595") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/595.wav")
        }
        if inst.containsIgnoringCase("596") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/596.wav")
        }
        if inst.containsIgnoringCase("597") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/597.wav")
        }
        if inst.containsIgnoringCase("598") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/598.wav")
        }
        if inst.containsIgnoringCase("599") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/599.wav")
        }
        if inst.containsIgnoringCase("60") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/60.wav")
        }
        if inst.containsIgnoringCase("600") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/600.wav")
        }
        if inst.containsIgnoringCase("601") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/601.wav")
        }
        if inst.containsIgnoringCase("602") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/602.wav")
        }
        if inst.containsIgnoringCase("603") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/603.wav")
        }
        if inst.containsIgnoringCase("604") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/604.wav")
        }
        if inst.containsIgnoringCase("605") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/606.wav")
        }
        if inst.containsIgnoringCase("606") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/606.wav")
        }
        if inst.containsIgnoringCase("607") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/607.wav")
        }
        if inst.containsIgnoringCase("608") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/608.wav")
        }
        if inst.containsIgnoringCase("609") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/609.wav")
        }
        if inst.containsIgnoringCase("610") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/610.wav")
        }
        if inst.containsIgnoringCase("611") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/611.wav")
        }
        if inst.containsIgnoringCase("612") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/612.wav")
        }
        if inst.containsIgnoringCase("613") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/613.wav")
        }
        if inst.containsIgnoringCase("614") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/614.wav")
        }
        if inst.containsIgnoringCase("615") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/616.wav")
        }
        if inst.containsIgnoringCase("616") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/616.wav")
        }
        if inst.containsIgnoringCase("617") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/617.wav")
        }
        if inst.containsIgnoringCase("618") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/618.wav")
        }
        if inst.containsIgnoringCase("619") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/619.wav")
        }
        if inst.containsIgnoringCase("62") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/62.wav")
        }
        if inst.containsIgnoringCase("621") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/621.wav")
        }
        if inst.containsIgnoringCase("622") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/622.wav")
        }
        if inst.containsIgnoringCase("623") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/623.wav")
        }
        if inst.containsIgnoringCase("624") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/624.wav")
        }
        if inst.containsIgnoringCase("625") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/626.wav")
        }
        if inst.containsIgnoringCase("626") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/626.wav")
        }
        if inst.containsIgnoringCase("627") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/627.wav")
        }
        if inst.containsIgnoringCase("628") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/628.wav")
        }
        if inst.containsIgnoringCase("629") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/629.wav")
        }
        if inst.containsIgnoringCase("630") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/630.wav")
        }
        if inst.containsIgnoringCase("63") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/63.wav")
        }
        if inst.containsIgnoringCase("631") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/631.wav")
        }
        if inst.containsIgnoringCase("632") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/632.wav")
        }
        if inst.containsIgnoringCase("633") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/633.wav")
        }
        if inst.containsIgnoringCase("634") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/634.wav")
        }
        if inst.containsIgnoringCase("635") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/636.wav")
        }
        if inst.containsIgnoringCase("636") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/636.wav")
        }
        if inst.containsIgnoringCase("637") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/637.wav")
        }
        if inst.containsIgnoringCase("638") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/638.wav")
        }
        if inst.containsIgnoringCase("639") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/639.wav")
        }
        if inst.containsIgnoringCase("64") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/64.wav")
        }
        if inst.containsIgnoringCase("640") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/640.wav")
        }
        if inst.containsIgnoringCase("641") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/641.wav")
        }
        if inst.containsIgnoringCase("642") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/642.wav")
        }
        if inst.containsIgnoringCase("643") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/643.wav")
        }
        if inst.containsIgnoringCase("644") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/644.wav")
        }
        if inst.containsIgnoringCase("645") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/646.wav")
        }
        if inst.containsIgnoringCase("646") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/646.wav")
        }
        if inst.containsIgnoringCase("647") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/647.wav")
        }
        if inst.containsIgnoringCase("648") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/648.wav")
        }
        if inst.containsIgnoringCase("649") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/649.wav")
        }
        if inst.containsIgnoringCase("650") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/660.wav")
        }
        if inst.containsIgnoringCase("65") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsIgnoringCase("651") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/661.wav")
        }
        if inst.containsIgnoringCase("652") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/662.wav")
        }
        if inst.containsIgnoringCase("653") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/633.wav")
        }
        if inst.containsIgnoringCase("654") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/664.wav")
        }
        if inst.containsIgnoringCase("655") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsIgnoringCase("656") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsIgnoringCase("657") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/667.wav")
        }
        if inst.containsIgnoringCase("658") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/668.wav")
        }
        if inst.containsIgnoringCase("659") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/669.wav")
        }
        if inst.containsIgnoringCase("66") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsIgnoringCase("660") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/66.wav")
        }
        if inst.containsIgnoringCase("661") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/661.wav")
        }
        if inst.containsIgnoringCase("662") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/662.wav")
        }
        if inst.containsIgnoringCase("663") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/663.wav")
        }
        if inst.containsIgnoringCase("664") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/664.wav")
        }
        if inst.containsIgnoringCase("665") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsIgnoringCase("666") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/666.wav")
        }
        if inst.containsIgnoringCase("667") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/667.wav")
        }
        if inst.containsIgnoringCase("668") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/668.wav")
        }
        if inst.containsIgnoringCase("669") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/669.wav")
        }
        if inst.containsIgnoringCase("67") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/67.wav")
        }
        if inst.containsIgnoringCase("671") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/671.wav")
        }
        if inst.containsIgnoringCase("672") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/672.wav")
        }
        if inst.containsIgnoringCase("673") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/673.wav")
        }
        if inst.containsIgnoringCase("674") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/674.wav")
        }
        if inst.containsIgnoringCase("675") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/676.wav")
        }
        if inst.containsIgnoringCase("676") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/676.wav")
        }
        if inst.containsIgnoringCase("677") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/677.wav")
        }
        if inst.containsIgnoringCase("678") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/678.wav")
        }
        if inst.containsIgnoringCase("679") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/679.wav")
        }
        if inst.containsIgnoringCase("68") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/68.wav")
        }
        if inst.containsIgnoringCase("681") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/681.wav")
        }
        if inst.containsIgnoringCase("682") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/682.wav")
        }
        if inst.containsIgnoringCase("683") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/683.wav")
        }
        if inst.containsIgnoringCase("684") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/684.wav")
        }
        if inst.containsIgnoringCase("685") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/686.wav")
        }
        if inst.containsIgnoringCase("686") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/686.wav")
        }
        if inst.containsIgnoringCase("687") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/687.wav")
        }
        if inst.containsIgnoringCase("688") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/688.wav")
        }
        if inst.containsIgnoringCase("689") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/689.wav")
        }
        if inst.containsIgnoringCase("690") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/690.wav")
        }
        if inst.containsIgnoringCase("69") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/69.wav")
        }
        if inst.containsIgnoringCase("691") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/691.wav")
        }
        if inst.containsIgnoringCase("692") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/692.wav")
        }
        if inst.containsIgnoringCase("693") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/693.wav")
        }
        if inst.containsIgnoringCase("694") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/694.wav")
        }
        if inst.containsIgnoringCase("695") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/696.wav")
        }
        if inst.containsIgnoringCase("696") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/696.wav")
        }
        if inst.containsIgnoringCase("697") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/697.wav")
        }
        if inst.containsIgnoringCase("698") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/698.wav")
        }
        if inst.containsIgnoringCase("699") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/699.wav")
        }
        if inst.containsIgnoringCase("70") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/70.wav")
        }
        if inst.containsIgnoringCase("700") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/700.wav")
        }
        if inst.containsIgnoringCase("701") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/701.wav")
        }
        if inst.containsIgnoringCase("702") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/702.wav")
        }
        if inst.containsIgnoringCase("703") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/703.wav")
        }
        if inst.containsIgnoringCase("704") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/704.wav")
        }
        if inst.containsIgnoringCase("705") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/707.wav")
        }
        if inst.containsIgnoringCase("706") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/707.wav")
        }
        if inst.containsIgnoringCase("707") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/707.wav")
        }
        if inst.containsIgnoringCase("708") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/708.wav")
        }
        if inst.containsIgnoringCase("709") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/709.wav")
        }
        if inst.containsIgnoringCase("710") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/710.wav")
        }
        if inst.containsIgnoringCase("711") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/711.wav")
        }
        if inst.containsIgnoringCase("712") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/712.wav")
        }
        if inst.containsIgnoringCase("713") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/713.wav")
        }
        if inst.containsIgnoringCase("714") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/714.wav")
        }
        if inst.containsIgnoringCase("715") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/717.wav")
        }
        if inst.containsIgnoringCase("716") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/717.wav")
        }
        if inst.containsIgnoringCase("717") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/717.wav")
        }
        if inst.containsIgnoringCase("718") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/718.wav")
        }
        if inst.containsIgnoringCase("719") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/719.wav")
        }
        if inst.containsIgnoringCase("72") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/72.wav")
        }
        if inst.containsIgnoringCase("721") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/721.wav")
        }
        if inst.containsIgnoringCase("722") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/722.wav")
        }
        if inst.containsIgnoringCase("723") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/723.wav")
        }
        if inst.containsIgnoringCase("724") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/724.wav")
        }
        if inst.containsIgnoringCase("725") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/727.wav")
        }
        if inst.containsIgnoringCase("726") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/727.wav")
        }
        if inst.containsIgnoringCase("727") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/727.wav")
        }
        if inst.containsIgnoringCase("728") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/728.wav")
        }
        if inst.containsIgnoringCase("729") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/729.wav")
        }
        if inst.containsIgnoringCase("730") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/730.wav")
        }
        if inst.containsIgnoringCase("73") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/73.wav")
        }
        if inst.containsIgnoringCase("731") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/731.wav")
        }
        if inst.containsIgnoringCase("732") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/732.wav")
        }
        if inst.containsIgnoringCase("733") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/733.wav")
        }
        if inst.containsIgnoringCase("734") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/734.wav")
        }
        if inst.containsIgnoringCase("735") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/737.wav")
        }
        if inst.containsIgnoringCase("736") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/737.wav")
        }
        if inst.containsIgnoringCase("737") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/737.wav")
        }
        if inst.containsIgnoringCase("738") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/738.wav")
        }
        if inst.containsIgnoringCase("739") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/739.wav")
        }
        if inst.containsIgnoringCase("74") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/74.wav")
        }
        if inst.containsIgnoringCase("740") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/740.wav")
        }
        if inst.containsIgnoringCase("741") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/741.wav")
        }
        if inst.containsIgnoringCase("742") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/742.wav")
        }
        if inst.containsIgnoringCase("743") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/743.wav")
        }
        if inst.containsIgnoringCase("744") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/744.wav")
        }
        if inst.containsIgnoringCase("745") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/747.wav")
        }
        if inst.containsIgnoringCase("746") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/747.wav")
        }
        if inst.containsIgnoringCase("747") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/747.wav")
        }
        if inst.containsIgnoringCase("748") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/748.wav")
        }
        if inst.containsIgnoringCase("749") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/749.wav")
        }
        if inst.containsIgnoringCase("750") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/770.wav")
        }
        if inst.containsIgnoringCase("75") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsIgnoringCase("751") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/771.wav")
        }
        if inst.containsIgnoringCase("752") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/772.wav")
        }
        if inst.containsIgnoringCase("753") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/733.wav")
        }
        if inst.containsIgnoringCase("754") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/774.wav")
        }
        if inst.containsIgnoringCase("755") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("756") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("757") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("758") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/778.wav")
        }
        if inst.containsIgnoringCase("759") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/779.wav")
        }
        if inst.containsIgnoringCase("76") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsIgnoringCase("760") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsIgnoringCase("761") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/771.wav")
        }
        if inst.containsIgnoringCase("762") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/772.wav")
        }
        if inst.containsIgnoringCase("763") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/773.wav")
        }
        if inst.containsIgnoringCase("764") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/774.wav")
        }
        if inst.containsIgnoringCase("765") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("766") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("767") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("768") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/778.wav")
        }
        if inst.containsIgnoringCase("769") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/779.wav")
        }
        if inst.containsIgnoringCase("77") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/77.wav")
        }
        if inst.containsIgnoringCase("770") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("771") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/771.wav")
        }
        if inst.containsIgnoringCase("772") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/772.wav")
        }
        if inst.containsIgnoringCase("773") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/773.wav")
        }
        if inst.containsIgnoringCase("774") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/774.wav")
        }
        if inst.containsIgnoringCase("775") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("776") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("777") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/777.wav")
        }
        if inst.containsIgnoringCase("778") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/778.wav")
        }
        if inst.containsIgnoringCase("779") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/779.wav")
        }
        if inst.containsIgnoringCase("78") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/78.wav")
        }
        if inst.containsIgnoringCase("780") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("781") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/781.wav")
        }
        if inst.containsIgnoringCase("782") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/782.wav")
        }
        if inst.containsIgnoringCase("783") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/783.wav")
        }
        if inst.containsIgnoringCase("784") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/784.wav")
        }
        if inst.containsIgnoringCase("785") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/787.wav")
        }
        if inst.containsIgnoringCase("786") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/787.wav")
        }
        if inst.containsIgnoringCase("787") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/787.wav")
        }
        if inst.containsIgnoringCase("788") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/788.wav")
        }
        if inst.containsIgnoringCase("789") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/789.wav")
        }
        if inst.containsIgnoringCase("790") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/790.wav")
        }
        if inst.containsIgnoringCase("79") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/79.wav")
        }
        if inst.containsIgnoringCase("791") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/791.wav")
        }
        if inst.containsIgnoringCase("792") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/792.wav")
        }
        if inst.containsIgnoringCase("793") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/793.wav")
        }
        if inst.containsIgnoringCase("794") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/794.wav")
        }
        if inst.containsIgnoringCase("795") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/797.wav")
        }
        if inst.containsIgnoringCase("796") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/797.wav")
        }
        if inst.containsIgnoringCase("797") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/797.wav")
        }
        if inst.containsIgnoringCase("798") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/798.wav")
        }
        if inst.containsIgnoringCase("799") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/799.wav")
        }
        if inst.containsIgnoringCase("80") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/80.wav")
        }
        if inst.containsIgnoringCase("800") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/800.wav")
        }
        if inst.containsIgnoringCase("801") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/801.wav")
        }
        if inst.containsIgnoringCase("802") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/802.wav")
        }
        if inst.containsIgnoringCase("803") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/803.wav")
        }
        if inst.containsIgnoringCase("804") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/804.wav")
        }
        if inst.containsIgnoringCase("805") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsIgnoringCase("806") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsIgnoringCase("807") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsIgnoringCase("808") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/808.wav")
        }
        if inst.containsIgnoringCase("809") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/809.wav")
        }
        if inst.containsIgnoringCase("810") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/810.wav")
        }
        if inst.containsIgnoringCase("811") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/811.wav")
        }
        if inst.containsIgnoringCase("812") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/812.wav")
        }
        if inst.containsIgnoringCase("813") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/813.wav")
        }
        if inst.containsIgnoringCase("814") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/814.wav")
        }
        if inst.containsIgnoringCase("815") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsIgnoringCase("816") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsIgnoringCase("817") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsIgnoringCase("818") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/818.wav")
        }
        if inst.containsIgnoringCase("819") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/819.wav")
        }
        if inst.containsIgnoringCase("82") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/82.wav")
        }
        if inst.containsIgnoringCase("821") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/821.wav")
        }
        if inst.containsIgnoringCase("822") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/822.wav")
        }
        if inst.containsIgnoringCase("823") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/823.wav")
        }
        if inst.containsIgnoringCase("824") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/824.wav")
        }
        if inst.containsIgnoringCase("825") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsIgnoringCase("826") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsIgnoringCase("827") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsIgnoringCase("828") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/828.wav")
        }
        if inst.containsIgnoringCase("829") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/829.wav")
        }
        if inst.containsIgnoringCase("830") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/830.wav")
        }
        if inst.containsIgnoringCase("83") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/83.wav")
        }
        if inst.containsIgnoringCase("831") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/831.wav")
        }
        if inst.containsIgnoringCase("832") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/832.wav")
        }
        if inst.containsIgnoringCase("833") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/833.wav")
        }
        if inst.containsIgnoringCase("834") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/834.wav")
        }
        if inst.containsIgnoringCase("835") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsIgnoringCase("836") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsIgnoringCase("837") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsIgnoringCase("838") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/838.wav")
        }
        if inst.containsIgnoringCase("839") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/839.wav")
        }
        if inst.containsIgnoringCase("84") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/84.wav")
        }
        if inst.containsIgnoringCase("840") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/840.wav")
        }
        if inst.containsIgnoringCase("841") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/841.wav")
        }
        if inst.containsIgnoringCase("842") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/842.wav")
        }
        if inst.containsIgnoringCase("843") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/843.wav")
        }
        if inst.containsIgnoringCase("844") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/844.wav")
        }
        if inst.containsIgnoringCase("845") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsIgnoringCase("846") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsIgnoringCase("847") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsIgnoringCase("848") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/848.wav")
        }
        if inst.containsIgnoringCase("849") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/849.wav")
        }
        if inst.containsIgnoringCase("850") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/880.wav")
        }
        if inst.containsIgnoringCase("85") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("851") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsIgnoringCase("852") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsIgnoringCase("853") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/833.wav")
        }
        if inst.containsIgnoringCase("854") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsIgnoringCase("855") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("856") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("857") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("858") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("859") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsIgnoringCase("86") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("860") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("861") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsIgnoringCase("862") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsIgnoringCase("863") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/883.wav")
        }
        if inst.containsIgnoringCase("864") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsIgnoringCase("865") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("866") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("867") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("868") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("869") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsIgnoringCase("87") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("870") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("871") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsIgnoringCase("872") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsIgnoringCase("873") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/883.wav")
        }
        if inst.containsIgnoringCase("874") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsIgnoringCase("875") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("876") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("877") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("878") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("879") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsIgnoringCase("88") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("880") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/88.wav")
        }
        if inst.containsIgnoringCase("881") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/881.wav")
        }
        if inst.containsIgnoringCase("882") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/882.wav")
        }
        if inst.containsIgnoringCase("883") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/883.wav")
        }
        if inst.containsIgnoringCase("884") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/884.wav")
        }
        if inst.containsIgnoringCase("885") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("886") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("887") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("888") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/888.wav")
        }
        if inst.containsIgnoringCase("889") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/889.wav")
        }
        if inst.containsIgnoringCase("890") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/890.wav")
        }
        if inst.containsIgnoringCase("89") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/89.wav")
        }
        if inst.containsIgnoringCase("891") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/891.wav")
        }
        if inst.containsIgnoringCase("892") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/892.wav")
        }
        if inst.containsIgnoringCase("893") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/893.wav")
        }
        if inst.containsIgnoringCase("894") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/894.wav")
        }
        if inst.containsIgnoringCase("895") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsIgnoringCase("896") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsIgnoringCase("897") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsIgnoringCase("898") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/898.wav")
        }
        if inst.containsIgnoringCase("899") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/899.wav")
        }
        if inst.containsIgnoringCase("90") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/90.wav")
        }
        if inst.containsIgnoringCase("900") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/900.wav")
        }
        if inst.containsIgnoringCase("901") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/901.wav")
        }
        if inst.containsIgnoringCase("902") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/902.wav")
        }
        if inst.containsIgnoringCase("903") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/903.wav")
        }
        if inst.containsIgnoringCase("904") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/904.wav")
        }
        if inst.containsIgnoringCase("905") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsIgnoringCase("906") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsIgnoringCase("907") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsIgnoringCase("908") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsIgnoringCase("909") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/909.wav")
        }
        if inst.containsIgnoringCase("910") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/910.wav")
        }
        if inst.containsIgnoringCase("911") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/911.wav")
        }
        if inst.containsIgnoringCase("912") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/912.wav")
        }
        if inst.containsIgnoringCase("913") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/913.wav")
        }
        if inst.containsIgnoringCase("914") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/914.wav")
        }
        if inst.containsIgnoringCase("915") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsIgnoringCase("916") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsIgnoringCase("917") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsIgnoringCase("918") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsIgnoringCase("919") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/919.wav")
        }
        if inst.containsIgnoringCase("92") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/92.wav")
        }
        if inst.containsIgnoringCase("921") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/921.wav")
        }
        if inst.containsIgnoringCase("922") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/922.wav")
        }
        if inst.containsIgnoringCase("923") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/923.wav")
        }
        if inst.containsIgnoringCase("924") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/924.wav")
        }
        if inst.containsIgnoringCase("925") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsIgnoringCase("926") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsIgnoringCase("927") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsIgnoringCase("928") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsIgnoringCase("929") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/929.wav")
        }
        if inst.containsIgnoringCase("930") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/930.wav")
        }
        if inst.containsIgnoringCase("93") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/93.wav")
        }
        if inst.containsIgnoringCase("931") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/931.wav")
        }
        if inst.containsIgnoringCase("932") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/932.wav")
        }
        if inst.containsIgnoringCase("933") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/933.wav")
        }
        if inst.containsIgnoringCase("934") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/934.wav")
        }
        if inst.containsIgnoringCase("935") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsIgnoringCase("936") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsIgnoringCase("937") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsIgnoringCase("938") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsIgnoringCase("939") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/939.wav")
        }
        if inst.containsIgnoringCase("94") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/94.wav")
        }
        if inst.containsIgnoringCase("940") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/940.wav")
        }
        if inst.containsIgnoringCase("941") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/941.wav")
        }
        if inst.containsIgnoringCase("942") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/942.wav")
        }
        if inst.containsIgnoringCase("943") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/943.wav")
        }
        if inst.containsIgnoringCase("944") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/944.wav")
        }
        if inst.containsIgnoringCase("945") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsIgnoringCase("946") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsIgnoringCase("947") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsIgnoringCase("948") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsIgnoringCase("949") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/949.wav")
        }
        if inst.containsIgnoringCase("950") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/990.wav")
        }
        if inst.containsIgnoringCase("95") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("951") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsIgnoringCase("952") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsIgnoringCase("953") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/933.wav")
        }
        if inst.containsIgnoringCase("954") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsIgnoringCase("955") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("956") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("957") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("958") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("959") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("96") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("960") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("961") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsIgnoringCase("962") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsIgnoringCase("963") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsIgnoringCase("964") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsIgnoringCase("965") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("966") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("967") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("968") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("969") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("97") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("970") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("971") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsIgnoringCase("972") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsIgnoringCase("973") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsIgnoringCase("974") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsIgnoringCase("975") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("976") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("977") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("978") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("979") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("98") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("980") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("981") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsIgnoringCase("982") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsIgnoringCase("983") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsIgnoringCase("984") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsIgnoringCase("985") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("986") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("987") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("988") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("989") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("990") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/990.wav")
        }
        if inst.containsIgnoringCase("99") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/99.wav")
        }
        if inst.containsIgnoringCase("991") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/991.wav")
        }
        if inst.containsIgnoringCase("992") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/992.wav")
        }
        if inst.containsIgnoringCase("993") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/993.wav")
        }
        if inst.containsIgnoringCase("994") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/994.wav")
        }
        if inst.containsIgnoringCase("995") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("996") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("997") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("998") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        if inst.containsIgnoringCase("999") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/999.wav")
        }
        
        StartPlaying()
    }
    
    func AddAudioToQueue(ofUrl url:String?)
    {
        print("AddAudioToQueue : \(url)")
        
        guard let urlString = url else {
            return
        }
        
        //var isFoundFromLocal = false
        if (urlString.containsIgnoringCase("http://")
            || urlString.containsIgnoringCase("https://"))
            && urlString.containsIgnoringCase(".wav")
        {
            print(urlString.substringWithLastInstanceOf("/"))
            if let soundName = urlString.substringWithLastInstanceOf("/")
                where NSBundle.mainBundle().URLForResource(soundName, withExtension: "wav") != nil
            {
                print(" Local Resource : - \(NSBundle.mainBundle().URLForResource(soundName, withExtension: "wav"))")
                if let AudioIdem = AudioItem(soundURLs: [AudioQuality.Medium : NSURL(string: NSBundle.mainBundle().URLForResource(soundName, withExtension: "wav")!.absoluteString)!]) {
                    AudioItems?.append(AudioIdem)
                }
                return
            }
            
        }
        
        if let mp3Url = NSURL(string: urlString) {
            //mp3Urls.append(mp3Url)
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
            if CLocation?.coordinate.latitude == 0
                && CLocation?.coordinate.longitude == 0
            {
                CLocation = LocationManager.sharedInstance.CLocation
            }
            
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

// Extra Codes - UnUsed but ca use later

//-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    
//    CLLocationDirection direction = newHeading.trueHeading;
//    lastDriverAngleFromNorth = direction;
//    self.driverMarker.rotation = lastDriverAngleFromNorth - mapBearing;
//}
//
//#pragma mark - GMSMapViewDelegate
//
//- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
//    
//    mapBearing = position.bearing;
//    self.driverMarker.rotation = lastDriverAngleFromNorth - mapBearing;
//}
//
////just do this only
//- (void)locationManager:(CLLocationManager *)manager  didUpdateHeading:(CLHeading *)newHeading
//{
//    double heading = newHeading.trueHeading;
//    marker.groundAnchor = CGPointMake(0.5, 0.5);
//    marker.rotation = heading;
//    marker.map = mapView;
//}
