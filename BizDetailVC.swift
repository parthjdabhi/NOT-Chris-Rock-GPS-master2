//
//  BizDetailVC.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 10/14/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol BusinessViewDelegate: class {
    func businessView(onBackTapped businessViewController:BizDetailVC)
}

class BizDetailVC: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    @IBOutlet weak var reviewsLabel: UILabel!
    @IBOutlet weak var reviewsImage: UIImageView!
    @IBOutlet weak var orderNowButton: UIButton!
    @IBOutlet weak var makeReservationButton: UIButton!
    @IBOutlet weak var reviewsTable: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var business: Business!
    var delegate: BusinessViewDelegate?
    
    var locationManager : CLLocationManager!
    var locationIsSet = false
    var zoomIsSet = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.mapView.userLocation.addObserver(self, forKeyPath: "location", options: NSKeyValueObservingOptions.init(rawValue: 0), context: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.mapView.userLocation.removeObserver(self, forKeyPath: "location")
    }
    
    override func viewDidAppear(animated: Bool) {
        if locationIsSet == false {
            goToLocation(CLLocation(latitude: business.latitude!, longitude: business.longitude!))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topImageView.sd_setImageWithURL(business.imageURL!)
        
        let contentWidth = scrollView.bounds.width
        let contentHeight = scrollView.bounds.height * 3
        scrollView.contentSize = CGSizeMake(contentWidth, contentHeight)
        
        makeReservationButton.setCornerRadious()
        makeReservationButton.setBorder(1.0, color: clrOrange)
        orderNowButton?.setCornerRadious()
        orderNowButton?.setBorder(1.0, color: clrGreen)
        
        // UI Setup
        nameLabel.text = business.name!
        distanceLabel.text = business.distance!
        categoriesLabel.text = business.categories!
        reviewsLabel.text = "\(business.reviewCount!) Reviews"
        topImageView.sd_setImageWithURL(business.imageURL!)
        reviewsImage.sd_setImageWithURL(business.ratingImageURL!)
        
        setDisabledBackgroundColorForButton(orderNowButton)
        setDisabledBackgroundColorForButton(makeReservationButton)
        
        if (business.eat24Url != nil) {
            orderNowButton.enabled = true
        } else {
            orderNowButton.enabled = false
        }
        
        if (business.reservationURL != nil) {
            makeReservationButton.enabled = true
        } else {
            makeReservationButton.enabled = false
        }
        
        // Nav setup
//        let backButton = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(BusinessViewController.backTapped))
//        backButton.tintColor = UIColor.whiteColor()
//        navigationItem.leftBarButtonItem = backButton
        
        // Map setup
        locationManager = CLLocationManager()
        //locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 200
        locationManager.requestWhenInUseAuthorization()
        
        addAnnotationAtCoordination(self.business)
        
        // Review Table setup
        let nib = UINib(nibName: "ReviewTableCell", bundle: nil)
        self.reviewsTable.registerNib(nib, forCellReuseIdentifier: "reviewCell")
        self.reviewsTable.estimatedRowHeight = 104
        self.reviewsTable.rowHeight = UITableViewAutomaticDimension
        
        reviewsTable.dataSource = self
        makeBusinessRequestWithId(business.id!)
    }
    
    @IBAction func goBackButtonPressed(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func orderNowTapped(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(business.eat24Url!)
    }
    
    @IBAction func onReservationTapped(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(business.reservationURL!)
    }
    
    func addAnnotationAtCoordination(business:Business) {
        let coordinate = CLLocationCoordinate2D(latitude: business.latitude!, longitude: business.longitude!)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func backTapped() {
        //delegate?.businessView(onBackTapped: self)
    }
    
    func makeBusinessRequestWithId(id:String) {
        Business.businessWithId(id) { (business: Business!, error: NSError!) in
            self.business.reviews = business.reviews
            self.reviewsTable.reloadData()
        }
    }
    
    func goToLocation(location: CLLocation) {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(region, animated: false)
    }
    
    func setZoom() {
        let currentLocationAnnotation = mapView.userLocation
        let mapAnnotations = NSArray.init(array: mapView.annotations)
        let finalArray = mapAnnotations.arrayByAddingObject(currentLocationAnnotation)
        mapView.showAnnotations(finalArray as! [MKAnnotation], animated: false)
        zoomIsSet = true
    }
    
    func setDisabledBackgroundColorForButton(button: UIButton) {
        let rect = CGRectMake(0, 0, button.frame.width,button.frame.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColor(context, CGColorGetComponents(UIColor.lightGrayColor().CGColor))
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        button.setBackgroundImage(image, forState: .Disabled)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "location" && !zoomIsSet {
            setZoom()
        }
    }
}

extension BizDetailVC: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.business.reviews?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = reviewsTable.dequeueReusableCellWithIdentifier("reviewCell") as! ReviewTableCell
        cell.initializeCell(self.business.reviews![indexPath.row])
        return cell
    }
}

extension BizDetailVC: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapView.showsUserLocation = true
        locationIsSet = true
    }
}


