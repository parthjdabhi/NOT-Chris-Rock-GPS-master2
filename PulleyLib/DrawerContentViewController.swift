//
//  DrawerPreviewContentViewController.swift
//  Pulley
//
//  Created by Brendan Lee on 7/6/16.
//  Copyright © 2016 52inc. All rights reserved.
//

import UIKit
import SVProgressHUD
import KDEAudioPlayer

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
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector : #selector(DrawerContentViewController.keyboardWillShow(_:)), name : UIKeyboardDidShowNotification, object : nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK:- Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        if let drawerVC = self.parentViewController?.parentViewController as? PulleyViewController {
            drawerVC.setDrawerPosition(.open, animated: true)
        }
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
        
//        if let drawer = self.parentViewController?.parentViewController as? PulleyViewController
//        {
//            drawer.onRequestRouteForBusiness(businessList![indexPath.row])
//            return
//        }
        
        let bizDetailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("BizDetailVC") as? BizDetailVC
        bizDetailVC?.business = businessList![indexPath.row]
        self.navigationController?.pushViewController(bizDetailVC!, animated: true)
        //self.performSegueWithIdentifier("segueBizDetail", sender: self)
        
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
        
        if let drawerVC = self.parentViewController?.parentViewController as? PulleyViewController
        {
            //drawerVC.setDrawerPosition(.open, animated: false)
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
        if let drawerVC = self.parentViewController?.parentViewController as? PulleyViewController
        {
            //drawerVC.setDrawerPosition(.collapsed, animated: true)
        }
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        if let drawerVC = self.parentViewController?.parentViewController as? PulleyViewController
        {
            drawerVC.setDrawerPosition(.open, animated: true)
        }
        
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
        myTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(MainViewController.searchInTime), userInfo: nil, repeats: false)
    }
    
    func searchInTime() {
        print("Serch string with time :: for search string -- \(searchString) --")
        //doSearch()
    }
    
    // MARK: Search.
    private func doSearch(showLoader:Bool = true)
    {
        //doCheckFoodSoundForSearchTerm()
        //StartPlaying()
        
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
            
            if let drawer = self.parentViewController?.parentViewController as? PulleyViewController
            {
                drawer.onBusinessSearchResult(self.businessList ?? [])
            }
            
            if business.count == 0 {
                SVProgressHUD.showInfoWithStatus("No results found!")
                
                self.doPlaySoundForSearchResult()
                //7) When a search does not show a restaurant that was SPECIFICALLY searched for, play food-stmt6.wav.
                
            } else {
                SVProgressHUD.dismiss()
                self.doPlaySoundForSearchResult()
            }
            
        })
        
    }
    
    func doPlaySoundForSearchResult()
    {
        //Clear all pending audio items
        AudioItems?.removeAll()
        
        
        
        // -- Playing Sequence --
        //foodstmt4-pt1_ifound.wav
        //Number
        //foodstmt4-pt2_places.wav
        //foodstmt4-pt3_for.wav
        //Restaurent name
        //foodstmt4-pt5_checkthemout.wav
        
        
        if self.businessList?.count == 0 {
            //Audio: Audio For No Business found
            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("foodstmt4-pt2_places", withExtension: "wav")!.absoluteString)
            
            StartPlaying()
            
        } else if self.businessList?.count == 1 {
            //Audio: i Founds
            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("foodstmt4-pt1_ifound", withExtension: "wav")!.absoluteString)
            
            //Number
            doPlaySoundForBusnessCount()
            
            //Audio: Restaurant name
            doCheckFoodSoundForSearchTerm()
            
            StartPlaying()
        } else {
            //Audio: i Founds
            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("foodstmt4-pt1_ifound", withExtension: "wav")!.absoluteString)
            
            //Number
            doPlaySoundForBusnessCount()
            
            //Audio: Place called
            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("foodstmt4-pt2_places", withExtension: "wav")!.absoluteString)
            
            //Play only if restaurants name is founds -- "called papa jones check 'em out"
            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("foodstmt4-pt3_for", withExtension: "wav")!.absoluteString)
            
            //Audio: Restaurant name
            doCheckFoodSoundForSearchTerm()
            
            //Audio: Check 'em out
            self.AddAudioToQueue(ofUrl: NSBundle.mainBundle().URLForResource("foodstmt4-pt5_checkthemout", withExtension: "wav")!.absoluteString)
            
            StartPlaying()
        }
        
        
    }
    
    func doPlaySoundForBusnessCount()
    {
        // Number Statements
        self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/\((self.businessList?.count ?? 0)!).wav")
    }
    
    func doCheckFoodSoundForSearchTerm()
    {
        let inst = searchString ?? ""
        
        // Food store name
        if inst.containsIgnoringCase("5 Guys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/5-guys.wav")
        }
        else if inst.containsIgnoringCase("7/11") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/7-11.wav")
        }
        else if inst.containsIgnoringCase("A&W") || inst.containsIgnoringCase("A W") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/a&w.wav")
        }
        else if inst.containsIgnoringCase("Applebees") || inst.containsIgnoringCase("Applebee") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        else if inst.containsIgnoringCase("Arbys") || inst.containsIgnoringCase("Arby") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/arbys.wav")
        }
        else if inst.containsIgnoringCase("Backyard Burgers") || inst.containsIgnoringCase("Backyard Burger") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/backyardburgers.wav")
        }
        else if inst.containsIgnoringCase("Bakers Dozen Donuts") || inst.containsIgnoringCase("Bakers Dozen Donut") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bakers-dozen-donuts.wav")
        }
        else if inst.containsIgnoringCase("Bar-B-Cutie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bar-b-cutie.wav")
        }
        else if inst.containsIgnoringCase("Bar Burrito") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/barburrito.wav")
        }
        else if inst.containsIgnoringCase("Baskin Robbins") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/baskin-robbins.wav")
        }
        else if inst.containsIgnoringCase("Beaver Tails") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/beavertails.wav")
        }
        else if inst.containsIgnoringCase("Ben & Florentine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-florentine.wav")
        }
        else if inst.containsIgnoringCase("Ben & Jerrys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-jerrys.wav")
        }
        else if inst.containsIgnoringCase("Benjys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/benjys.wav")
        }
        else if inst.containsIgnoringCase("Big Boy") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/big-boy.wav")
        }
        else if inst.containsIgnoringCase("BJs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bjs.wav")
        }
        else if inst.containsIgnoringCase("Blimpie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/blimpie3.wav")
        }
        else if inst.containsIgnoringCase("Bob Evans") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bob-evans.wav")
        }
        else if inst.containsIgnoringCase("Bojangles") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bojangles.wav")
        }
        else if inst.containsIgnoringCase("Bonefish Grill") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bonefish-grill.wav")
        }
        else if inst.containsIgnoringCase("Booster-Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/booster-juice.wav")
        }
        else if inst.containsIgnoringCase("Boston Market") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-market.wav")
        }
        else if inst.containsIgnoringCase("Boston Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-pizza.wav")
        }
        else if inst.containsIgnoringCase("Burger Baron") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-baron.wav")
        }
        else if inst.containsIgnoringCase("Burger King") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-king.wav")
        }
        else if inst.containsIgnoringCase("BW3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/BW3.wav")
        }
        else if inst.containsIgnoringCase("C Lovers Fish-N-Chips") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/c-lovers-fish-n-chips.wav")
        }
        else if inst.containsIgnoringCase("Captain Ds Seafood") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Capt-Ds-Seafood.wav")
        }
        else if inst.containsIgnoringCase("Captain Submarine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/captain-submarine.wav")
        }
        else if inst.containsIgnoringCase("Captains Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/capts-sub.wav")
        }
        else if inst.containsIgnoringCase("Carls Jr") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carls-jr.wav")
        }
        else if inst.containsIgnoringCase("Carrabbas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carrabbas.wav")
        }
        else if inst.containsIgnoringCase("Checkers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/checkers.wav")
        }
        else if inst.containsIgnoringCase("Cheddars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheddars.wav")
        }
        else if inst.containsIgnoringCase("Cheesecake Factory") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheesecake-factory.wav")
        }
        else if inst.containsIgnoringCase("Chez Ashton") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chez-aston.wav")
        }
        else if inst.containsIgnoringCase("Chic-Fil-A") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chic-fil-a.wav")
        }
        else if inst.containsIgnoringCase("Chicken Cottage") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-cottage.wav")
        }
        else if inst.containsIgnoringCase("Chicken Delight") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-delight.wav")
        }
        else if inst.containsIgnoringCase("Chilis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chilis.wav")
        }
        else if inst.containsIgnoringCase("Chipotle") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chipotle.wav")
        }
        else if inst.containsIgnoringCase("Chuck-E-Cheese") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chuck-e-cheese.wav")
        }
        else if inst.containsIgnoringCase("Churchs Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/churchs-chicken.wav")
        }
        else if inst.containsIgnoringCase("Cicis Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cicis-pizza.wav")
        }
        else if inst.containsIgnoringCase("Cinnabun") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cinnabun.wav")
        }
        else if inst.containsIgnoringCase("Circle K") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/circle-k.wav")
        }
        else if inst.containsIgnoringCase("Coffee Time") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/coffeetime.wav")
        }
        else if inst.containsIgnoringCase("Cora") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cora.wav")
        }
        else if inst.containsIgnoringCase("Country Style") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/countrystyle.wav")
        }
        else if inst.containsIgnoringCase("Cows Ice Cream") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cows-ice-cream.wav")
        }
        else if inst.containsIgnoringCase("CPK") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cpk.wav")
        }
        else if inst.containsIgnoringCase("Cracker Barrel") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cracker-barrel.wav")
        }
        else if inst.containsIgnoringCase("Culvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/culvers.wav")
        }
        else if inst.containsIgnoringCase("Dairy Queen") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dairy-queen.wav")
        }
        else if inst.containsIgnoringCase("Del Taco") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/del-taco")
        }
        else if inst.containsIgnoringCase("Dennys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dennys.wav")
        }
        else if inst.containsIgnoringCase("Dic Anns Hamburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dic-ann-hamburgers.wav")
        }
        else if inst.containsIgnoringCase("Dixie Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-chicken.wav")
        }
        else if inst.containsIgnoringCase("Dixie Lee Fried Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-lee-fried-chicken.wav")
        }
        else if inst.containsIgnoringCase("Dominos") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dominos.wav")
        }
        else if inst.containsIgnoringCase("Donut Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/donut-diner.wav")
        }
        else if inst.containsIgnoringCase("Dunkin Donuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dunkin-donuts.wav")
        }
        else if inst.containsIgnoringCase("East Side Marios") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/east-side-marios.wav")
        }
        else if inst.containsIgnoringCase("Eat Restaurant") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/eat-restaurant.wav")
        }
        else if inst.containsIgnoringCase("Edo Japan") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/edo-japan.wav")
        }
        else if inst.containsIgnoringCase("Eds Easy Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        else if inst.containsIgnoringCase("eds-easy-diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        else if inst.containsIgnoringCase("Einstein Brothers Bagels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/einstein-bros-bagels.wav")
        }
        else if inst.containsIgnoringCase("Extreme Pita") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/extreme-pita.wav")
        }
        else if inst.containsIgnoringCase("Famous Daves") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/famous-daves.wav")
        }
        else if inst.containsIgnoringCase("Fast Eddies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fast-eddies.wav")
        }
        else if inst.containsIgnoringCase("Firehouse Subs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/firehouse-subs.wav")
        }
        else if inst.containsIgnoringCase("Friendlys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/friendlys.wav")
        }
        else if inst.containsIgnoringCase("Fryers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fryers.wav")
        }
        else if inst.containsIgnoringCase("Gojis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/gojis.wav")
        }
        else if inst.containsIgnoringCase("Golden Corral") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/golden-corral.wav")
        }
        else if inst.containsIgnoringCase("Greco Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/greco-pizza.wav")
        }
        else if inst.containsIgnoringCase("Hardees") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hardees.wav")
        }
        else if inst.containsIgnoringCase("Harveys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/harveys.wav")
        }
        else if inst.containsIgnoringCase("Heros Cert Burgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/heros-cert-burgers.wav")
        }
        else if inst.containsIgnoringCase("Ho Lee Chow") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ho-lee-chow.wav")
        }
        else if inst.containsIgnoringCase("Hooters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hooters.wav")
        }
        else if inst.containsIgnoringCase("Humptys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/humptys.wav")
        }
        else if inst.containsIgnoringCase("IHOP") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ihop.wav")
        }
        else if inst.containsIgnoringCase("In-And-Out-Burger") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/in-and-out-burger.wav")
        }
        else if inst.containsIgnoringCase("Jack In The Box") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jack-in-the-box.wav")
        }
        else if inst.containsIgnoringCase("Jamba Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jamba-juice.wav")
        }
        else if inst.containsIgnoringCase("Jasons Deli") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jasons-deli.wav")
        }
        else if inst.containsIgnoringCase("Jimmy Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-johns.wav")
        }
        else if inst.containsIgnoringCase("Jimmy The Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-the-greek.wav")
        }
        else if inst.containsIgnoringCase("Jugo Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jugo-juice.wav")
        }
        else if inst.containsIgnoringCase("Kaspas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kaspas.wav")
        }
        else if inst.containsIgnoringCase("KFC") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kfc.wav")
        }
        else if inst.containsIgnoringCase("Krispy Kreme Doughnuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krispy-kreme-dougnuts.wav")
        }
        else if inst.containsIgnoringCase("Krystal") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krystal.wav")
        }
        else if inst.containsIgnoringCase("Labelle Prov") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/labelle-prov.wav")
        }
        else if inst.containsIgnoringCase("Licks Homeburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/licks-homeburgers.wav")
        }
        else if inst.containsIgnoringCase("Little Caesars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-caesars.wav")
        }
        else if inst.containsIgnoringCase("Little Chef") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-chef.wav")
        }
        else if inst.containsIgnoringCase("Logans Roadhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/logans-roadhouse.wav")
        }
        else if inst.containsIgnoringCase("Long John Silvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/long-john-silvers.wav")
        }
        else if inst.containsIgnoringCase("Longhorn Steakhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/longhorn-steakhouse.wav")
        }
        else if inst.containsIgnoringCase("Macaroni") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/macaroni-grill.wav")
        }
        else if inst.containsIgnoringCase("Manchu Wok") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/manchu-wok.wav")
        }
        else if inst.containsIgnoringCase("Mary Browns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mary-browns.wav")
        }
        else if inst.containsIgnoringCase("McDonalds") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mcdonalds.wav")
        }
        else if inst.containsIgnoringCase("Millies Cookies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/millies-cookies.wav")
        }
        else if inst.containsIgnoringCase("Moes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/moes.wav")
        }
        else if inst.containsIgnoringCase("Morleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/morleys.wav")
        }
        else if inst.containsIgnoringCase("Mr. Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-greek.wav")
        }
        else if inst.containsIgnoringCase("Mr. Mikes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-mikes.wav")
        }
        else if inst.containsIgnoringCase("Mr. Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-sub.wav")
        }
        else if inst.containsIgnoringCase("NY Fries") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ny-fries.wav")
        }
        else if inst.containsIgnoringCase("Ocharleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Ocharleys.wav")
        }
        else if inst.containsIgnoringCase("Olive Garden") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/olive-garden.wav")
        }
        else if inst.containsIgnoringCase("On The Border") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/on-the-border.wav")
        }
        else if inst.containsIgnoringCase("Orange Julius") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/orange-julius.wav")
        }
        else if inst.containsIgnoringCase("Outback") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/outback.wav")
        }
        else if inst.containsIgnoringCase("Panago") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panago.wav")
        }
        else if inst.containsIgnoringCase("Panda Express") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panda-express.wav")
        }
        else if inst.containsIgnoringCase("Panera Bread") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panera-bread.wav")
        }
        else if inst.containsIgnoringCase("Papa Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/papa-johns.wav")
        }
    }
    
    func AddAudioToQueue(ofUrl url:String?)
    {
        print("AddAudioToQueue : \(url)")
        
        guard let urlString = url else {
            return
        }
        
        //var isFoundFromLocal = false
        if (urlString.containsIgnoringCase("http://")
            || urlString.containsIgnoringCase("https://"))
            && urlString.containsIgnoringCase(".wav")
        {
            print(urlString.substringWithLastInstanceOf("/"))
            if let soundName = urlString.substringWithLastInstanceOf("/")
                where NSBundle.mainBundle().URLForResource(soundName, withExtension: "wav") != nil
            {
                print(" Local Resource : - \(NSBundle.mainBundle().URLForResource(soundName, withExtension: "wav"))")
                if let AudioIdem = AudioItem(soundURLs: [AudioQuality.Medium : NSURL(string: NSBundle.mainBundle().URLForResource(soundName, withExtension: "wav")!.absoluteString)!]) {
                    AudioItems?.append(AudioIdem)
                }
                return
            }
            
        }
        
        if let mp3Url = NSURL(string: urlString) {
            //mp3Urls.append(mp3Url)
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
}
