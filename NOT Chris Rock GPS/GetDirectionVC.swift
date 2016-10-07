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

class GetDirectionVC: UIViewController,UITextFieldDelegate,UISearchBarDelegate, LocateOnTheMap {
    
    var searchResultController:SearchResultsController!
    var resultsArray = [String]()
    var fromClicked = Bool()
    var mapManager = DirectionManager()
    var tableData = NSDictionary()
    var directionDetail = NSArray()
    var polyline: MKPolyline = MKPolyline()
    let markerNextTurn = GMSMarker()
    
    var player:AVPlayer?
    var bizForRoute: Business?
    
    @IBOutlet var btnMenu: UIButton?
    //@IBOutlet weak var drawMap: MKMapView!
    @IBOutlet weak var googleMapsView : GMSMapView!
    @IBOutlet weak var txtTo: UITextField!
    @IBOutlet weak var txtFrom: UITextField!
    @IBOutlet weak var btnGetDirection: UIButton!
    @IBOutlet weak var btnStartRoute: UIButton!
    
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
            self.btnStartRoute.setTitle("Stop Route", forState: .Normal)
            self.btnStartRoute.backgroundColor = clrGreen
            self.btnStartRoute.tag = 2;
            
            print("Start monitoring route")
            startObservingRoute()
        } else if self.btnStartRoute.enabled
            && self.btnStartRoute.tag == 2
        {
            self.btnStartRoute.setTitle("Start Route", forState: .Normal)
            self.btnStartRoute.backgroundColor = clrRed
            self.btnStartRoute.tag = 1;
            
            print("stop monitoring route")
            stopObservingRoute()
        }
    }
    
    func startObservingRoute()
    {
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
        LocationManager.sharedInstance.startUpdatingLocationWithCompletionHandler(nil)
        markerNextTurn.map = nil
    }
    
    func playSoundForInstruction(instruction:String?) {
        guard let inst = instruction else {
            print("Instruction not found")
            return
        }
        
        print("Playing Sound for instruction : \(inst)")
        //self.playSound(ofUrl: "http://www.notchrisrock.com/gps/api/sounds/Route/route.wav")
        
        if inst.containsString("Turn right") || inst.containsString("turns left") {
            self.playSound(ofUrl: "\(BaseUrlSounds)Directional/to-the-right.wav")
        } else if inst.containsString("Turn left") || inst.containsString("turns right") {
            self.playSound(ofUrl: "\(BaseUrlSounds)Directional/to-the-left.wav")
        } else if inst.containsString("Turn right onto") {
            self.playSound(ofUrl: "\(BaseUrlSounds)Directional/to-the-right2.wav")
        } else if inst.containsString("Turn left onto") {
            self.playSound(ofUrl: "\(BaseUrlSounds)Directional/to-the-left2.wav")
        }
        
        if inst.containsString("highway") {
            self.playSound(ofUrl: "\(BaseUrlSounds)Highway/highway.wav")
        }
    }
    
    func playSound(ofUrl url:String)
    {
        let mp3Url = NSURL(string: url)
        print("playing soung for url : \(mp3Url)")
        
        do {
            let playerItem = AVPlayerItem(URL: mp3Url!)
            
            self.player = try AVPlayer(playerItem:playerItem)
            player?.volume = 1.0
            player?.play()
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
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

