//
//  ViewController1.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/23/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD

import AVFoundation

var tapStack:Array<NSDate> = []
let ApplicationDidFiveTapsNotification = "DetectedFiveTaps"
let tapInSeconds: NSTimeInterval = 5 //* 60

let recordVoiceForSeconds: NSTimeInterval = 15
let progressInterval:Float = 0.1
var currentProgress:Float = 0.0
var recordTimer: NSTimer?
var stopRecordTimer: NSTimer?
var isRecordingVoice: Bool = false
var lastRecordedURL: NSURL?

class MyVCdata {
    var isEnableFivetapGesture = true
    init(isEnableFivetapGesture: Bool)
    {
        self.isEnableFivetapGesture = isEnableFivetapGesture
    }
}

extension UIViewController: UIGestureRecognizerDelegate
{
    static var extraData = [UIViewController: MyVCdata]()
    
    var isEnableFivetapGesture: Bool {
        get {
            return UIViewController.extraData[self]?.isEnableFivetapGesture ?? true
        }
        set(value) {
            UIViewController.extraData[self] = MyVCdata(isEnableFivetapGesture: value)
        }
    }
    
    func startFiveTapGesture() {
        let tap: FiveTapGestureRecognizer = FiveTapGestureRecognizer(target: self, action: #selector(UIViewController.checkThisTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    func checkFiveTapGesture() {
        // print("checkFiveTapGesture")
        // checkThisTap()
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        //print("classForCoder class:\(touch.view?.classForCoder)")
        //print("class is UIButton:\(touch.view! is UIButton)")
        //print("classForKeyedArchiver class:\(touch.view?.classForKeyedArchiver)")
        
        return (touch.view! is UIButton || touch.view! is UITextField || touch.view! is UITextView) ? false : true
        
        //return true
    }
    
    // Resent the timer because there was user interaction.
    func checkThisTap(sender:UITapGestureRecognizer)
    {
        //print("tap class:\(sender.view?.classForCoder)")
        
        //print("isEnableFivetapGesture : ",isEnableFivetapGesture)
        tapStack.append(NSDate())
        //print(" Count : ", tapStack.count, "First : ", tapStack.first, "Last : ", tapStack.last)
        
        if tapStack.count > 5 {
            tapStack.removeFirst()
        }
        
        if tapStack.count == 5
            && isRecordingVoice == false
        {
            let elapsedTime = tapStack.last!.timeIntervalSinceDate(tapStack.first!)
            //let duration = Int(elapsedTime)
            if elapsedTime <= tapInSeconds { //Timeout time to detect taps in 10 seconds
                tapStack.removeAll()
                DetectedFiveTaps()
            }
        }
    }
    
    // If the tpas reaches the limit as defined in tapInSeconds, post this notification.
    func DetectedFiveTaps()
    {
        print("DetectedFiveTaps")
        //NSNotificationCenter.defaultCenter().postNotificationName(ApplicationDidFiveTapsNotification, object: nil)
        //topViewController()?.ShowRecodringScreen()
        
        /*
        topViewController()?.view.setCornerRadious(12)
        topViewController()?.view.setBorder(4, color: UIColor.blueColor())
        
        recordTimer = NSTimer.scheduledTimerWithTimeInterval(Double(progressInterval), target: self,
                                                             selector: #selector(UIViewController.timerAction), userInfo: ["record":"voice"], repeats: true)
        stopRecordTimer = NSTimer.scheduledTimerWithTimeInterval(recordVoiceForSeconds, target: self,
                                                                 selector: #selector(UIViewController.StopRecording), userInfo: nil, repeats: false)
        currentProgress = 0.0
        SVProgressHUD.showProgress(currentProgress, status: "Recording Voice..")
        isRecordingVoice = true
        
        startRecording()
        */
        
        //print("Class name : ",self,"  - ",NSStringFromClass(self.dynamicType))
        //print("is recording - isRecordingVoice",isRecordingVoice)
        
        if self.isKindOfClass(AudioRecorderViewController) {
            self.dismissViewControllerAnimated(true, completion: {
                print("Recording view dismissed")
            })
        } else {
            let controller = AudioRecorderViewController()
            //controller.audioRecorderDelegate = self
            controller.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            presentViewController(controller, animated: true, completion: nil)
        }
        
        //Present VoiceHelpVC
//        let viewController = topViewController()?.storyboard?.instantiateViewControllerWithIdentifier("VoiceHelpVC") as! VoiceHelpVC
//        viewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
//        self.presentViewController(viewController, animated: true, completion: nil)
        
    }
    
    // called every time interval from the timer
    func timerAction()
    {
        currentProgress = currentProgress + (progressInterval/Float(recordVoiceForSeconds))
        SVProgressHUD.showProgress(currentProgress, status: "Recording Voice..")
        //print("fireDate :",recordTimer?.fireDate)
        //print("  timeInterval :",recordTimer?.timeInterval)
    }
    
    func StopRecording()
    {
        recordTimer?.invalidate()
        stopRecordTimer?.invalidate()
        isRecordingVoice = false
        
        topViewController()?.view.setCornerRadious(0)
        topViewController()?.view.setBorder(0, color: UIColor.clearColor())
        
        SVProgressHUD.showSuccessWithStatus("Voice Recorded!")
        
        //Start Uploading of recorded voice
        stopButtonClicked(self)
        print("Recorded Audio Path :", audioFilePath())
    }
    
}

//class MyViewController: UIViewController, AudioRecorderViewControllerDelegate {
//
//    //MARK : AudioRecorderViewController Delegage Methods
//
//    func audioRecorderViewControllerDismissed(withFileURL fileURL: NSURL?) {
//        // do something with fileURL
//        dismissViewControllerAnimated(true, completion: nil)
//        print("Audio file URL : \(fileURL)")
//    }
//
//    //MARK : ShowRecodringScreen
//
//    func ShowRecodringScreen() {
//        print("ShowRecodringScreen")
//        let controller = AudioRecorderViewController()
//        controller.audioRecorderDelegate = self
//        presentViewController(controller, animated: true, completion: nil)
//    }
//}

extension UIViewController : AudioRecorderViewControllerDelegate
{
    func ShowRecodringScreen() {
        print("ShowRecodringScreen")
        let controller = AudioRecorderViewController()
        controller.audioRecorderDelegate = self
        presentViewController(controller, animated: true, completion: nil)
    }
    
