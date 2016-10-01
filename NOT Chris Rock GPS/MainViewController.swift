//
//  MainViewController.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/14/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import UIKit

import FBSDKLoginKit
import GoogleMaps
import GooglePlaces

import SWRevealViewController
import Alamofire
import SwiftyJSON
import SDWebImage

class MainViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK: -
    // MARK: Vars
    //@IBOutlet var googleMapsView: GMSMapView!
    @IBOutlet var googleMVContainer: UIView!
    @IBOutlet weak var btnRefreshNearByPlace: UIButton!
    @IBOutlet weak var btnDirection: UIButton!
    @IBOutlet var btnMenu: UIButton?
    
    var googleMapsView: GMSMapView!
    var searchResultController: SearchResultsController!
    var resultsArray = [String]()
    //var locationManager = CLLocationManager()
    
    //To Store Food places
    var places:[MyPlace] = []
    var placesDetail:[JSON] = []
    
    // MARK: -
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        isEnableFivetapGesture = true
        startFiveTapGesture()
        
        btnRefreshNearByPlace.setCornerRadious()
        btnRefreshNearByPlace.setBorder(1.0, color: clrGreen)
        btnDirection.setCornerRadious()
        btnDirection.setBorder(1.0, color: clrGreen)
        
        // Init menu button action for menu
        if let revealVC = self.revealViewController() {
            self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
            //            self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
            //            self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
        
        googleMVContainer.layoutIfNeeded()
        var frameMV = googleMVContainer.frame
        frameMV.origin.y = 0
        googleMapsView = GMSMapView(frame: frameMV)
        self.googleMVContainer.insertSubview(self.googleMapsView, atIndex: 0)
        
        GMSServices.provideAPIKey(googleMapsApiKey)
        //self.googleMapsView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        
        self.googleMapsView.delegate = self
        self.googleMapsView.myLocationEnabled = true
        self.googleMapsView.settings.myLocationButton = true
        
        if LocationManager.sharedInstance.hasLastKnownLocation == false {
            LocationManager.sharedInstance.onFirstLocationUpdateWithCompletionHandler { (latitude, longitude, status, verboseMessage, error) in
                print(latitude,longitude,status)
                CLocation = CLLocation(latitude: latitude, longitude: longitude)
                self.googleMapsView.animateToCameraPosition(GMSCameraPosition(target: CLocation!.coordinate, zoom: 15, bearing: 0, viewingAngle: 0))
                //For Search Via Yelp
                self.showNearByPlace(["food"])
            }
        } else {
            self.googleMapsView.animateToCameraPosition(GMSCameraPosition(target: CLocation!.coordinate, zoom: 15, bearing: 0, viewingAngle: 0))
            //For Search Via Yelp
            showNearByPlace(["food"])
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -
    @IBAction func googleMapsButton(sender: AnyObject) {
        let next = self.storyboard?.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController!
        self.navigationController?.pushViewController(next, animated: true)
    }
    
    @IBAction func googlePlaces(sender: AnyObject) {
        //self.navigationController?.navigationBarHidden = false
        let next = self.storyboard?.instantiateViewControllerWithIdentifier("GooglePlacesViewController") as! GooglePlacesViewController!
        self.navigationController?.pushViewController(next, animated: true)
    }
    
    @IBAction func yelp(sender: AnyObject) {
        let next = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController") as! ViewController!
        self.navigationController?.pushViewController(next, animated: true)
    }
    
    @IBAction func weatherButton(sender: AnyObject) {
        let next = self.storyboard?.instantiateViewControllerWithIdentifier("OpenWeatherViewController") as! OpenWeatherViewController!
        self.navigationController?.pushViewController(next, animated: true)
    }
    
    @IBAction func recordAudio(sender: AnyObject) {
        
        let controller = AudioRecorderViewController()
        controller.audioRecorderDelegate = self
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func actionLogout(sender: AnyObject) {
        let actionSheetController = UIAlertController (title: "Message", message: "Are you sure want to logout?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        actionSheetController.addAction(UIAlertAction(title: "Logout", style: UIAlertActionStyle.Destructive, handler: { (actionSheetController) -> Void in
            print("handle Logout action...")
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey("userDetail")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            if FBSDKAccessToken.currentAccessToken() != nil {
                //FBSDKLoginManager().logOut()
            }
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            
            let navLogin = self.storyboard?.instantiateViewControllerWithIdentifier("SignInViewController") as! SignInViewController
            self.navigationController?.setViewControllers([navLogin], animated: true)
        }))
        
        presentViewController(actionSheetController, animated: true, completion: nil)
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
        
        client.searchPlacesWithParameters(["ll": "\(CLocation!.coordinate.latitude),\(CLocation!.coordinate.longitude)", "category_filter": "burgers", "radius_filter": "3000","term": "food", "sort": "0"], successSearch: { (data, response) -> Void in
            
            //print(data.stringValue)
            
            let json = JSON(data.stringValue?.convertToDictionary ?? [:])
            print(json)
            
            if let businesses = json["businesses"].array {
                for business in businesses {
                    
                    //print(business)
                    let place = MyPlace(json: business, Types: ["food"])
                    
                    self.places.append(place)
                    self.placesDetail.append(business)
                }
                
                for place: MyPlace in self.places {
                    let marker = PlaceMarker(place: place)
                    marker.map = self.googleMapsView
                }
            }
            
        }) { (error) -> Void in
            print(error)
        }
        
    }
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
        let placeMarker = marker as! PlaceMarker
        
        if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
            infoView.nameLabel.text = placeMarker.place.name
            
            if let photo = placeMarker.place.photo {
                infoView.placePhoto.image = photo
            } else {
                infoView.placePhoto.image = UIImage(named: "button_compass_night.png")
            }
            
            if let ratingPhoto = placeMarker.place.ratingPhoto {
                infoView.ratingPhoto.image = ratingPhoto
            } else {
                infoView.ratingPhoto.image = UIImage(named: "button_compass_night.png")
            }
            
            return infoView
        } else {
            return nil
        }
    }
    
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        return false
    }
    
    func didTapMyLocationButtonForMapView(mapView: GMSMapView!) -> Bool {
        mapView.selectedMarker = nil
        return false
    }
}


