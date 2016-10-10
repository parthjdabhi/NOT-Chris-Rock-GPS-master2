//
//  ForgotPwdVC.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 10/10/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire
import SwiftyJSON

class ForgotPwdVC: UIViewController {

    // MARK: - Member
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var btnSubmit: UIButton!
    
    @IBOutlet var btnLogin: UIButton!
    
    // MARK: - VC LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        txtEmail.setCornerRadious()
        txtEmail.setPlaceholderColor(UIColor.darkGrayColor())
        txtEmail.setLeftMargin(12)
        btnLogin.setCornerRadious()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Action
    @IBAction func actionResetPassword(sender: AnyObject)
    {
        self.view.endEditing(true)
        
        if self.txtEmail.text!.isEmpty {
            SVProgressHUD.showInfoWithStatus("Please add your email!")
            txtEmail.animateShakeEffect()
        }
        else
        {
            let Parameters = ["submitted" : "1",
                              "email" : txtEmail.text ?? ""]
            print(Parameters)
            SVProgressHUD.showWithStatus("Loading..")
            
            Alamofire.request(.POST, url_ResetPassword, parameters: Parameters)
                .validate()
                .responseJSON { response in
                    CommonUtils.sharedUtils.hideProgress()
                    switch response.result
                    {
                    case .Success(let data):
                        let json = JSON(data)
                        print(json.dictionary)
                        
                        if let status = json["status"].string
                            //,result = json["result"].dictionaryObject
                            where status == "1"
                        {
                            print(json["msg"].string )
                            SVProgressHUD.showSuccessWithStatus(json["msg"].string ?? "Request submitted successfully")
                            
//                            userDetail = result
//                            NSUserDefaults.standardUserDefaults().setObject(result, forKey: "userDetail")
//                            NSUserDefaults.standardUserDefaults().synchronize()
                            
                            //Go To Login Screen
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                        else if let msg = json["msg"].string {
                            print(msg)
                            SVProgressHUD.showErrorWithStatus(msg)
                            self.navigationController?.popViewControllerAnimated(true)
                        } else {
                            SVProgressHUD.showErrorWithStatus("Unable to request!")    // error?.localizedDescription
                        }
                        //"status": 1, "result": , "msg": Registraion success! Please check your email for activation key.
                        
                    case .Failure(let error):
                        SVProgressHUD.showErrorWithStatus("Operation Failed!")
                        print("Request failed with error: \(error)")
                        //CommonUtils.sharedUtils.showAlert(self, title: "Error", message: (error?.localizedDescription)!)
                    }
            }
        }
    }
    @IBAction func actionGoToLogin(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}
