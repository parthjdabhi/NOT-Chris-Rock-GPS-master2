//
//  SingleTouchRotationGestureRecognizer.swift
//  SingleTouchRotationGestureRecognizer
//
//  Created by Chris Gulley on 9/18/15.
//  Copyright © 2015 Chris Gulley. All rights reserved.
//


import UIKit
import UIKit.UIGestureRecognizerSubclass

public class FiveTapGestureRecognizer: UITapGestureRecognizer {

    
    override init(target: AnyObject?, action: Selector) {
        super.init(target: target, action: action)
    }
    
    override public func reset() {
        super.reset()
    }

    public override func canPreventGestureRecognizer(preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("\n\n"," ",preventedGestureRecognizer.view?.classForCoder)
        return false
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        guard let touch = touches.first where touches.count == 1 && view != nil else {
            state = .Failed
            return
        }
        state = .Began
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        guard let touch = touches.first where view != nil else {
            state = .Failed
            return
        }
        
        
        state = .Changed
    }
    
    override public func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesCancelled(touches, withEvent: event)
        state = .Ended
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        state = .Ended
    }
}
