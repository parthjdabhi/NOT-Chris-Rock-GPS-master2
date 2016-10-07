//
//  GooglePlacesViewController.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/14/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

import SWRevealViewController
import Alamofire
import SwiftyJSON
import SDWebImage

class GooglePlacesViewController: UIViewController, UISearchBarDelegate, LocateOnTheMap, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var btnMenu: UIButton?
    @IBOutlet weak var btnSearch: UIButton!
    @IBOutlet weak var googleMapsContainer: UIView!
    @IBOutlet weak var googleMapsView : GMSMapView!
    //@IBOutlet var googleMVContainer: UIView!
    @IBOutlet weak var btnRefreshNearByPlace: UIButton!
    
    //var googleMapsView: GMSMapView!
    var searchResultController: SearchResultsController!
    var resultsArray = [String]()
    var locationManager = CLLocationManager()
    
    //To Store Food places
    var places:[MyPlace] = []
    var placesDetail:[JSON] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationController?.navigationBarHidden = false
        // Do any additional setup after loading the view, typically from a nib.
        
        isEnableFivetapGesture = false
        startFiveTapGesture()
        
        btnSearch.titleLabel?.numberOfLines = 2
        btnSearch.titleLabel?.textAlignment = .Center
        
        btnRefreshNearByPlace.setCornerRadious()
        btnRefreshNearByPlace.setBorder(1.0, color: clrGreen)
        
        // Init menu button action for menu
        if let revealVC = self.revealViewController() {
            self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
            //self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
            //self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
        
        //googleMVContainer.layoutIfNeeded()
        //var frameMV = googleMVContainer.frame
        //frameMV.origin.y = 0
        //googleMapsView = GMSMapView(frame: frameMV)
        //self.googleMVContainer.insertSubview(self.googleMapsView, atIndex: 0)
        
        //GMSServices.provideAPIKey(googleMapsApiKey)
        //self.googleMapsView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        let camera = GMSCameraPosition.cameraWithLatitude(53.9,longitude: 27.5667, zoom: 6)
        self.googleMapsView.animateToCameraPosition(camera)
        
        //        locationManager.delegate = self
        //        locationManager.requestWhenInUseAuthorization()
        //        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //        locationManager.startUpdatingLocation()
        
        self.googleMapsView.delegate = self
        self.googleMapsView.myLocationEnabled = true
        self.googleMapsView.settings.myLocationButton = true
        
        initLocationManager()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(true)
        
        //self.googleMapsView.removeObserver(self, forKeyPath: "myLocation")
        searchResultController = SearchResultsController()
        searchResultController.delegate = self
    }
    
    @IBAction func searchWithAddress(sender: AnyObject)
    {
        let searchController = UISearchController(searchResultsController: searchResultController)
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholderText = "Search your destination"
        self.presentViewController(searchController, animated: true, completion: nil)
    }
    
    func locateWithLongitude(lon: Double, andLatitude lat: Double, andTitle title: String)
    {
        CLocationSelected =  CLLocation(latitude: lat, longitude: lon)
        addOverlayToMapView()
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            self.googleMapsView.clear()
            
            let position = CLLocationCoordinate2DMake(lat, lon)
            
            
            let marker = GMSMarker(position: position)
            let camera = GMSCameraPosition.cameraWithLatitude(lat, longitude: lon, zoom: 10)
            self.googleMapsView.animateToCameraPosition(camera)
            
            marker.title = "\(title)"
            //marker.snippet = "NOT chris rock"
            marker.map = self.googleMapsView
            marker.icon = GMSMarker.markerImageWithColor(clrGreen)
            
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        let placeClient = GMSPlacesClient()
        placeClient.autocompleteQuery(searchText, bounds: nil, filter: nil) { (results, error: NSError?) -> Void in
            
            self.resultsArray.removeAll()
            if results == nil {
                return
            }
            
            for result in results! {
                if let result = result as? GMSAutocompletePrediction {
                    self.resultsArray.append(result.attributedFullText.string)
                }
            }
            self.searchResultController.reloadDataWithArray(self.resultsArray)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initLocationManager()
    {
        if !CLLocationManager.locationServicesEnabled() {
            print("Location service not enabled")
        }
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        locationManager.stopUpdatingLocation()
        print("Location Update Fails with errors : \(error)")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        CLocation = locations.last! as CLLocation
        self.googleMapsView.camera = GMSCameraPosition(target: CLocation!.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        CLGeocoder().reverseGeocodeLocation(CLocation!, completionHandler: {(placemarks, error)->Void in
            let pm = placemarks![0]
            if let place = pm.LocationString()
            {
                CLocationPlace = place
            }
        })
        locationManager.stopUpdatingLocation()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "myLocation" {
            print("myLocation",object)
            //            if let l:CLLocation = object?.location {
            //                print("Location : ",l)
            //            }
        }
    }
    
    func addOverlayToMapView()
    {
        let directionURL = "https://maps.googleapis.com/maps/api/directions/json?origin=\(CLocation!.coordinate.latitude),\(CLocation!.coordinate.longitude)&destination=\(CLocationSelected.coordinate.latitude),\(CLocationSelected.coordinate.longitude)&key=\(googleMapsApiKey)&mode=driving"
        //mode:driving,walking,bicycling,transit
        print(directionURL)
        
        Alamofire.request(.GET, directionURL, parameters: nil).responseJSON { response in
            
            switch response.result {
                
            case .Success(let data):
                
                let json = JSON(data)
                let errornum = json["error"]
                print(json)
                
                if (errornum == true) {
                    print("Error",errornum)
                } else {
                    if let routes = json["routes"].array
                        where routes.count > 0
                    {
                        let overViewPolyLine = routes[0]["overview_polyline"]["points"].string
                        print(overViewPolyLine)
                        if overViewPolyLine != nil{
                            self.addPolyLineWithEncodedStringInMap(overViewPolyLine!)
                        }
                    } else {
                        self.googleMapsView.clear()
                    }
                }
                
            case .Failure(let error):
                print("Request failed with error: \(error)")
            }
        }
    }
    
    func addPolyLineWithEncodedStringInMap(encodedString: String)
    {
        let path = GMSMutablePath(fromEncodedPath: encodedString)
        let polyLine = GMSPolyline(path: path)
        polyLine.strokeWidth = 5
        polyLine.strokeColor = clrGreen
        polyLine.map = self.googleMapsView
    }
    
    @IBAction func actionGoToBack(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func actionRefreshNearByPlace(sender: AnyObject)
    {
        //For Search Via Google Maps Api
        //showNearByPlaceByGoogleAPI(["food"])
        
        //For Search Via Yelp
        showNearByPlace(["food"])
    }
    
    //Searcing by yelp api
    func showNearByPlace(ofCategory:[String])
    {
        
        guard let client = YelpClient.sharedInstance else { return }
        client.location = "\(CLocation!.coordinate.latitude),\(CLocation!.coordinate.longitude)"
        client.searchWithTerm(searchString, sort: Myfilters.sortBy, categories: Myfilters.categories, deals: Myfilters.hasDeal, completion: { (business, error) in
            businessArr = business
            for biz: Business in businessArr! {
                let marker = BizMarker(biz: biz)
                marker.map = self.googleMapsView
            }
            
            MBProgressHUD.hideHUDForView(self.view, animated: true)
        })
        
//        client.searchPlacesWithParameters(["ll": "\(CLocation!.coordinate.latitude),\(CLocation!.coordinate.longitude)", "category_filter": "burgers", "radius_filter": "3000","term": "food", "sort": "0"], successSearch: { (data, response) -> Void in
//            
//            //print(data.stringValue)
//            
//            let json = JSON(data.stringValue?.convertToDictionary ?? [:])
//            print(json)
//            
//            if let businesses = json["businesses"].array {
//                for business in businesses {
//                    
//                    //print(business)
//                    let place = MyPlace(json: business, Types: ["food"])
//                    
//                    self.places.append(place)
//                    self.placesDetail.append(business)
//                }
//                
//                for place: MyPlace in self.places {
//                    let marker = PlaceMarker(place: place)
//                    marker.map = self.googleMapsView
//                }
//            }
//            
//            //            self.burgerLabel.text = String(client.searchPlacesWithParameters(["ll": "37.788022,-122.399797", "category_filter": "burgers", "radius_filter": "3000", "sort": "0"], successSearch: { (data, response) -> Void in
//            //            }) { (error) -> Void in
//            //                print(error)
//            //                })
//            
//        }) { (error) -> Void in
//            print(error)
//        }
    }
    
    //Searcing by google api
//    func showNearByPlaceByGoogleAPI(ofCategory:[String])
//    {
//        
//        let directionURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=\(googleMapsApiKey)&sensor=false&location=\(CLocation!.coordinate.latitude),\(CLocation!.coordinate.longitude)&radius=10000&types=store&hasNextPage=true&nextPage()=true&types=\(ofCategory.joinWithSeparator(","))"
//        //"https://maps.googleapis.com/maps/api/directions/json?origin=\(CLocation!.coordinate.latitude),\(CLocation!.coordinate.longitude)&destination=\(CLocationSelected.coordinate.latitude),\(CLocationSelected.coordinate.longitude)&key=\(googleMapsApiKey)&mode=walking"
//        //mode:driving,walking,bicycling,transit
//        
//        //https ://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyB5jzZt5pc9-WVIEvfaBIZAIvQOYLhVu94&sensor=false&location=51.52864165,-0.10179430&radius=10000&types=store&hasNextPage=true&nextPage()=true&&pagetoken=CqQDmgEAAKT5-i-8iY5K4SPtMicW7Z2cUkGpM1kWiUIXSogohSio3vdw1bdSanD-mad_KgnSzk34KrXEfrTi6ABLxQidFTub6ilmoxRJx6bNhGSYdqkaJfW5h4Srw-7vkBToqto_NboFDMWzCAEzCqK1RgRGjRkWgPaHLi0gQ7wSTg9gecVVB-FAJ55QJO8w5lFrV5sAR-OF7yQ0Xqr9b2b4FyLoTBl-onaNNTqbycZXBFY28ychJywlQP3HbyfNVyU0sb5GODMbwZrQqP1JuolO_fhMnXyBYP3dwnFJVmdL25ms3b3DFwzTEII-3XeJWmPceSZnTIsLXn9-05JOWyTbaj0gI38G-1DeUUxthp7KDq47rTrNW5ogEfAO9pcfsIT7eSCzex5RhIvz1ohqpVYKT_Lr09MPQ6pYaEJ4ZY3_658aIi6GjcM4HkH2VDmfk-6DzF_hK3GFCbNeo1MjVlnPIt7Kp_6IvY-8aO0Xy8S3CAjtGLWXy0uxsADEMnC_mynFP0JhJJnbTu8RWuhPQbX0qdijx26fGXz1SlevkG2plENfnn2HEhBj-lJuu6Ua5-sngBrCzLXvGhRd_ubAQ4408c9YSShDc0RmhC5ogQ
//        print(directionURL)
//        
//        Alamofire.request(.GET, directionURL, parameters: nil).responseJSON { response in
//            
//            switch response.result {
//                
//            case .Success(let data):
//                
//                let json = JSON(data)
//                let errornum = json["error"]
//                print(json)
//                
//                if (errornum == true) {
//                    print("Error",errornum)
//                } else {
//                    
//                    //var places:[GMSMarker] = []
//                    
//                    if let results = json["results"].array
//                        where results.count > 0
//                    {
//                        //name
//                        
//                        for result in results {
//                            let marker = GMSMarker()
//                            marker.groundAnchor = CGPoint(x: 0.5, y: 1)
//                            marker.appearAnimation = kGMSMarkerAnimationPop
//                            marker.icon = UIImage(named: "default_marker.png")
//                            
//                            marker.title = result["name"].string
//                            marker.snippet = result["vicinity"].string
//                            
//                            marker.position = CLLocation(latitude: (result["geometry"]["location"]["lat"].double ?? 0), longitude: result["geometry"]["location"]["lng"].double ?? 0).coordinate
//                            
//                            let place = MyPlace(json: result, Types: ["food"])
//                            self.places.append(place)
//                        }
//                        
//                        for place: MyPlace in self.places {
//                            let marker = PlaceMarker(place: place)
//                            marker.map = self.googleMapsView
//                        }
//                        
//                    } else {
//                        self.googleMapsView.clear()
//                    }
//                }
//            case .Failure(let error):
//                print("Request failed with error: \(error)")
//            }
//        }
//    }
    
    // MARK: - GMSMapViewDelegate
    
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        print(position.target)
    }
    
    func mapView(mapView: GMSMapView, willMove gesture: Bool) {
        if (gesture) {
            mapView.selectedMarker = nil
        }
    }
    
    func mapView(mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        let placeMarker = marker as! BizMarker
        
        if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
            infoView.lblName.text = placeMarker.biz.name
            infoView.lblReviewCount.text = placeMarker.biz.reviewCount?.stringValue ?? ""
            infoView.lblAddress.text = placeMarker.biz.address ?? ""
            infoView.lblDistance.text = placeMarker.biz.distance ?? ""
            infoView.lblCategory.text = placeMarker.biz.categories ?? ""
            
            infoView.imgBiz.setCornerRadious(infoView.imgBiz.frame.width/2)
            if let photo = placeMarker.biz.photo {
                infoView.imgBiz.image = photo
            } else {
                infoView.imgBiz.image = UIImage(named: "button_compass_night.png")
            }
            
            if let ratingPhoto = placeMarker.biz.ratingPhoto {
                infoView.imgRating.image = ratingPhoto
            } else {
                infoView.imgRating.image = UIImage(named: "button_compass_night.png")
            }
            
            return infoView
        } else {
            return nil
        }
    }
    
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        return false
    }
    
    func didTapMyLocationButtonForMapView(mapView: GMSMapView) -> Bool {
        mapView.selectedMarker = nil
        return false
    }
}