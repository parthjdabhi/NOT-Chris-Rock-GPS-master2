//
//  ViewController.swift
//  Pulley
//
//  Created by Brendan Lee on 7/6/16.
//  Copyright © 2016 52inc. All rights reserved.
//

import UIKit
import MapKit

class PrimaryContentViewController: UIViewController, PulleyPrimaryContentControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var controlsContainer: UIView!
    @IBOutlet var temperatureLabel: UILabel!
    
    @IBOutlet var temperatureLabelBottomConstraint: NSLayoutConstraint!
    
    private let temperatureLabelBottomDistance: CGFloat = 8.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        controlsContainer.layer.cornerRadius = 10.0
        temperatureLabel.layer.cornerRadius = 7.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        Uncomment if you want to change the visual effect style to dark. Note: The rest of the sample app's UI isn't made for dark theme. This just shows you how to do it.
//        if let drawer = self.parent as? PulleyViewController
//        {
//            drawer.drawerBackgroundVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func makeUIAdjustmentsForFullscreen(progress: CGFloat)
    {
        controlsContainer.alpha = 1.0 - progress
    }
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat)
    {
        if distance <= 268.0
        {
            temperatureLabelBottomConstraint.constant = distance + temperatureLabelBottomDistance
        }
        else
        {
            temperatureLabelBottomConstraint.constant = 268.0 + temperatureLabelBottomDistance
        }
    }
    
    func PushBusinessDirection(business:Business)
    {
        let getDirectionVC = self.storyboard?.instantiateViewControllerWithIdentifier("GetDirectionVC") as! GetDirectionVC
        getDirectionVC.bizForRoute = business
        self.navigationController?.pushViewController(getDirectionVC, animated: true)
    }
    
    @IBAction func runPrimaryContentTransitionWithoutAnimation(sender: AnyObject) {
        
        if let drawer = self.parentViewController as? PulleyViewController
        {
            let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PrimaryTransitionTargetViewController")
            
            drawer.setPrimaryContentViewController(primaryContent, animated: false)
        }
    }
    
    @IBAction func runPrimaryContentTransition(sender: AnyObject) {
        
        if let drawer = self.parentViewController as? PulleyViewController
        {
            let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PrimaryTransitionTargetViewController")
            
            drawer.setPrimaryContentViewController(primaryContent, animated: true)
        }
    }
    
}

