//
//  SignInViewController.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/21/16.
//  Copyright © 2016 Harloch. All rights reserved.
//



import UIKit

import Alamofire
import SwiftyJSON
import SVProgressHUD
import FBSDKLoginKit
import FBSDKShareKit

class SignInViewController: UIViewController {
    
    // MARK: -
    // MARK: Vars
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtEmail: UITextField!
    
    var isRememberMe:String = "0"
    
    // MARK: -
    // MARK: Lifecycle
    override func viewDidLoad()
    {
        //self.startFiveTapGesture()
        
        txtEmail.setCornerRadious()
        txtPassword.setCornerRadious()
        txtEmail.setPlaceholderColor(UIColor.darkGrayColor())
        txtPassword.setPlaceholderColor(UIColor.darkGrayColor())
        txtEmail.setLeftMargin(8)
        txtPassword.setLeftMargin(8)
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    override func  preferredStatusBarStyle()-> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.Portrait
    }
    
    //override func shouldAutorotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation) -> Bool {
    //    return false//self.shouldAutorotateToInterfaceOrientation(toInterfaceOrientation)
    //}
    
    // MARK: -
    @IBAction func didTapForgotPwd(sender: AnyObject)
    {
        let vcForgotPwd = self.storyboard?.instantiateViewControllerWithIdentifier("ForgotPwdVC") as! ForgotPwdVC
        self.navigationController?.pushViewController(vcForgotPwd, animated: true)
    }
    
    @IBAction func didTapSignIn(sender: AnyObject)
    {
        //self.performSegueWithIdentifier("segueHome", sender: self)
        // Sign In with credentials.
        let email = txtEmail.text!
        let password = txtPassword.text!
        if email.isEmpty || password.isEmpty {
            SVProgressHUD.showImage((SVProgressHUD.sharedView().infoImage), status: "Invalid email or password!", displayInterval: 3)
            txtEmail.animateShakeEffect()
            txtPassword.animateShakeEffect()
        } else {
            DoLogin()
        }
    }
    
