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
import SVProgressHUD

class MainViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK: -
    // MARK: Vars
    //@IBOutlet var googleMapsView: GMSMapView!
    @IBOutlet var googleMVContainer: UIView!
    @IBOutlet weak var btnRefreshNearByPlace: UIButton!
    @IBOutlet weak var btnDirection: UIButton!
    @IBOutlet var btnMenu: UIButton?
    @IBOutlet weak var searchBar: UISearchBar!
    
    //var searchBar: UISearchBar!
    var myTimer = NSTimer()
    
    var googleMapsView: GMSMapView!
    var searchResultController: SearchResultsController!
    //var locationManager = CLLocationManager()
    
    //To Store Food places
    var currentBizMarker:[BizMarker] = []
    var selectedBizMarker:BizMarker?
    
    // MARK: -
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        isEnableFivetapGesture = true
        startFiveTapGesture()
        self.btnDirection.hidden = true
        
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
                self.doSearch()
            }
        } else {
            self.googleMapsView.animateToCameraPosition(GMSCameraPosition(target: CLocation!.coordinate, zoom: 15, bearing: 0, viewingAngle: 0))
            //For Search Via Yelp
            doSearch()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueFilter" {
            let navController = segue.destinationViewController as! UINavigationController
            let filtersVC = navController.topViewController as! FiltersViewController
            filtersVC.delegate = self
            filtersVC.filterObject = Myfilters
        }
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
    
    @IBAction func actionDoRouteForBiz(sender: AnyObject) {
        guard let myBizMarker = selectedBizMarker else {
            return
        }
        print("\(myBizMarker.biz.address)")
        let getDirectionVC = self.storyboard?.instantiateViewControllerWithIdentifier("GetDirectionVC") as! GetDirectionVC
        getDirectionVC.bizForRoute = myBizMarker.biz
        self.navigationController?.pushViewController(getDirectionVC, animated: true)
    }
    
    @IBAction func actionRefreshNearByPlace(sender: AnyObject)
    {
        //For Search Via Yelp
        //showNearByPlace(["food"])
        doSearch()
    }
    
    // MARK: - GMSMapViewDelegate
    
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        print(position.target)
    }
    
    func mapView(mapView: GMSMapView, willMove gesture: Bool) {
        if (gesture) {
            mapView.selectedMarker = nil
            self.btnDirection.hidden = true
        }
    }
    
    func mapView(mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        let placeMarker = marker as! BizMarker
        selectedBizMarker = placeMarker
        self.btnDirection.hidden = false
        
        if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
            infoView.nameLabel.text = placeMarker.biz.name
            infoView.lblReviewCount.text = placeMarker.biz.reviewCount?.stringValue ?? ""
            
            if let photo = placeMarker.biz.photo {
                infoView.placePhoto.image = photo
            } else {
                infoView.placePhoto.image = UIImage(named: "button_compass_night.png")
            }
            
            if let ratingPhoto = placeMarker.biz.ratingPhoto {
                infoView.ratingPhoto.image = ratingPhoto
            } else {
                infoView.ratingPhoto.image = UIImage(named: "button_compass_night.png")
            }
            
            infoView.btnGetRoute.addTarget(self, action: #selector(MainViewController.doRouteForBiz), forControlEvents: .TouchUpInside)
            //let biz: Business
            
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
        self.btnDirection.hidden = true
        return false
    }
    
    func doRouteForBiz() {
        print("Draw route")
    }
    
    // Perform the search.
    private func doSearch() {
        // Perform request to Yelp API to get the list of businessees
        guard let client = YelpClient.sharedInstance else { return }
        SVProgressHUD.showWithStatus("Searching..")
        client.location = "\(LocationManager.sharedInstance.latitude),\(LocationManager.sharedInstance.longitude)"
        client.searchWithTerm(searchString, sort: Myfilters.sortBy, categories: Myfilters.categories, deals: Myfilters.hasDeal, completion: { (business, error) in
            self.removeMarkers(self.currentBizMarker)
            businessArr = business
            for biz: Business in businessArr! {
                let marker = BizMarker(biz: biz)
                self.currentBizMarker.append(marker)
                marker.map = self.googleMapsView
            }
            
            SVProgressHUD.dismiss()
        })
    }
    
    func removeMarkers(marker:[GMSMarker]) {
        for cBizMarker in self.currentBizMarker {
            cBizMarker.map = nil
        }
        self.currentBizMarker.removeAll()
    }
}


extension MainViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true;
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        return true;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        searchString = ""
        searchBar.resignFirstResponder()
        doSearch()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchString = searchBar.text!
        searchBar.resignFirstResponder()
        doSearch()
    }
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        myTimer.invalidate()
        searchString = searchText
        myTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(MainViewController.searchInTime), userInfo: nil, repeats: false)
    }
    func searchInTime(){
        doSearch()
    }
    
}

extension MainViewController: FiltersViewControllerDelegate {
    func filtersViewControllerDelegate(filtersViewController: FiltersViewController, didSet filters: Filters) {
        Myfilters = filters
        doSearch()
    }
}
// Model class that represents the user's search settings
@objc class YelpSearchInfo: NSObject {
    var searchString: String?
    override init() {
        searchString = ""
    }
    
}

