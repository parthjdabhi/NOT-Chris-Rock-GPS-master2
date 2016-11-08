//
//  Constants.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/13/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import CoreLocation

import Alamofire
import SwiftyJSON
import SVProgressHUD

class CommonUtils: NSObject {
    static let sharedUtils = CommonUtils()
    var progressView : MBProgressHUD = MBProgressHUD.init()
    
    // show alert view
    func showAlert(controller: UIViewController, title: String, message: String) {
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        controller.presentViewController(ac, animated: true){}
    }
    
    // show progress view
    func showProgress(view : UIView, label : String) {
        progressView = MBProgressHUD.showHUDAddedTo(view, animated: true)
        progressView.labelText = label
    }
    
    // hide progress view
    func hideProgress() {
        progressView.removeFromSuperview()
        progressView.hide(true)
    }
    
    func decodeImage(base64String : String) -> UIImage {
        let decodedData = NSData(base64EncodedString: base64String, options:  NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
        let image = UIImage(data: decodedData!)
        return image!
    }
}

@IBDesignable
class MyCustomButton: UIButton {
    
    @IBInspectable var Padding: CGFloat {
        get {
            return layer.cornerRadius
        }
        set
        {
            let imageSize = self.imageView!.frame.size
            let titleSize = self.titleLabel!.frame.size
            let totalHeight = imageSize.height + titleSize.height + Padding
            
            self.imageEdgeInsets = UIEdgeInsets(
                top: -(totalHeight - imageSize.height),
                left: 0,
                bottom: 0,
                right: -titleSize.width
            )
            
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -imageSize.width,
                bottom: -(totalHeight - titleSize.height),
                right: 0
            )
        }
    }
}

@IBDesignable
class MyCustomLabel: UILabel {
    
    @IBInspectable var textShadow: CGFloat {
        get {
            return layer.cornerRadius
        }
        set
        {
            self.shadowColor = UIColor.blackColor()
            self.shadowOffset = CGSizeMake(0.0, 0.0)
            self.layer.shadowRadius = 1.0
            self.layer.shadowOpacity = 0.2
            self.layer.masksToBounds = false
            self.layer.shouldRasterize = true
        }
    }
}

func updateUserLocation()
{
    print("updateUserLocation")
    
    if CLocation?.coordinate.latitude == 0
        && CLocation?.coordinate.longitude == 0
    {
        CLocation = LocationManager.sharedInstance.CLocation
    }
    
    if CLocation?.coordinate.latitude == 0
        && CLocation?.coordinate.longitude == 0
    {
        return
    }
    
    if user_id != ""
    {
        let Parameters:[String:AnyObject] = ["user_id" : user_id,
                          "lat" : CLocation?.coordinate.latitude ?? 0,
                          "lng" : CLocation?.coordinate.longitude ?? 0]
        print(Parameters)
        
        Alamofire.request(.POST, url_updateLocation, parameters: Parameters)
            .validate()
            .responseJSON { response in
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
                        //SVProgressHUD.showSuccessWithStatus(json["msg"].string ?? "Login successfully")
                        
                        userDetail = result
                        NSUserDefaults.standardUserDefaults().setObject(result, forKey: "userDetail")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                    }
                    else if let msg = json["msg"].string {
                        print(msg)
                    }
                case .Failure(let error):
                    SVProgressHUD.showErrorWithStatus("Request failed!")
                    print("Request failed with error: \(error)")
                    //CommonUtils.sharedUtils.showAlert(self, title: "Error", message: (error?.localizedDescription)!)
                }
        }
    } else {
//        let alert = UIAlertController(title: "Error", message: "cant update!", preferredStyle: .Alert)
//        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
//        alert.addAction(action)
    }
}
