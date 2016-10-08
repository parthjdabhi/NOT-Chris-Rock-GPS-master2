//
//  AudioRecorderViewController.swift
//  AudioRecorderViewControllerExample
//
//  Created by Ben Dodson on 19/10/2015.
//  Copyright © 2015 Dodo Apps. All rights reserved.
//

import UIKit
import AVFoundation

import Alamofire
import SwiftyJSON
import SVProgressHUD

protocol AudioRecorderViewControllerDelegate: class {
    func audioRecorderViewControllerDismissed(withFileURL fileURL: NSURL?)
}

// AVAudioRecorderDelegate, AVAudioPlayerDelegate
class AudioRecorderViewController: UIViewController {
    
    //internal let childViewController = AudioRecorderChildViewController()
    weak var audioRecorderDelegate: AudioRecorderViewControllerDelegate?
    var statusBarStyle: UIStatusBarStyle = .Default
    
    var saveButton: UIBarButtonItem!
    //@IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    //@IBOutlet weak var recordButton: UIButton!
    //@IBOutlet weak var recordButtonContainer: UIView!
    //@IBOutlet weak var playButton: UIButton!
    //weak var audioRecorderDelegate: AudioRecorderViewControllerDelegate?
    
    var timeTimer: NSTimer?
    var milliseconds: Int = 0
    
    var recorder: AVAudioRecorder!
    var player: AVAudioPlayer?
    //var outputURL: NSURL
    var fileName = "\(NSUUID().UUIDString).m4a"
    

    init() {
        fileName = "\(NSUUID().UUIDString).m4a"
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        let recordDirPath = path.stringByAppendingPathComponent("Recordings")
        let filePath = recordDirPath.stringByAppendingPathComponent(fileName) as String
        lastRecordedURL = NSURL(fileURLWithPath: filePath)
        super.init(nibName: "AudioRecorderViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        let settings = [AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatMPEG4AAC), AVSampleRateKey: NSNumber(integer: 44100), AVNumberOfChannelsKey: NSNumber(integer: 2)]
        try! recorder = AVAudioRecorder(URL: lastRecordedURL!, settings: settings)
        recorder.delegate = self
        recorder.prepareToRecord()
        
        //recordButton.layer.cornerRadius = 4
        
        self.startFiveTapGesture()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.view.setCornerRadious(12)
        self.view.setBorder(4, color: UIColor.blueColor())
        
        statusBarStyle = UIApplication.sharedApplication().statusBarStyle
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if recorder.recording {
            timeTimer?.invalidate()
            if recorder.recording {
                recorder.stop()
            }
            //saveRecording()
        }
        
        if audioRecorderDelegate != nil {
            audioRecorderDelegate?.audioRecorderViewControllerDismissed(withFileURL: nil)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        UIApplication.sharedApplication().setStatusBarStyle(statusBarStyle, animated: animated)
        self.view.setCornerRadious(0)
        self.view.setBorder(0, color: UIColor.clearColor())
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch let error as NSError {
            NSLog("Error: \(error)")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AudioRecorderViewController.toggleRecord(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        milliseconds = 0
        timeLabel.text = "00:00.00"
        timeTimer = NSTimer.scheduledTimerWithTimeInterval(0.0167, target: self, selector: #selector(AudioRecorderViewController.updateTimeLabel(_:)), userInfo: nil, repeats: true)
        recorder.deleteRecording()
        recorder.record()
    }
    
    internal override func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if flag == true {
            print("Recording stops successfully")
            saveRecording()
        }
        else{
            print("Stopping recording failed")
        }
        
        //        self.playButton.enabled = true
        //        self.recordButton.enabled = false
        //        self.stopButton.enabled = false
    }
    
    @IBAction func dismiss(sender: AnyObject) {
        
        if recorder.recording {
            timeTimer?.invalidate()
            if recorder.recording {
                recorder.stop()
                //recorder.deleteRecording()
            }
            //saveRecording()
        }
        
        if audioRecorderDelegate != nil {
            audioRecorderDelegate?.audioRecorderViewControllerDismissed(withFileURL: nil)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func toggleRecord(sender: AnyObject) {
        
        timeTimer?.invalidate()
        
        if recorder.recording {
            cleanup()
            //saveRecording()
        } else {
            milliseconds = 0
            timeLabel.text = "00:00.00"
            timeTimer = NSTimer.scheduledTimerWithTimeInterval(0.0167, target: self, selector: #selector(AudioRecorderViewController.updateTimeLabel(_:)), userInfo: nil, repeats: true)
            //recorder.deleteRecording()
            recorder.record()
        }
    }
    
    func saveRecording() {
        let Parameters = ["submitted": "1",
                          "filePath" : lastRecordedURL!.absoluteString,
                          "user_id" : user_id,
                          "name" : userDetail["name"] as? String ?? ""]
        //photo
        
        guard let data = NSData(contentsOfURL: lastRecordedURL!) else {
            print("No Recording Founds")
            return
        }
        
        print(Parameters)
        SVProgressHUD.showWithStatus("Uploading..")
        
        let fName = "\(userDetail["name"] as? String ?? "")-NCR-COPSTOP-\(NSDate().strDateInUTC)"
        print(fName)
        
        Alamofire.upload(.POST, url_saveRecording, multipartFormData: { (multipartFormData) -> Void in
            multipartFormData.appendBodyPart(data: data, name: "file", fileName: fName, mimeType: "audio/mp4")
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
                        
                        /*
                         ["status": 1, "result": {
                         "file" : "http:\/\/www.notchrisrock.com\/gps\/api\/file_upload\/12_Parth Dabhi_A0B2ACD0-1A7E-4C43-AA2D-C7FCCE2011FC.m4a"
                         }, "msg": File uploaded successfully.]
                         */
                        if let status = json["status"].int
                            //,result = json["result"].dictionaryObject
                            where status == 1
                        {
                            print(json["msg"].string )
                            SVProgressHUD.showSuccessWithStatus(json["msg"].string ?? "Uploaded successfully")
                            
                            if self.audioRecorderDelegate != nil {
                                self.audioRecorderDelegate?.audioRecorderViewControllerDismissed(withFileURL: lastRecordedURL!)
                            } else {
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                        }
                        else if let msg = json["msg"].string {
                            print(msg)
                            SVProgressHUD.showErrorWithStatus(msg)
                            self.navigationController?.popViewControllerAnimated(true)
                        } else {
                            SVProgressHUD.showErrorWithStatus("Unable to uplod!")    // error?.localizedDescription
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
                self.showAlert("Error", message: "Unable to upload!")
            }
        }
    }
    
    func cleanup() {
        timeTimer?.invalidate()
        if recorder.recording {
            recorder.stop()
            //recorder.deleteRecording()
        }
        if let player = player {
            player.stop()
            self.player = nil
        }
    }
    
    // MARK: Time Label
    
    func updateTimeLabel(timer: NSTimer) {
        milliseconds += 1
        let milli = (milliseconds % 60) + 39
        let sec = (milliseconds / 60) % 60
        let min = milliseconds / 3600
        timeLabel.text = NSString(format: "%02d:%02d.%02d", min, sec, milli) as String
    }

}

