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
    var isObservingRoute = false
    
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
        
        self.googleMapsView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        dispatch_async(dispatch_get_main_queue(), {
            self.googleMapsView.myLocationEnabled = true;
        });
        
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
        
        
        //let camera = GMSCameraPosition.cameraWithLatitude(53.9,longitude: 27.5667, zoom: 6)
        //self.googleMapsView.animateToCameraPosition(camera)
        
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

    // MARK: -
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if change![NSKeyValueChangeOldKey] == nil && isObservingRoute == true
        {
            if let location = change?[NSKeyValueChangeNewKey] as? CLLocation {
                self.googleMapsView.animateToCameraPosition(GMSCameraPosition(target: location.coordinate, zoom: self.googleMapsView.camera.zoom, bearing: 0, viewingAngle: 0))
            }
        }
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
            isObservingRoute = true
            self.btnRefresh.hidden = true
            self.btnStartRoute.setTitle("Stop Route", forState: .Normal)
            self.btnStartRoute.backgroundColor = clrGreen
            self.btnStartRoute.tag = 2;
            
            let camera = GMSCameraPosition.cameraWithLatitude(LocationManager.sharedInstance.latitude,longitude: LocationManager.sharedInstance.longitude, zoom: 20)
            self.googleMapsView.animateToCameraPosition(camera)
            
            print("Start monitoring route")
            startObservingRoute()
        } else if self.btnStartRoute.enabled
            && self.btnStartRoute.tag == 2
        {
            isObservingRoute = false
            self.btnRefresh.hidden = false
            self.btnStartRoute.setTitle("Start Route", forState: .Normal)
            self.btnStartRoute.backgroundColor = clrRed
            self.btnStartRoute.tag = 1;
            
            print("stop monitoring route")
            stopObservingRoute()
        }
    }
    
    func startObservingRoute()
    {
        
        playSoundForInstruction("StartRoute")
        
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
        
        let camera = GMSCameraPosition.cameraWithLatitude(LocationManager.sharedInstance.latitude,longitude: LocationManager.sharedInstance.longitude, zoom: 20)
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
        if inst.containsString("StartRoute") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Directional/lets-go.wav")
        }
        
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
            
            mapManager.directionsUsingGoogle(from: from, to: txtTo.text!)
            {
                (route,encodedPolyLine ,directionInformation, boundingRegion, error) -> () in
                
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
                        
                        let camera = GMSCameraPosition.cameraWithLatitude(coordOrigin.latitude,longitude: coordOrigin.longitude, zoom: 15)
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

