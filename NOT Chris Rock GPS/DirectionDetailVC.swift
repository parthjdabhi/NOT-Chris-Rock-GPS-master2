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

        //Print All Instruction
//        for dict in self.directionDetail {
//            if let dictValue = dict as? NSDictionary {
//                print(dictValue["instructions"] as? String ?? "")
//            }
//        }
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
        } else {
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

/*
 Head northwest on I-78 W/Holland TunnelContinue to follow I-78 WEntering New Jersey
 Keep left at the fork to continue on NJ-139 W
 Keep left to stay on NJ-139 W
 Continue onto US-1 S/U.S. 9 S
 Take the exit toward US 1-9 S/NJ-21/US 22/Interstate 78
 Continue onto US-1 Truck S/US-9 Truck S
 Take the Interstate 78 W/Garden State Parkway exit
 Keep left at the fork, follow signs for Interstate 78 Express W/Garden State Parkway and merge onto I-78 Express W/Phillipsburg–Newark Expy
 Continue onto I-78 W/Phillipsburg–Newark Expy
 Keep left to stay on I-78 WPartial toll roadEntering Pennsylvania
 Take the Interstate 81 exit on the left toward Harrisburg
 Merge onto I-81 S
 Keep right at the fork to stay on I-81 S
 Take exit 52 for US-11 toward I-76/New Kingstown/Middlesex
 Turn right onto US-11 S
 Take the Interstate 76/Pennsylvania Turnpike ramp to Philadelphia/PittsburghToll road
 Keep right at the fork, follow signs for I-76 W/Pittsburgh and merge onto I-76 W/Pennsylvania TurnpikeToll road
 Take exit 75 for I-70 W toward Wheeling WVPartial toll road
 Continue onto I-70 W
 Keep left at the fork to stay on I-70 WEntering West Virginia
 Keep left at the fork to continue on I-470 W, follow signs for ColumbusEntering Ohio
 Merge onto I-70 W
 Keep right at the fork to stay on I-70 W, follow signs for Interstate70 W/Dayton/OH-315 N
 Keep left to stay on I-70 W
 Keep left to stay on I-70 WEntering Indiana
 Keep left to stay on I-70 W
 Keep right at the fork to stay on I-70 W, follow signs for Interstate 70 W/Airport/St LouisEntering Illinois
 Keep right at the fork to stay on I-70 W, follow signs for Interstate 70 W/Saint Louis
 Take the Interstate 55 S/Interstate 70 exit on the left toward St Louis
 Merge onto I-55 S/I-70 W
 Keep left at the fork to continue on I-55 S
 Keep right to continue on I-55 S/I-64 WEntering Missouri
 Take exit 40B W for I-44 toward I-70/Kansas St/Walnut St
 Keep left at the fork and merge onto I-44/I-55 S
 Keep right at the fork to continue on I-44, follow signs for 290C/12th St/Gravois Ave
 Keep left to stay on I-44Partial toll roadEntering Oklahoma
 Take exit 34 to merge onto I-44 W/US-412 W toward OK-66/TulsaPartial toll road
 Keep left at the fork to continue on I-44
 Take the OK-66 W/Interstate 44 W exit on the left toward Sapulpa/Okla. City
 Merge onto I-44/OK-66 W
 Keep right to continue on I-44Toll road
 Keep right to continue on I-44 WToll road
 Continue onto John Kilpatrick TurnpikePartial toll road
 Take the exit onto I-40 W toward AmarilloPartial toll roadPassing through Texas, New MexicoEntering Arizona
 Take exit 286 for I-40 BUS/AZ-77 S toward US-180 E/AZ-377 S/Show Low/Heber
 Turn left onto AZ-77 S/Navajo BlvdContinue to follow AZ-77 S
 Turn right onto AZ-377 S/Heber RdContinue to follow AZ-377 S
 Turn right onto AZ-277 S
 Turn right onto AZ-260 W
 Turn left onto AZ-87
 Turn right to merge onto AZ-202 Loop W
 Take the exit on the left onto I-10 W toward Central Phoenix/Los Angeles
 Take exit 112 for AZ-85 toward I-8/Yuma/San Diego
 Continue onto AZ-85 S/Phoenix Bypass Rte
 Slight right onto Phoenix Bypass Rte
 Continue onto E Pima St
 Merge onto I-8 W via the ramp to San DiegoEntering California
 Keep left to stay on I-8 W
 Take exit 14B to merge onto CA-125 S
 Take exit 15 on the left to merge onto CA-94 W/Martin Luther King Jr Fwy
 Take the M L King Jr Fwy exit on the left toward Balboa Park/Downtown/CA-94
 Continue onto F St
 Turn right onto Fifth Ave
 Turn left at the 2nd cross street onto Broadway
 */

/*
 Turn right - /Directional/to-the-right.wav
 Turn left - /Directional/to-the-left.wav
 Turn left at
 Turn right at
 Keep right to - /Directional/to-the-right.wav
 Keep left to - /Directional/to-the-left.wav
 Keep right onto
 Keep left onto
 Keep right at
 Keep left at
 Slight right onto
 Take the
 Head northwest
 Merge onto
 Continue onto
 Take the exit toward
 Take the exit onto
 Take the Interstate
 */