    func DoLogin()
    {
        let email = self.txtEmail.text!
        let password = self.txtPassword.text!
        // make sure the user entered both email & password
        if email != ""
            && password != ""
        {
            let Parameters = ["submitted" : "1",
                              "email" : email,
                              "password" : password]
            print(Parameters)
            SVProgressHUD.showWithStatus("Signing in..")
            
            Alamofire.request(.POST, url_login, parameters: Parameters)
                .validate()
                .responseJSON { response in
                    CommonUtils.sharedUtils.hideProgress()
                    switch response.result
                    {
                    case .Success(let data):
                        let json = JSON(data)
                        print(json.dictionary)
                        
                        if let status = json["status"].string,
                            result = json["result"].dictionaryObject
                            where status == "1"
                        {
                            print(json["msg"].string )
                            SVProgressHUD.showSuccessWithStatus(json["msg"].string ?? "Login successfully")
                            
                            
                            userDetail = result
                            NSUserDefaults.standardUserDefaults().setObject(result, forKey: "userDetail")
                            NSUserDefaults.standardUserDefaults().synchronize()
                            
                            //Go To Main Screen
                            self.performSegueWithIdentifier("segueHome", sender: nil)
                        }
                        else if let msg = json["msg"].string {
                            print(msg)
                            SVProgressHUD.showErrorWithStatus(msg)
                            self.navigationController?.popViewControllerAnimated(true)
                        } else {
                            SVProgressHUD.showErrorWithStatus("Unable to register!")    // error?.localizedDescription
                        }
                        //"status": 1, "result": , "msg": Registraion success! Please check your email for activation key.
                        
                    case .Failure(let error):
                        SVProgressHUD.showErrorWithStatus("Request failed!")
                        print("Request failed with error: \(error)")
                        //CommonUtils.sharedUtils.showAlert(self, title: "Error", message: (error?.localizedDescription)!)
                    }
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Enter email & password!", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
        }
    }
    
    
    @IBAction func onClickFacebookButton(sender: UIButton){
        let login = FBSDKLoginManager()
        login.loginBehavior = FBSDKLoginBehavior.SystemAccount
        login.logInWithReadPermissions(["public_profile", "email"], fromViewController: self, handler: {(result, error) in
            if error != nil {
                print("Error :  \(error.description)")
            }
            else if result.isCancelled {
                print("Login cancelled")
            }
            else {
                FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "first_name, last_name, picture.type(large), email, name, id, gender"]).startWithCompletionHandler({(connection, result, error) -> Void in
                    if error != nil{
                        print("Error : \(error.description)")
                    } else {
                        print("userInfo is \(result))")
                        
                        let facebookData = result as! NSDictionary //FACEBOOK DATA IN DICTIONARY
                        print("facebookData : \(facebookData)")
                        
                        var CUserDetail = [String: AnyObject]()
                        
                        if facebookData.objectForKey("name") != nil {
                            CUserDetail["name"] = (facebookData.objectForKey("name") as? String) ?? ""
                        }
                        if facebookData.objectForKey("email") != nil {
                            CUserDetail["email"] = (facebookData.objectForKey("email") as? String) ?? ""
                        }
                        if facebookData.objectForKey("id") != nil {
                            CUserDetail["fbid"] = (facebookData.objectForKey("id") as? String) ?? ""
                            CUserDetail["photo"] = NSURL(string: "http://graph.facebook.com/\(facebookData.objectForKey("id") as? String ?? "")/picture?type=large")
                        }
                        if facebookData.objectForKey("gender") != nil {
                            CUserDetail["gender"] = facebookData.objectForKey("gender") as? String ?? ""
                        }
                        if FBSDKAccessToken.currentAccessToken() != nil {
                            CUserDetail["FBAccessToken"] = FBSDKAccessToken.currentAccessToken().tokenString
                        } else {
                            CUserDetail["FBAccessToken"] = "0"
                        }
                        
                        CUserDetail["device_id"] = "0"
                        CUserDetail["device_type"] = "IOS"
                        
                        print(CUserDetail)
                        SVProgressHUD.showWithStatus("Signing in..")
                        
                        Alamofire.request(.POST, url_fb_register, parameters: CUserDetail)
                            .validate()
                            .responseJSON { response in
                                CommonUtils.sharedUtils.hideProgress()
                                switch response.result
                                {
                                case .Success(let data):
                                    let json = JSON(data)
                                    print(json.dictionary)
                                    
                                    if let status = json["status"].string,
                                        result = json["result"].dictionaryObject
                                        where status == "1"
                                    {
                                        print(json["msg"].string)
                                        
                                        if result["is_profile_updated"] as? Int ?? "" == 0 {
                                            SVProgressHUD.showSuccessWithStatus(json["msg"].string ?? "Register successfully")
                                            
                                            userDetail = result
                                            NSUserDefaults.standardUserDefaults().setObject(result, forKey: "userDetail")
                                            NSUserDefaults.standardUserDefaults().synchronize()
                                            
                                            //Go To Update Information
                                            let setDataVC = self.storyboard?.instantiateViewControllerWithIdentifier("SetDataViewController") as! SetDataViewController
                                            self.navigationController?.pushViewController(setDataVC, animated: true)
                                        } else {
                                            SVProgressHUD.showSuccessWithStatus(json["msg"].string ?? "Login successfully")
                                            
                                            userDetail = result
                                            NSUserDefaults.standardUserDefaults().setObject(result, forKey: "userDetail")
                                            NSUserDefaults.standardUserDefaults().synchronize()
                                            
                                            //Go To Main Screen
                                            self.performSegueWithIdentifier("segueHome", sender: nil)
                                        }
                                    }
                                    else if let msg = json["msg"].string {
                                        print(msg)
                                        SVProgressHUD.showErrorWithStatus(msg)
                                        self.navigationController?.popViewControllerAnimated(true)
                                    } else {
                                        SVProgressHUD.showErrorWithStatus("Unable to register!")    // error?.localizedDescription
                                    }
                                    //"status": 1, "result": , "msg": Registraion success! Please check your email for activation key.
                                    
                                case .Failure(let error):
                                    print("Request failed with error: \(error)")
                                    //CommonUtils.sharedUtils.showAlert(self, title: "Error", message: (error?.localizedDescription)!)
                                }
                        }
                    }
                })
            }
            
        })
    }
}
