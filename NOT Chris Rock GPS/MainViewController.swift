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

class MainViewController: UIViewController,PulleyPrimaryContentControllerDelegate , GMSMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: -
    // MARK: Vars
    //@IBOutlet var googleMapsView: GMSMapView!
    @IBOutlet var googleMVContainer: UIView!
    @IBOutlet weak var btnRefreshNearByPlace: UIButton!
    @IBOutlet weak var btnDirection: UIButton!
    @IBOutlet var btnMenu: UIButton?
    @IBOutlet var btnFilter: UIButton?
    @IBOutlet var btnBizList: UIButton?
    @IBOutlet weak var searchBar: UISearchBar!
    //@IBOutlet weak var tblBizList: UITableView!
    
    var searchResultController:BizSearchController!
    //var searchBar: UISearchBar!
    var myTimer = NSTimer()
    
    var googleMapsView: GMSMapView!
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
        //self.btnDirection.hidden = true
        
        searchResultController = BizSearchController()
        //searchResultController.delegate = self
        
        btnRefreshNearByPlace.setCornerRadious()
        btnRefreshNearByPlace.setBorder(1.0, color: clrGreen)
        btnDirection.setCornerRadious()
        btnDirection.setBorder(1.0, color: clrGreen)
        btnBizList?.setCornerRadious()
        btnBizList?.setBorder(1.0, color: clrGreen)
        
        // Init menu button action for menu
        if let revealVC = self.revealViewController() {
            self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
            //self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
            //self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
        
//        tblBizList.alpha = 0
//        tblBizList.hidden = true
//        self.tblBizList.registerNib(UINib(nibName: "BusinessTableViewCell", bundle: nil), forCellReuseIdentifier: "BusinessTableViewCell")
//        self.tblBizList.rowHeight = 94
        
        googleMVContainer.layoutIfNeeded()
        var frameMV = googleMVContainer.frame
        frameMV.origin.y = 0
        googleMapsView = GMSMapView(frame: frameMV)
        self.googleMVContainer.insertSubview(self.googleMapsView, atIndex: 0)
        
        //Map View
        GMSServices.provideAPIKey(googleMapsApiKey)
        self.googleMapsView.delegate = self
        self.googleMapsView.myLocationEnabled = true
        self.googleMapsView.settings.myLocationButton = true
        //self.googleMapsView.addObserver(self, forKeyPath: "myLocation", options: .New, context: nil)
        dispatch_async(dispatch_get_main_queue(), {
            self.googleMapsView.myLocationEnabled = true;
        });
        
        if LocationManager.sharedInstance.hasLastKnownLocation == false {
            LocationManager.sharedInstance.onFirstLocationUpdateWithCompletionHandler { (latitude, longitude, status, verboseMessage, error) in
                print(latitude,longitude,status)
                CLocation = CLLocation(latitude: latitude, longitude: longitude)
                self.googleMapsView.camera = GMSCameraPosition(target: CLocation!.coordinate, zoom: 16, bearing: 0, viewingAngle: 0)
                //self.googleMapsView.animateToCameraPosition(GMSCameraPosition(target: CLocation!.coordinate, zoom: 16, bearing: 0, viewingAngle: 0))
                //For Search Via Yelp
                //self.doSearch()
            }
        } else {
            self.googleMapsView.camera = GMSCameraPosition(target: CLocation!.coordinate, zoom: 16, bearing: 0, viewingAngle: 0)
            //For Search Via Yelp
            //doSearch()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        //navFilter
//        if segue.identifier == "segueFilter" {
//            let navController = segue.destinationViewController as! UINavigationController
//            let filtersVC = navController.topViewController as! FiltersViewController
//            filtersVC.delegate = self
//            filtersVC.filterObject = Myfilters
//        }
    }
    
    
    // MARK: - PulleyPrimaryContentControllerDelegate
    func onRequestRouteForBusiness(biz: Business)
    {
        let getDirectionVC = self.storyboard?.instantiateViewControllerWithIdentifier("GetDirectionVC") as! GetDirectionVC
        getDirectionVC.bizForRoute = biz
        self.navigationController?.pushViewController(getDirectionVC, animated: true)
    }
    
    func onBusinessSearchResult(bizs: [Business])
    {
        self.removeMarkers(self.currentBizMarker)
        businessArr = bizs
        
        for biz: Business in businessArr! {
            let marker = BizMarker(biz: biz)
            self.currentBizMarker.append(marker)
            marker.map = self.googleMapsView
        }
    }
    
    // MARK: -
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if change![NSKeyValueChangeOldKey] == nil
        {
            //print("observeValueForKeyPath : ",change)
            if let location = change?[NSKeyValueChangeNewKey] as? CLLocation {
                self.googleMapsView.animateToCameraPosition(GMSCameraPosition(target: location.coordinate, zoom: self.googleMapsView.camera.zoom, bearing: 0, viewingAngle: 0))
                if let LastLoc = LastSearchLocation where LastLoc.distanceFromLocation(location) > 50 {
                    print("distanceFromLocation : ",LastLoc.distanceFromLocation(location))
                    self.doSearch(false)
                }
            }
        } else {
            //super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
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
    
    //Filter or Show Map Screen
    @IBAction func actionFilter(sender: AnyObject)
    {
//        if self.tblBizList.hidden == false {
//            UIView.animateWithDuration(0.5, animations: {
//                self.tblBizList.alpha = 0
//                }, completion: { (completed) in
//                    self.tblBizList.hidden = true
//                    self.btnFilter?.setTitle("Filter", forState: .Normal)
//            })
//            return
//        }
        
        let navController = self.storyboard?.instantiateViewControllerWithIdentifier("navFilter") as! UINavigationController
        let filtersVC = navController.topViewController as! FiltersViewController
        filtersVC.delegate = self
        filtersVC.filterObject = Myfilters
        self.presentViewController(navController, animated: true) { 
            print("Finished")
        }
    }
    
    @IBAction func actionViewBusinessList(sender: AnyObject)
    {
//        if self.tblBizList.hidden == true {
//            self.tblBizList.reloadData()
//            self.tblBizList.hidden = false
//            UIView.animateWithDuration(0.5, animations: {
//                self.tblBizList.alpha = 1
//            })
//            self.btnFilter?.hidden = false
//            self.btnFilter?.setTitle("Map", forState: .Normal)
//        } else {
//            
//        }
    }
    @IBAction func actionDoRouteForBiz(sender: AnyObject?) {
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
        //For Search Via Yelp                   //showNearByPlace(["food"])
        doSearch()
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return businessArr?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessTableViewCell", forIndexPath: indexPath) as! BusinessTableViewCell
        cell.business = businessArr![indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        print("Selcted business")
    }
    
    // MARK: - GMSMapViewDelegate
    
    func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
        print(position.target)
    }
    
    func mapView(mapView: GMSMapView, willMove gesture: Bool) {
        if (gesture) {
            mapView.selectedMarker = nil
            //self.btnDirection.hidden = true
        }
    }
    
    func mapView(mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
        
        let placeMarker = marker as! BizMarker
        selectedBizMarker = placeMarker
        //self.btnDirection.hidden = false
        
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
    
    func mapView(mapView: GMSMapView, didLongPressInfoWindowOfMarker marker: GMSMarker) {
        self.actionDoRouteForBiz(nil)
    }
    
    func mapView(mapView: GMSMapView, didCloseInfoWindowOfMarker marker: GMSMarker) {
        //mapView.selectedMarker = nil
        //self.btnDirection.hidden = true
    }
    
    func didTapMyLocationButtonForMapView(mapView: GMSMapView) -> Bool {
        return false
    }
    
    func doRouteForBiz() {
        print("Draw route")
    }
    
    // Perform the search.
    private func doSearch(showLoader:Bool = true)
    {
        // Perform request to Yelp API to get the list of businessees
        guard let client = YelpClient.sharedInstance else { return }
        
        if showLoader == true {
            SVProgressHUD.showWithStatus("Searching..")
        }
        
        LastSearchLocation = LocationManager.sharedInstance.CLocation
        client.location = "\(LocationManager.sharedInstance.latitude),\(LocationManager.sharedInstance.longitude)"
        client.searchWithTerm(searchString, sort: Myfilters.sortBy, categories: Myfilters.categories, deals: Myfilters.hasDeal, completion: { (business, error) in
            
            self.removeMarkers(self.currentBizMarker)
            businessArr = business
            //self.tblBizList.reloadData()
            
            for biz: Business in businessArr! {
                let marker = BizMarker(biz: biz)
                self.currentBizMarker.append(marker)
                marker.map = self.googleMapsView
            }
            
            SVProgressHUD.dismiss()
        })
    }
    
    private func doSearchSuggestion() {
        // Perform request to Yelp API to get the list of businessees
        guard let client = YelpClient.sharedInstance else { return }
        SVProgressHUD.showWithStatus("Searching..")
        client.location = "\(LocationManager.sharedInstance.latitude),\(LocationManager.sharedInstance.longitude)"
        client.searchWithTerm(searchString, completion: { (business, error) in
            //self.removeMarkers(self.currentBizMarker)
            //businessArr = business
//            for biz: Business in businessArr! {
//                let marker = BizMarker(biz: biz)
//                self.currentBizMarker.append(marker)
//                marker.map = self.googleMapsView
//            }
            
            self.searchResultController.reloadDataWithArray(business)
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
        if searchBar == self.searchBar {
            let searchController = UISearchController(searchResultsController: searchResultController)
            searchController.searchBar.delegate = self
            searchController.searchBar.text = self.searchBar.text
            //searchController.searchBar.showsSearchResultsButton = true
            self.presentViewController(searchController, animated: true, completion: nil)
            return false;
        }
        searchBar.setShowsCancelButton(true, animated: true)
        return true;
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        if let searchStr = searchBar.text {
            print(searchStr)
//            searchString = searchStr
            searchBar.resignFirstResponder()
//            doSearch()
            searchResultController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        //searchBar.setShowsCancelButton(false, animated: true)
        return true;
    }
    
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        print("Bookmark")
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        searchString = ""
        searchBar.resignFirstResponder()
        //doSearchSuggestion()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchString = searchBar.text!
        searchBar.resignFirstResponder()
        //doSearchSuggestion()
        self.searchBar.text = searchString
        doSearch()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        myTimer.invalidate()
        searchString = searchText
        myTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(MainViewController.searchInTime), userInfo: nil, repeats: false)
    }
    
    func searchInTime(){
        doSearchSuggestion()
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

