//
//  DirectionDetail.swift
//  TYDirectionSwift
//
//  Created by Thabresh on 9/6/16.
//  Copyright © 2016 VividInfotech. All rights reserved.
//

import UIKit

class DirectionDetailVC: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var directionDetail = NSArray()
    var directionInfo = NSDictionary()
    var lblSrcDest = UILabel()
   
    @IBOutlet weak var directTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.directTable.estimatedRowHeight = 44
        self.directTable.rowHeight = UITableViewAutomaticDimension
        print(self.directionInfo)
        self.navigationItem.prompt = self.directionInfo .objectForKey("end_address") as? String
        self.navigationItem.title = self.directionInfo .objectForKey("start_address") as? String
        self.directionDetail = directionInfo.objectForKey("steps") as! NSArray
    }
    
    @IBAction func actionGoToBack(sender: AnyObject)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if section == 0 {
            return 1
        }
        return self.directionDetail.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{        
         let cell = tableView.dequeueReusableCellWithIdentifier("DirectionDetailTableViewCell", forIndexPath: indexPath) as! DirectionDetailTableViewCell
        if indexPath.section == 0 {
            cell.directionDescription.text = NSString(format:"Total Distance = %@ \nTotal Duration = %@",directionInfo.valueForKey("distance")as! NSString,directionInfo.valueForKey("duration")as! NSString) as String
            cell.directionDetail.text = NSString(format:"Driving Directions \nfrom \n%@ \nto \n%@",directionInfo.valueForKey("start_address")as! NSString,directionInfo.valueForKey("end_address")as! NSString) as String
        }else{
            let idx:Int = indexPath.row
            let dictTable:NSDictionary = self.directionDetail[idx] as! NSDictionary
            cell.directionDetail.text =  dictTable["instructions"] as? String
            let distance = dictTable["distance"] as! NSString
            let duration = dictTable["duration"] as! NSString
            let detail = "Distance : \(distance) Duration : \(duration)"
            cell.directionDescription.text = detail
            cell.selectionStyle = UITableViewCellSelectionStyle.None
        }
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Driving Directions Summary"
        }else{
        return "Driving Directions Detail"
        }
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

}
