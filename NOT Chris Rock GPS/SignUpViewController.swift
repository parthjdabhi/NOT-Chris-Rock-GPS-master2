//
//  SignUpViewController.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/15/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

import Alamofire
import SwiftyJSON
import SVProgressHUD
import SDWebImage
import IQKeyboardManagerSwift
import IQDropDownTextField

class SignUpViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, IQDropDownTextFieldDelegate {
    
    @IBOutlet var imgBackGProfile: UIImageView!
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var btnProfileImg: UIButton!
    
    @IBOutlet var txtName: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var txtConfirmEmail: UITextField!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtGender: UITextField!
    @IBOutlet weak var swGender: PDSwitch?
    @IBOutlet var txtBirthDate: IQDropDownTextField!
    @IBOutlet var txtFoodType: UITextField!
    
    // MARK: -
    // MARK: Vars
    
    var tblFavFood = UITableView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 204))
    var lastSelectedIndexPath = NSIndexPath(forRow: -1, inSection: 0)
    var selectedFood:Array<String> = []
    var imgTaken = false
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        imgProfile.setCornerRadious(imgProfile.frame.width/2)
        //imgProfile.setBorder(1, color: clrGreen)
        imgBackGProfile.setCornerRadious(imgBackGProfile.frame.width/2)
        imgProfile.image = UIImage(named: "stamp-red")
        imgProfile.contentMode = .ScaleAspectFit
        
        txtName.setCornerRadious()
        txtEmail.setCornerRadious()
        txtConfirmEmail.setCornerRadious()
        txtPassword.setCornerRadious()
        txtGender.setCornerRadious()
        txtBirthDate.setCornerRadious()
        txtFoodType.setCornerRadious()
        
        txtName.setPlaceholderColor(UIColor.darkGrayColor())
        txtEmail.setPlaceholderColor(UIColor.darkGrayColor())
        txtConfirmEmail.setPlaceholderColor(UIColor.darkGrayColor())
        txtPassword.setPlaceholderColor(UIColor.darkGrayColor())
        txtGender.setPlaceholderColor(UIColor.darkGrayColor())
        txtBirthDate.setPlaceholderColor(UIColor.darkGrayColor())
        txtFoodType.setPlaceholderColor(UIColor.darkGrayColor())
        
        txtName.setLeftMargin(8)
        txtEmail.setLeftMargin(8)
        txtConfirmEmail.setLeftMargin(8)
        txtPassword.setLeftMargin(8)
        txtGender.setLeftMargin(8)
        txtBirthDate.setLeftMargin(8)
        txtFoodType.setLeftMargin(8)
        
        txtBirthDate?.isOptionalDropDown = false
        txtBirthDate?.dropDownMode = IQDropDownMode.DatePicker
        txtBirthDate?.setDate(NSDate.changeYearsBy(-13), animated: true)
        txtBirthDate?.maximumDate = NSDate.changeYearsBy(-13)
        
        tblFavFood.allowsMultipleSelection = true
        tblFavFood.delegate = self
        tblFavFood.dataSource = self
        tblFavFood.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
        txtFoodType.inputView = tblFavFood
        
        swGender?.titles = genderType
        //swGender?.backgroundColor = UIColor(red: 122/255.0, green: 203/255.0, blue: 108/255.0, alpha: 1.0)
        //swGender?.selectedBackgroundColor = UIColor.whiteColor()
        //swGender?.titleColor = UIColor.whiteColor()
        //swGender?.selectedTitleColor = UIColor(red: 135/255.0, green: 227/255.0, blue: 120/255.0, alpha: 1.0)
        //swGender?.titleFont = UIFont(name: "HelveticaNeue-Light", size: 17.0)
        
    }
    
    // MARK: -
    
    @IBAction func switchValueDidChange(sender: PDSwitch!) {
        print("valueChanged: \(sender.selectedIndex)")
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func  preferredStatusBarStyle()-> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    
    @IBAction func actionBack(sender: UIButton) {
        //Go To back
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func createProfile(sender: AnyObject)
    {
        /*
         1.	First Name
         2.	Email
         3.	Re-enter Email
         4.	Password [remember me checkbox]
         5.	Birthday
         6.	Gender
         7.	Please select up to four food types you like. (American, Mexican, Italian, Chinese, Asian, Indian, Mediterranean, BBQ, Fast Food, Steak, Soups, Salads, Pizza, Southern, Cajun) — you can add these as the list & let the user select up to 4 options.
         */
        
        if self.txtName.text!.isEmpty {
            SVProgressHUD.showInfoWithStatus("Please add your name!")
            txtName.animateShakeEffect()
        } else if self.txtEmail.text!.isEmpty {
            SVProgressHUD.showInfoWithStatus("Please add your email!")
            txtEmail.animateShakeEffect()
        } else if self.txtConfirmEmail.text!.isEmpty {
            SVProgressHUD.showInfoWithStatus("Invaild confirm email!")
            txtConfirmEmail.animateShakeEffect()
        } else if self.txtEmail.text! != self.txtConfirmEmail.text! {
            SVProgressHUD.showInfoWithStatus("Confirm email is not matching with email.!")
            txtEmail.animateShakeEffect()
            txtConfirmEmail.animateShakeEffect()
        } else if self.txtPassword.text!.isEmpty || self.txtPassword.text!.characters.count < 6 {
            SVProgressHUD.showInfoWithStatus("Your password should be of minimum six character long!")
            txtPassword.animateShakeEffect()
        }else if imgTaken == false {
            SVProgressHUD.showInfoWithStatus("Select you profile picture!")
            imgProfile.animateShakeEffect()
            imgBackGProfile.animateShakeEffect()
        }
        else
        {
            let Parameters = ["submitted": "1",
                              "name" : self.txtName.text ?? "",
                              "email" : self.txtEmail.text ?? "",
                              "password" : self.txtPassword.text ?? "",
                              "gender" : genderType[swGender?.selectedIndex ?? 0],
                              "birthday" : NSDate().strDateInUTC,
                              "favfood" : txtFoodType.text ?? ""]
            //photo
            
            print(Parameters)
            SVProgressHUD.showWithStatus("Registering..")
            
            Alamofire.upload(.POST, url_register, multipartFormData: { (multipartFormData) -> Void in
                if let imageData = UIImageJPEGRepresentation(self.imgProfile.image!, 0.8) {
                    multipartFormData.appendBodyPart(data: imageData, name: "photo", fileName: "file.png", mimeType: "image/png")
                }
                for (key, value) in Parameters {
                    multipartFormData.appendBodyPart(data: value.dataUsingEncoding(NSUTF8StringEncoding)!, name: key)
                }
                })
            { (encodingResult) -> Void in
                switch encodingResult {
                    
                case .Success (let upload, _, _):
                    upload.responseJSON { response in
                        CommonUtils.sharedUtils.hideProgress()
                        switch response.result
                        {
                        case .Success(let data):
                            
                            let json = JSON(data)
                            print(json.dictionary)
                            //print(json.dictionaryObject)
                            
                            if let status = json["status"].string,
                                result = json["result"].dictionaryObject
                                where status == "1"
                            {
                                print(json["msg"].string )
                                SVProgressHUD.showSuccessWithStatus(json["msg"].string ?? "Register successfully")
                                
                                userDetail = result
                                NSUserDefaults.standardUserDefaults().setObject(result, forKey: "userDetail")
                                NSUserDefaults.standardUserDefaults().synchronize()
                                
                                self.performSegueWithIdentifier("segueHome", sender: self)
                            }
                            else if let msg = json["msg"].string {
                                print(msg)
                                SVProgressHUD.showErrorWithStatus(msg)
                                //self.navigationController?.popViewControllerAnimated(true)
                            } else {
                                SVProgressHUD.showErrorWithStatus("Unable to register!")    // error?.localizedDescription
                            }
                            //"status": 1, "result": , "msg": Registraion success! Please check your email for activation key.
                            
                        case .Failure(let error):
                            print("Request failed with error: \(error)")
                            SVProgressHUD.dismiss()
                            self.showAlert("Error", message: error.description)
                        }
                    }
                //break
                case .Failure(let errorType):
                    print("Request failed with error: \(errorType)")
                    SVProgressHUD.dismiss()
                    self.showAlert("Error", message: "Unable to register!")
                }
            }
        }
    }
    
    
    // MARK - TableView Delegate & DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foodCategories.count
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 40
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel!.text = "\(indexPath.row)"
        cell.detailTextLabel?.text = "location"
        
        cell.textLabel?.font = UIFont(name: "HelveticaNeue", size: 14.0)
        cell.textLabel?.text = foodCategories[indexPath.row]["name"]
        
        //cell.selectionStyle = .None
        
        //cell.accessoryType = cell.selected ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
        //        if cell.selected {
        //            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        //        } else {
        //            cell.accessoryType = UITableViewCellAccessoryType.None
        //        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let isFoodSelected:Bool = selectedFood.contains(foodCategories[indexPath.row]["code"] ?? "-")
        
        //(selectedFood.contains(foodTypes[indexPath.row])
        if selectedFood.count >= 4
            && isFoodSelected == false
        {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            SVProgressHUD.showInfoWithStatus("You can't select  more than four diffrent food!")
            return
        }
        
        if isFoodSelected == false {
            selectedFood.append(foodCategories[indexPath.row]["code"] ?? "-")
            txtFoodType.text = selectedFood.joinWithSeparator(", ")
        }
        //        let cell = tableView.cellForRowAtIndexPath(indexPath)
        //        if cell!.selected == true {
        //            cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        //        } else {
        //            cell!.accessoryType = UITableViewCellAccessoryType.None
        //        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let index = selectedFood.indexOf(foodCategories[indexPath.row]["code"] ?? "-") {
            selectedFood.removeAtIndex(index)
            txtFoodType.text = selectedFood.joinWithSeparator(", ")
        }
        
        //tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }
    
    @IBAction func takePhoto(sender: AnyObject) {
        // 1
        view.endEditing(true)
        
        // 2
        let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Photo",
                                                       message: nil, preferredStyle: .ActionSheet)
        // 3
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let cameraButton = UIAlertAction(title: "Take Photo",
                                             style: .Default) { (alert) -> Void in
                                                let imagePicker = UIImagePickerController()
                                                imagePicker.delegate = self
                                                imagePicker.sourceType = .Camera
                                                imagePicker.allowsEditing = true
                                                self.presentViewController(imagePicker,
                                                                           animated: true,
                                                                           completion: nil)
            }
            imagePickerActionSheet.addAction(cameraButton)
        }
        // 4
        let libraryButton = UIAlertAction(title: "Choose Existing",
                                          style: .Default) { (alert) -> Void in
                                            let imagePicker = UIImagePickerController()
                                            imagePicker.delegate = self
                                            imagePicker.sourceType = .PhotoLibrary
                                            imagePicker.allowsEditing = true
                                            self.presentViewController(imagePicker,
                                                                       animated: true,
                                                                       completion: nil)
        }
        imagePickerActionSheet.addAction(libraryButton)
        // 5
        let cancelButton = UIAlertAction(title: "Cancel",
                                         style: .Cancel) { (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        // 6
        presentViewController(imagePickerActionSheet, animated: true,
                              completion: nil)
    }
    
    // Image picker Delegate methods
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            imgProfile.image = editedImage
            //imgProfile.image = self.scaleImage(pickedImage, maxDimension: 300)
        }
        else if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imgProfile.contentMode = .ScaleAspectFit
            imgProfile.image = pickedImage
        }
        
        self.imgTaken = true
        dismissViewControllerAnimated(true, completion: nil)
    }
}
