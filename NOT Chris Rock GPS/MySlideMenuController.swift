//
//  MySlideMenuController.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/29/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SWRevealViewController
import FBSDKLoginKit

enum LeftMenu: Int {
    case Main = 0
    case Watchlist
    case What2watch
    case ImproveAccu
    case ShareWat2Watch
}

protocol LeftMenuProtocol : class {
    func changeViewController(menu: LeftMenu)
}

class MySlideMenuController : UIViewController {
    
    @IBOutlet weak var txtSearchbar: UITextField?
    @IBOutlet weak var btnSearch: UIButton?
    @IBOutlet weak var imgProfile: UIImageView?
    @IBOutlet weak var lblName: UILabel?
    @IBOutlet weak var lblWachCount: UILabel?
    @IBOutlet weak var lblTimeWaste: UILabel?
    
    @IBOutlet weak var btnMainScreen: UIButton!
    @IBOutlet weak var btnLogout: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        isEnableFivetapGesture = true
        startFiveTapGesture()
        
        imgProfile?.layer.cornerRadius = (imgProfile?.frame.width ?? 1) / 2
        imgProfile?.layer.borderWidth = 3
        imgProfile?.layer.masksToBounds = true
        imgProfile?.layer.borderColor = clrGreen.CGColor
        
        btnLogout.layer.borderWidth = 1
        btnLogout.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).CGColor
        
        
        self.lblName?.text = "asd asd asd asd"
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MySlideMenuController.MyProfile))
        lblName?.addGestureRecognizer(tap)
        lblName?.userInteractionEnabled = true
        
        imgProfile?.setCornerRadious(imgProfile!.frame.width/2)
        if let user = NSUserDefaults.standardUserDefaults().objectForKey("userDetail") as? NSDictionary {
            print(user)
            lblName?.text = "Hello, \(user["name"] as? String ?? "")"
            imgProfile?.sd_setImageWithURL(NSURL(string: user["profile_pic"] as? String ?? ""), placeholderImage: UIImage(named: "user.png"))
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        RefreshProfiledata()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    func MyProfile() {
        view.endEditing(true)
        self.actionMyProfile(nil)
    }
    
    func RefreshProfiledata()
    {
        
    }
    
    @IBAction func actionMyProfile(sender: AnyObject?) {
        //self.performSegueWithIdentifier("segueMyProfile", sender: self)
    }
    
    @IBAction func actionFindPlace(sender: AnyObject) {
        //self.performSegueWithIdentifier("segueMainScreen", sender: self)
    }
    
    @IBAction func actionMainScreen(sender: AnyObject) {
        self.performSegueWithIdentifier("segueMainScreen", sender: self)
    }
    
    @IBAction func actionDirection(sender: AnyObject) {
        self.performSegueWithIdentifier("segueDirection", sender: self)
    }
    
    @IBAction func actionAboutApp(sender: AnyObject) {
        //self.performSegueWithIdentifier("segueAboutApp", sender: self)
    }
    
    @IBAction func actionHelp(sender: AnyObject) {
        //self.performSegueWithIdentifier("segueHelp", sender: self)
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
            
            //self.performSegueWithIdentifier("segueMainScreen", sender: self)
            let navLogin = self.storyboard?.instantiateViewControllerWithIdentifier("SignInViewController") as! SignInViewController
            self.navigationController?.setViewControllers([navLogin], animated: true)
        }))
        
        presentViewController(actionSheetController, animated: true, completion: nil)
    }
}

