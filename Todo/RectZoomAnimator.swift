//
//  RectZoomAnimator.swift
//  Todo
//
//  Created by Chi Zhang on 12/20/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit

class RectZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    enum AnimationDirection {
        case ZoomIn
        case ZoomOut
    }
    
    let direction: AnimationDirection
    let rect: ()->CGRect
    
    init(direction: AnimationDirection, rect: ()->CGRect) {
        self.direction = direction
        self.rect = rect
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        guard
            let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey),
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey),
            //let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            let containerView = transitionContext.containerView()
            else { return }
        
        containerView.backgroundColor = UIColor.whiteColor()
        
        //let finalFrame = transitionContext.finalFrameForViewController(toViewController)
        let masterView = direction == .ZoomIn ? fromView : toView
        //let detailViewSnapShot = detailView.resizableSnapshotViewFromRect(detailView.bounds, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        let masterViewSnapShot = masterView.resizableSnapshotViewFromRect(masterView.bounds, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        
        if direction == .ZoomOut {
            // dismiss
            containerView.addSubview(masterViewSnapShot)
            //containerView.addSubview(detailViewSnapShot)
            //containerView.addSubview(toView)
            //toView.alpha = 0
            let detailViewEndFrame = self.rect()
//            print("end frame: \(detailViewEndFrame)")
            let scaleX =  containerView.frame.size.width / detailViewEndFrame.size.width
            let scaleY = scaleX
            
            masterViewSnapShot.transform = CGAffineTransformMakeScale(scaleX, scaleY)
//            print("scale: \(scaleX)")
            masterViewSnapShot.frame.origin = CGPointMake(-scaleX*detailViewEndFrame.origin.x, -detailViewEndFrame.origin.y*scaleY)
//            print("origin: \(masterViewSnapShot.frame.origin)")
            
            dispatch_async(dispatch_get_main_queue()) {
                //fromView.hidden = true
//                masterViewSnapShot.alpha = 0
                fromView.alpha = 1
                UIView.animateWithDuration(self.transitionDuration(transitionContext),
                    delay: 0,
                    options: UIViewAnimationOptions.CurveEaseInOut,
                    animations: {
                        //detailViewSnapShot.frame = self.rect()
                        masterViewSnapShot.transform = CGAffineTransformIdentity
                        masterViewSnapShot.frame.origin = CGPointZero
                        //detailViewSnapShot.alpha = 0
                        fromView.alpha = 0
//                        masterViewSnapShot.alpha = 1
                        
//                        print("master: \(masterViewSnapShot)")
//                        print("animateView: \(detailViewSnapShot)")
                    },
                    
                    completion: { (success) in
                        //detailViewSnapShot.removeFromSuperview()
                        masterViewSnapShot.removeFromSuperview()
                        containerView.addSubview(toView)
                        fromView.hidden = false
                        transitionContext.completeTransition(success)
                })
            }
            
        } else {
            // show
            let rect = self.rect()
            //detailViewSnapShot.frame = self.rect()
            let detailViewBeginFrame = rect
            let scaleX = containerView.frame.size.width / rect.size.width
            let scaleY = scaleX
            containerView.addSubview(masterViewSnapShot)
            //containerView.addSubview(detailViewSnapShot)
            containerView.addSubview(toView)
            toView.alpha = 0
            
            dispatch_async(dispatch_get_main_queue(), {
                fromView.hidden = true
                //detailViewSnapShot.alpha = 0
                UIView.animateWithDuration(self.transitionDuration(transitionContext),
                    delay: 0,
                    options: UIViewAnimationOptions.CurveEaseInOut,
                    animations: {
                        //detailViewSnapShot.frame = finalFrame
                        masterViewSnapShot.transform = CGAffineTransformMakeScale(scaleX, scaleY)
                        masterViewSnapShot.frame.origin = CGPointMake(-scaleX*detailViewBeginFrame.origin.x, -detailViewBeginFrame.origin.y*scaleY)
//                        print("origin1: \(masterViewSnapShot.frame.origin)")
//                        print("\(masterViewSnapShot.frame)")
                        masterViewSnapShot.alpha = 0
                        //print("final frame: \(finalFrame)")
                        //detailViewSnapShot.alpha = 1
                        toView.alpha = 1
                    },
                    completion: { (success) in
                        //detailViewSnapShot.removeFromSuperview()
                        masterViewSnapShot.removeFromSuperview()
                        //containerView.addSubview(toView)
                        //print("final frame2: \(toView.frame)")
                        transitionContext.completeTransition(success)
                        fromView.hidden = false
                })
            })
            
        }
    }
}
