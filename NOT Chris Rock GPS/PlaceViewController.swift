//
//  SelectLocationViewController.swift
//  MLM
//
//  Created by Parth Dabhi on 12/01/16.
//  Copyright © 2016 IBL Infotech (Parth Dabhi). All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

import Alamofire
import AlamofireSwiftyJSON

protocol PlaceSelectDelegate {
    func OnSelectUserLocation(Location:CLLocation?,LocationDetail:String?)
}

class PlaceViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var mvLocation: MKMapView!
    @IBOutlet var lblLocationDetail: UILabel!
    
    @IBOutlet var viewSearch: UIView!
    @IBOutlet var tblPlaceList: UITableView!
    @IBOutlet var txtSearchBar: UITextField!
    @IBOutlet var btnSearch: UIButton!
    @IBOutlet var btnCurrentLoc: UIButton!
    
    // MARK: - Properties
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var seenError:Bool!
    var locationFixAchieved:Bool!
    var locationStatus:String!
    var SearchPlaceResult = [AnyObject]()
    
    var selectedLocation: CLLocation?
    var locationString:String!
    var manager:Manager?
    var showCurrentLocation = false
    
    var delegate : PlaceSelectDelegate?
    
    // MARK: - VC Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        viewSearch.layer.borderWidth = 0.5
        viewSearch.layer.borderColor = UIColor.darkGrayColor().CGColor
        
        tblPlaceList.delegate = self
        tblPlaceList.dataSource = self
        tblPlaceList.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
        
        if locationString != nil {
            lblLocationDetail.text = locationString;
        }
        if self.selectedLocation != nil
        {
            let center = CLLocationCoordinate2D(latitude: self.selectedLocation!.coordinate.latitude, longitude: self.selectedLocation!.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mvLocation.setRegion(region, animated: true)
            AddAnnotationAtCoord(self.selectedLocation!.coordinate)
        }
        
        initLocationManager()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(PlaceViewController.actionAddPinAtPoint(_:)))
        longPress.minimumPressDuration = 1.0
        mvLocation.addGestureRecognizer(longPress)
        
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        manager  = Alamofire.Manager(configuration: configuration)
    }
    
    func initLocationManager() {
        
        if !CLLocationManager.locationServicesEnabled() {
            print("Location service not enabled")
        }
        
        seenError = false
        locationFixAchieved = false
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func actionAddPinAtPoint(gestureRecognizer:UIGestureRecognizer)
    {
        mvLocation.removeAnnotations(mvLocation.annotations)
        
        let touchPoint = gestureRecognizer.locationInView(self.mvLocation)
        let newCoord:CLLocationCoordinate2D = mvLocation.convertPoint(touchPoint, toCoordinateFromView: self.mvLocation)
        
        AddAnnotationAtCoord(newCoord)
        
        selectedLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
        lblLocationDetail.text = "";
        CLGeocoder().reverseGeocodeLocation(selectedLocation!, completionHandler: {(placemarks, error)->Void in
            let pm = placemarks![0]
            self.displayLocationInfo(pm)
        })
    }
    
    func AddAnnotationAtCoord(Coord: CLLocationCoordinate2D)
    {
        let newAnotation = MKPointAnnotation()
        newAnotation.coordinate = Coord
        newAnotation.title = "Selected Location"
        newAnotation.subtitle = ""
        mvLocation.addAnnotation(newAnotation)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        locationManager.stopUpdatingLocation()
        if (seenError == false) {
            seenError = true
            print("Location Update Fails with errors : \(error)")
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            if #available(iOS 9.0, *) {
                pinView?.pinTintColor = UIColor.orangeColor()
            } else {
                // Fallback on earlier versions
                pinView?.pinColor = MKPinAnnotationColor.Red
            }
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        CLocation = locations.last! as CLLocation
        CLGeocoder().reverseGeocodeLocation(CLocation!, completionHandler: {(placemarks, error)->Void in
            let pm = placemarks![0]
            if let place = pm.LocationString()
            {
                CLocationPlace = place
            }
        })
        
        
        if self.selectedLocation == nil || self.showCurrentLocation
        {
            self.showCurrentLocation = false
            
            let location = locations.last! as CLLocation
            currentLocation = location
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            self.mvLocation.setRegion(region, animated: true)
        }
        
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            let locationArray = locations as NSArray
            let locationObj = locationArray.lastObject as! CLLocation
            _ = locationObj.coordinate
            
            if let lat = self.currentLocation?.coordinate.latitude, lon = self.currentLocation?.coordinate.longitude {
                print("\(lat),\(lon)")
            }
        }
        locationManager.stopUpdatingLocation()
    }
    
    func displayLocationInfo(placemark: CLPlacemark?) {
        if let containsPlacemark = placemark
        {
            //stop updating location to save battery life
            locationManager.stopUpdatingLocation()
            
            print("\(containsPlacemark)")
            var LocArray = [""]
            LocArray.removeAll()
            if (containsPlacemark.locality != nil
                && containsPlacemark.locality?.characters.count > 1) {
                LocArray.append(containsPlacemark.locality!)
            }
            if containsPlacemark.administrativeArea != nil  && containsPlacemark.administrativeArea?.characters.count > 1 {
                LocArray.append((containsPlacemark.administrativeArea)!)
            }
            if containsPlacemark.country != nil  && containsPlacemark.country?.characters.count > 1 {
                LocArray.append(containsPlacemark.country!)
            }
            locationString = LocArray.joinWithSeparator(", ")
            lblLocationDetail.text = locationString
            print("String : \(locationString)")
        }
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            var shouldIAllow = false
            switch status {
            case CLAuthorizationStatus.Restricted:
                locationStatus = "Restricted Access to location"
            case CLAuthorizationStatus.Denied:
                locationStatus = "User denied access to location"
            case CLAuthorizationStatus.NotDetermined:
                locationStatus = "Status not determined"
            default:
                locationStatus = "Allowed to location Access"
                shouldIAllow = true
            }
            NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
            if (shouldIAllow == true) {
                NSLog("Location to Allowed : \(locationStatus)")
                locationManager.startUpdatingLocation()
            } else {
                NSLog("Denied access: \(locationStatus)")
            }
    }

    @IBAction func CancelLocationSelection(sender: UIButton)
    {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func DoneLocationSelection(sender: UIButton)
    {
        if selectedLocation != nil
            && locationString.characters.count > 2
        {
            delegate?.OnSelectUserLocation(selectedLocation,LocationDetail: locationString)
        }
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    @IBAction func didTapCurrentLocation(sender: UIButton)
    {
        self.showCurrentLocation = true
        mvLocation.showsUserLocation = true
        initLocationManager()
    }
    
    func testDelegate() {
        print("in my target view controller delegate")
    }
    
    // MARK - TextField Delegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text! as NSString
        let proposedText = currentText.stringByReplacingCharactersInRange(range, withString: string)
        if (string == "\n")
        {
            textField.resignFirstResponder()
            return false;
        }
        else if proposedText.characters.count > 40 && currentText.length <= proposedText.characters.count {
            return false
        } else {
            Search(proposedText)
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        Search(txtSearchBar.text!)
        return true
    }
    
    // MARK - TableView Delegate & DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchPlaceResult.count
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel!.text = "\(indexPath.row)"
        cell.detailTextLabel?.text = "location"
        
        cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 14.0)
        if let PlaceDetail = SearchPlaceResult[indexPath.row] as? NSDictionary {
            print("\(PlaceDetail)")
            if let Desc = PlaceDetail["description"] as? String {
                cell.textLabel?.text = Desc
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableView.hidden = true;
        if let PlaceDetail = SearchPlaceResult[indexPath.row] as? NSDictionary {
            if let Desc = PlaceDetail["description"] as? String {
                self.txtSearchBar.text = Desc
            }
        }
        //self.txtSearchBar.text = ""
        self.view.endEditing(true)
        
        if let PlaceDetail = SearchPlaceResult[indexPath.row] as? NSDictionary {
            print("\(PlaceDetail)")
            if let Desc = PlaceDetail["description"] as? String {
                print("Selected Address : \(Desc)")
            }
            if let place_id = PlaceDetail["place_id"] as? String {
                getLatLngFromPlaceId(place_id, isDidSelect: true)
            }
            
        }
    }
    
    func Search(searchStr:String)
    {
        let url: String = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        let jsonData: [String : String] = [
            "key" : "AIzaSyA5q9bxiJA2g1fVqyi0O_iWT4gNcU0ICC0",
            "types" : "",
            "input" : txtSearchBar.text!
        ]
        
        if #available(iOS 9.0, *) {
           manager!.session.getAllTasksWithCompletionHandler { (tasks) -> Void in
                tasks.forEach({ $0.cancel() })
            }
        } else {
            // Fallback on earlier versions
            manager!.session.getTasksWithCompletionHandler({
                $0.0.forEach({ $0.cancel() })
                $0.1.forEach({ $0.cancel() })
                $0.2.forEach({ $0.cancel() })
            })
        }
        
        manager!.request(.GET, url, parameters: jsonData)
            .responseSwiftyJSON { response in
                print("###Success: \(response.result.isSuccess)")
                //now response.result.value is SwiftyJSON.JSON type
                print("###Value: \(response.result.value?["args"].array)")
                if response.result.isSuccess {
                    let PlaceList = response.result.value?["predictions"].arrayObject
                    
                    if response.result.value?["status"] != nil
                        && response.result.value?["status"] == "OK"
                        && PlaceList != nil
                    {
                        self.SearchPlaceResult = PlaceList!
                        self.tblPlaceList.hidden = false
                        self.tblPlaceList.reloadData()
                    }
                }
        }
    }
    
    func getLatLngFromPlaceId(placeId: String, isDidSelect: Bool) {
        let url: String = "https://maps.googleapis.com/maps/api/place/details/json"
        let jsonData: [String : String] = [
            "key" : "AIzaSyA5q9bxiJA2g1fVqyi0O_iWT4gNcU0ICC0",
            "placeid" : placeId
        ]
        
        CommonUtils.sharedUtils.showProgress(self.view, label: "Loading..")
        Alamofire.request(.GET, url, parameters: jsonData)
            .responseSwiftyJSON { response in
                print("###Success: \(response.result.isSuccess)")
                //now response.result.value is SwiftyJSON.JSON type
                print("###Value: \(response.result.value?["args"].array)")
                
                CommonUtils.sharedUtils.hideProgress()
                if let json = response.result.value where response.result.isSuccess {
                        print("JSON: \(json)")
                        let PlaceDeatil = json["result"].dictionary
                        
                        if json["status"] != nil
                            && json["status"] == "OK"
                            && PlaceDeatil != nil
                        {
                            print("\(PlaceDeatil)")
                            if let geometry = PlaceDeatil!["geometry"]?.dictionary {
                                print("\(geometry)")
                                if let location = geometry["location"]?.dictionary {
                                    print("\(location)")
                                    let selectedLat = location["lat"]?.double;
                                    let selectedLng = location["lng"]?.double;
                                    if selectedLat != nil && selectedLng != nil
                                    {
                                        self.selectedLocation = CLLocation(latitude: selectedLat!, longitude: selectedLng!)
                                        
                                        self.mvLocation.removeAnnotations(self.mvLocation.annotations)
                                        self.AddAnnotationAtCoord(self.selectedLocation!.coordinate)
                                        self.lblLocationDetail.text = "";
                                        CommonUtils.sharedUtils.showProgress(self.view, label: "Loading..")
                                        CLGeocoder().reverseGeocodeLocation(self.selectedLocation!, completionHandler: {(placemarks, error)->Void in
                                            CommonUtils.sharedUtils.hideProgress()
                                            let pm = placemarks![0]
                                            self.displayLocationInfo(pm)
                                        })
                                        
                                        let latDelta:CLLocationDegrees = 0.05
                                        let lonDelta:CLLocationDegrees = 0.05
                                        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
                                        let region:MKCoordinateRegion = MKCoordinateRegionMake(self.selectedLocation!.coordinate, span)
                                        self.mvLocation.setRegion(region, animated: true)
                                    }
                                }
                            }
                        } else {
                            
                        }
                }
            }
    }
}