    //MARK : AudioRecorderViewController Delegage Methods
    func audioRecorderViewControllerDismissed(withFileURL fileURL: NSURL?) {
        // do something with fileURL
        dismissViewControllerAnimated(true, completion: nil)
        print("Audio file URL : \(fileURL)")
    }
}


func topViewController(base: UIViewController? = (UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController) -> UIViewController? {
    if let nav = base as? UINavigationController {
        return topViewController(nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
        if let selected = tab.selectedViewController {
            return topViewController(selected)
        }
    }
    if let presented = base?.presentedViewController {
        return topViewController(presented)
    }
    return base
}



//Recording--------------------------

import UIKit
import AVFoundation

extension String {
    
    func stringByAppendingPathComponent(path: String) -> String {
        
        let nsSt = self as NSString
        return nsSt.stringByAppendingPathComponent(path)
    }
}

var audioRecorder : AVAudioRecorder!
var outputURL: String!

extension UIViewController : AVAudioPlayerDelegate, AVAudioRecorderDelegate
{
    //    var audioPlayer : AVAudioPlayer!
    //    var audioRecorder : AVAudioRecorder!
    
    //    @IBOutlet var recordButton : UIButton!
    //    @IBOutlet var playButton : UIButton!
    //    @IBOutlet var stopButton : UIButton!
    
    //    override func viewDidLoad() {
    //        super.viewDidLoad()
    //
    ////        self.recordButton.enabled = true
    ////        self.playButton.enabled = false
    ////        self.stopButton.enabled = false
    //    }
    
    
    //MARK: UIButton action methods
    
    @IBAction func stopButtonClicked(sender : AnyObject){
        
        if let record = audioRecorder{
            
            record.stop()
        }
        
        let session = AVAudioSession.sharedInstance()
        do{
            try session.setActive(false)
        }
        catch{
            print("\(error)")
        }
    }
    
    @IBAction func recordButtonClicked(sender : AnyObject){
        
        let session = AVAudioSession.sharedInstance()
        
        do{
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setActive(true)
            session.requestRecordPermission({ (allowed : Bool) -> Void in
                
                if allowed {
                    self.startRecording()
                }
                else{
                    print("We don't have request permission for recording.")
                }
            })
        }
        catch{
            print("\(error)")
        }
    }
    
    func startRecording(){
        
        //        self.playButton.enabled = false
        //        self.recordButton.enabled = false
        //        self.stopButton.enabled = true
        
        do{
            
            let fileURL = NSURL(string: self.audioFilePath())!
            audioRecorder = try AVAudioRecorder(URL: fileURL, settings: self.audioRecorderSettings() as! [String : AnyObject])
            
            if let recorder = audioRecorder{
                recorder.delegate = self
                
                if recorder.record() && recorder.prepareToRecord(){
                    print("Audio recording started successfully")
                }
            }
        }
        catch{
            print("\(error)")
        }
    }
    
    func audioFilePath() -> String
    {
        //        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        //        //let outputPath = documentsPath.stringByAppendingPathComponent("\(NSUUID().UUIDString).m4a")
        //        let outputPath = NSBundle.mainBundle().pathForResource("\(NSUUID().UUIDString)", ofType: "mp3")!
        //        outputURL = NSURL(fileURLWithPath: outputPath)
        //        return outputPath
        
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        let recordDirPath = path.stringByAppendingPathComponent("Recordings")
        let filePath = recordDirPath.stringByAppendingPathComponent("\(NSUUID().UUIDString).caf") as String
        outputURL = filePath
        
        //api/audio/policeFile/
        
        //let filePath = NSBundle.mainBundle().pathForResource("mySong", ofType: "mp3")!
        return filePath
    }
    
    func audioRecorderSettings() -> NSDictionary{
        
        let settings = [AVFormatIDKey : NSNumber(int: Int32(kAudioFormatMPEG4AAC)), AVSampleRateKey : NSNumber(float: Float(16000.0)), AVNumberOfChannelsKey : NSNumber(int: 1), AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))]
        
        return settings
    }
    
    //MARK: AVAudioPlayerDelegate methods
    
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        
        if flag == true {
            print("Player stops playing successfully")
        }
        else{
            print("Player interrupted")
        }
        
        //        self.recordButton.enabled = true
        //        self.playButton.enabled = false
        //        self.stopButton.enabled = false
    }
    
    //MARK: AVAudioRecorderDelegate methods
    
    public func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if flag == true {
            print("Recording stops successfully")
        }
        else{
            print("Stopping recording failed")
        }
        
        //        self.playButton.enabled = true
        //        self.recordButton.enabled = false
        //        self.stopButton.enabled = false
    }
}
