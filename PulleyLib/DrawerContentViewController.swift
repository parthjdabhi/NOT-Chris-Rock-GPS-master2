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
        myTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(MainViewController.searchInTime), userInfo: nil, repeats: false)
    }
    
    func searchInTime() {
        doSearch()
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
            
            SVProgressHUD.dismiss()
            self.doPlaySoundForSearchResult()
        })
        
    }
    
    func doPlaySoundForSearchResult()
    {
        // -- Playing Sequence --
        //foodstmt4-pt1_ifound.wav
        //Number
        //foodstmt4-pt2_places.wav
        //foodstmt4-pt3_for.wav
        //Restaurent name
        //foodstmt4-pt5_checkthemout.wav
        
        let file1 = NSBundle.mainBundle().URLForResource("foodstmt4-pt1_ifound", withExtension: "wav")!
        let file2 = NSBundle.mainBundle().URLForResource("foodstmt4-pt2_places", withExtension: "wav")!
        let file3 = NSBundle.mainBundle().URLForResource("foodstmt4-pt3_for", withExtension: "wav")!
        let file4 = NSBundle.mainBundle().URLForResource("foodstmt4-pt5_checkthemout", withExtension: "wav")!
        
        
        self.AddAudioToQueue(ofUrl: file1.absoluteString)
        //Number
        doPlaySoundForBusnessCount()
        self.AddAudioToQueue(ofUrl: file2.absoluteString)
        self.AddAudioToQueue(ofUrl: file3.absoluteString)
        //Restaurent name
        doCheckFoodSoundForSearchTerm()
        self.AddAudioToQueue(ofUrl: file4.absoluteString)
        
        StartPlaying()
    }
    
    func doPlaySoundForBusnessCount()
    {
        // Number Statements
        self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)1-1000 Routespeak/\((self.businessList?.count ?? 0)!).wav")
    }
    
    func doCheckFoodSoundForSearchTerm()
    {
        let inst = searchString ?? ""
        // Food
        if inst.containsIgnoringCase("5 Guys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/5-guys.wav")
        }
        if inst.containsIgnoringCase("7/11") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/7-11.wav")
        }
        if inst.containsIgnoringCase("A&W") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/a&w.wav")
        }
        if inst.containsIgnoringCase("Applebees") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        if inst.containsIgnoringCase("Arbys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/arbys.wav")
        }
        if inst.containsIgnoringCase("Backyard Burgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/backyardburgers.wav")
        }
        if inst.containsIgnoringCase("Bakers Dozen Donuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bakers-dozen-donuts.wav")
        }
        if inst.containsIgnoringCase("Bar-B-Cutie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bar-b-cutie.wav")
        }
        if inst.containsIgnoringCase("Bar Burrito") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/barburrito.wav")
        }
        if inst.containsIgnoringCase("Baskin Robbins") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/baskin-robbins.wav")
        }
        if inst.containsIgnoringCase("Beaver Tails") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/beavertails.wav")
        }
        if inst.containsIgnoringCase("Ben & Florentine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-florentine.wav")
        }
        if inst.containsIgnoringCase("Ben & Jerrys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ben-and-jerrys.wav")
        }
        if inst.containsIgnoringCase("Benjys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/benjys.wav")
        }
        if inst.containsIgnoringCase("Big Boy") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/big-boy.wav")
        }
        if inst.containsIgnoringCase("BJs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bjs.wav")
        }
        if inst.containsIgnoringCase("Blimpie") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/blimpie3.wav")
        }
        if inst.containsIgnoringCase("Bob Evans") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bob-evans.wav")
        }
        if inst.containsIgnoringCase("Bojangles") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bojangles.wav")
        }
        if inst.containsIgnoringCase("Bonefish Grill") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/bonefish-grill.wav")
        }
        if inst.containsIgnoringCase("Booster-Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/booster-juice.wav")
        }
        if inst.containsIgnoringCase("Boston Market") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-market.wav")
        }
        if inst.containsIgnoringCase("Boston Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/boston-pizza.wav")
        }
        if inst.containsIgnoringCase("Burger Baron") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-baron.wav")
        }
        if inst.containsIgnoringCase("Burger King") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/burger-king.wav")
        }
        if inst.containsIgnoringCase("BW3") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/BW3.wav")
        }
        if inst.containsIgnoringCase("C Lovers Fish-N-Chips") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/c-lovers-fish-n-chips.wav")
        }
        if inst.containsIgnoringCase("Captain Ds Seafood") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Capt-Ds-Seafood.wav")
        }
        if inst.containsIgnoringCase("Captain Submarine") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/captain-submarine.wav")
        }
        if inst.containsIgnoringCase("Captains Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/capts-sub.wav")
        }
        if inst.containsIgnoringCase("Carls Jr") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carls-jr.wav")
        }
        if inst.containsIgnoringCase("Carrabbas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/carrabbas.wav")
        }
        if inst.containsIgnoringCase("Checkers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/checkers.wav")
        }
        if inst.containsIgnoringCase("Cheddars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheddars.wav")
        }
        if inst.containsIgnoringCase("Cheesecake Factory") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cheesecake-factory.wav")
        }
        if inst.containsIgnoringCase("Chez Ashton") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chez-aston.wav")
        }
        if inst.containsIgnoringCase("Chic-Fil-A") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chic-fil-a.wav")
        }
        if inst.containsIgnoringCase("Chicken Cottage") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-cottage.wav")
        }
        if inst.containsIgnoringCase("Chicken Delight") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chicken-delight.wav")
        }
        if inst.containsIgnoringCase("Chilis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chilis.wav")
        }
        if inst.containsIgnoringCase("Chipotle") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chipotle.wav")
        }
        if inst.containsIgnoringCase("Chuck-E-Cheese") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/chuck-e-cheese.wav")
        }
        if inst.containsIgnoringCase("Churchs Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/churchs-chicken.wav")
        }
        if inst.containsIgnoringCase("Cicis Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cicis-pizza.wav")
        }
        if inst.containsIgnoringCase("Cinnabun") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cinnabun.wav")
        }
        if inst.containsIgnoringCase("Circle K") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/circle-k.wav")
        }
        if inst.containsIgnoringCase("Coffee Time") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/coffeetime.wav")
        }
        if inst.containsIgnoringCase("Cora") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cora.wav")
        }
        if inst.containsIgnoringCase("Country Style") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/countrystyle.wav")
        }
        if inst.containsIgnoringCase("Cows Ice Cream") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cows-ice-cream.wav")
        }
        if inst.containsIgnoringCase("CPK") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cpk.wav")
        }
        if inst.containsIgnoringCase("Cracker Barrel") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/cracker-barrel.wav")
        }
        if inst.containsIgnoringCase("Culvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/culvers.wav")
        }
        if inst.containsIgnoringCase("Dairy Queen") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dairy-queen.wav")
        }
        if inst.containsIgnoringCase("Del Taco") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/del-taco")
        }
        if inst.containsIgnoringCase("Dennys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dennys.wav")
        }
        if inst.containsIgnoringCase("Dic Anns Hamburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dic-ann-hamburgers.wav")
        }
        if inst.containsIgnoringCase("Dixie Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-chicken.wav")
        }
        if inst.containsIgnoringCase("Dixie Lee Fried Chicken") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dixie-lee-fried-chicken.wav")
        }
        if inst.containsIgnoringCase("Dominos") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dominos.wav")
        }
        if inst.containsIgnoringCase("Donut Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/donut-diner.wav")
        }
        if inst.containsIgnoringCase("Dunkin Donuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/dunkin-donuts.wav")
        }
        if inst.containsIgnoringCase("East Side Marios") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/east-side-marios.wav")
        }
        if inst.containsIgnoringCase("Eat Restaurant") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/eat-restaurant.wav")
        }
        if inst.containsIgnoringCase("Edo Japan") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/edo-japan.wav")
        }
        if inst.containsIgnoringCase("Eds Easy Diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        if inst.containsIgnoringCase("eds-easy-diner") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/applebees.wav")
        }
        if inst.containsIgnoringCase("Einstein Brothers Bagels") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/einstein-bros-bagels.wav")
        }
        if inst.containsIgnoringCase("Extreme Pita") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/extreme-pita.wav")
        }
        if inst.containsIgnoringCase("Famous Daves") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/famous-daves.wav")
        }
        if inst.containsIgnoringCase("Fast Eddies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fast-eddies.wav")
        }
        if inst.containsIgnoringCase("Firehouse Subs") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/firehouse-subs.wav")
        }
        if inst.containsIgnoringCase("Friendlys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/friendlys.wav")
        }
        if inst.containsIgnoringCase("Fryers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/fryers.wav")
        }
        if inst.containsIgnoringCase("Gojis") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/gojis.wav")
        }
        if inst.containsIgnoringCase("Golden Corral") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/golden-corral.wav")
        }
        if inst.containsIgnoringCase("Greco Pizza") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/greco-pizza.wav")
        }
        if inst.containsIgnoringCase("Hardees") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hardees.wav")
        }
        if inst.containsIgnoringCase("Harveys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/harveys.wav")
        }
        if inst.containsIgnoringCase("Heros Cert Burgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/heros-cert-burgers.wav")
        }
        if inst.containsIgnoringCase("Ho Lee Chow") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ho-lee-chow.wav")
        }
        if inst.containsIgnoringCase("Hooters") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/hooters.wav")
        }
        if inst.containsIgnoringCase("Humptys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/humptys.wav")
        }
        if inst.containsIgnoringCase("IHOP") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ihop.wav")
        }
        if inst.containsIgnoringCase("In-And-Out-Burger") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/in-and-out-burger.wav")
        }
        if inst.containsIgnoringCase("Jack In The Box") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jack-in-the-box.wav")
        }
        if inst.containsIgnoringCase("Jamba Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jamba-juice.wav")
        }
        if inst.containsIgnoringCase("Jasons Deli") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jasons-deli.wav")
        }
        if inst.containsIgnoringCase("Jimmy Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-johns.wav")
        }
        if inst.containsIgnoringCase("Jimmy The Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jimmy-the-greek.wav")
        }
        if inst.containsIgnoringCase("Jugo Juice") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/jugo-juice.wav")
        }
        if inst.containsIgnoringCase("Kaspas") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kaspas.wav")
        }
        if inst.containsIgnoringCase("KFC") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/kfc.wav")
        }
        if inst.containsIgnoringCase("Krispy Kreme Doughnuts") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krispy-kreme-dougnuts.wav")
        }
        if inst.containsIgnoringCase("Krystal") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/krystal.wav")
        }
        if inst.containsIgnoringCase("Labelle Prov") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/labelle-prov.wav")
        }
        if inst.containsIgnoringCase("Licks Homeburgers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/licks-homeburgers.wav")
        }
        if inst.containsIgnoringCase("Little Caesars") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-caesars.wav")
        }
        if inst.containsIgnoringCase("Little Chef") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/little-chef.wav")
        }
        if inst.containsIgnoringCase("Logans Roadhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/logans-roadhouse.wav")
        }
        if inst.containsIgnoringCase("Long John Silvers") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/long-john-silvers.wav")
        }
        if inst.containsIgnoringCase("Longhorn Steakhouse") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/longhorn-steakhouse.wav")
        }
        if inst.containsIgnoringCase("Macaroni") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/macaroni-grill.wav")
        }
        if inst.containsIgnoringCase("Manchu Wok") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/manchu-wok.wav")
        }
        if inst.containsIgnoringCase("Mary Browns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mary-browns.wav")
        }
        if inst.containsIgnoringCase("McDonalds") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mcdonalds.wav")
        }
        if inst.containsIgnoringCase("Millies Cookies") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/millies-cookies.wav")
        }
        if inst.containsIgnoringCase("Moes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/moes.wav")
        }
        if inst.containsIgnoringCase("Morleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/morleys.wav")
        }
        if inst.containsIgnoringCase("Mr. Greek") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-greek.wav")
        }
        if inst.containsIgnoringCase("Mr. Mikes") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-mikes.wav")
        }
        if inst.containsIgnoringCase("Mr. Sub") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/mr-sub.wav")
        }
        if inst.containsIgnoringCase("NY Fries") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/ny-fries.wav")
        }
        if inst.containsIgnoringCase("Ocharleys") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/Ocharleys.wav")
        }
        if inst.containsIgnoringCase("Olive Garden") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/olive-garden.wav")
        }
        if inst.containsIgnoringCase("On The Border") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/on-the-border.wav")
        }
        if inst.containsIgnoringCase("Orange Julius") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/orange-julius.wav")
        }
        if inst.containsIgnoringCase("Outback") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/outback.wav")
        }
        if inst.containsIgnoringCase("Panago") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panago.wav")
        }
        if inst.containsIgnoringCase("Panda Express") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panda-express.wav")
        }
        if inst.containsIgnoringCase("Panera Bread") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/panera-bread.wav")
        }
        if inst.containsIgnoringCase("Papa Johns") {
            self.AddAudioToQueue(ofUrl: "\(BaseUrlSounds)Restaurants/papa-johns.wav")
        }
    }
    
    func AddAudioToQueue(ofUrl url:String)
    {
        print("AddAudioToQueue : \(url)")
        
        if let mp3Url = NSURL(string: url) {
            //            mp3Urls.append(mp3Url)
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
