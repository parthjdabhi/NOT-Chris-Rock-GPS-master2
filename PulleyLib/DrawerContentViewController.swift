//
//  DrawerPreviewContentViewController.swift
//  Pulley
//
//  Created by Brendan Lee on 7/6/16.
//  Copyright © 2016 52inc. All rights reserved.
//

import UIKit
import SVProgressHUD

class DrawerContentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PulleyDrawerViewControllerDelegate, UISearchBarDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var gripperView: UIView!
    
    @IBOutlet var seperatorHeightConstraint: NSLayoutConstraint!
    
    var myTimer = NSTimer()
    var businessList: [Business]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        gripperView.layer.cornerRadius = 2.5
        seperatorHeightConstraint.constant = 1.0 / UIScreen.mainScreen().scale
        
        self.tableView.registerNib(UINib(nibName: "BusinessTableViewCell", bundle: nil), forCellReuseIdentifier: "BusinessTableViewCell")
        self.tableView.rowHeight = 94
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Tableview data source & delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return businessList?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessTableViewCell", forIndexPath: indexPath) as! BusinessTableViewCell
        cell.business = businessList![indexPath.row]
        return cell
        //return tableView.dequeueReusableCellWithIdentifier("SampleCell", forIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 94.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
//        if let drawer = self.parentViewController as? PulleyViewController
//        {
//            let primaryContent = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("PrimaryTransitionTargetViewController")
//            drawer.setDrawerPosition(.collapsed, animated: true)
//            drawer.setPrimaryContentViewController(primaryContent, animated: false)
//        }
    }

    // MARK: Drawer Content View Controller Delegate
    
    func collapsedDrawerHeight() -> CGFloat
    {
        return 68.0
    }
    
    func partialRevealDrawerHeight() -> CGFloat
    {
        return 264.0
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.all // You can specify the drawer positions you support. This is the same as: [.open, .partiallyRevealed, .collapsed]
    }

    func drawerPositionDidChange(drawer: PulleyViewController)
    {
        tableView.scrollEnabled = drawer.drawerPosition == .open
        
        if drawer.drawerPosition != .open
        {
            searchBar.resignFirstResponder()
        }
    }
    
    // MARK: Search Bar delegate
    
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        searchBar.setShowsCancelButton(true, animated: true)
        
        if let drawerVC = self.parentViewController as? PulleyViewController
        {
            drawerVC.setDrawerPosition(.open, animated: false)
        }
        
        UIView.animateWithDuration(0.5, delay: 1.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            
        }) { (cmopleted) in
                
        }
        
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        //searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        print("Bookmark")
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        if let drawerVC = self.parentViewController as? PulleyViewController
        {
            drawerVC.setDrawerPosition(.open, animated: true)
        }
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
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
        doSearch()
    }
    
    // MARK: Search.
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
            
            self.businessList = business
            self.tableView.reloadData()
            
            SVProgressHUD.dismiss()
        })
    }
}
