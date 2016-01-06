//
//  RectZoomAnimator.swift
//  Todo
//
//  Created by Chi Zhang on 12/20/15.
//  Copyright © 2015 chi zhang. All rights reserved.
//

import UIKit

class RectZoomAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    // true for presenting animation, false for dismissing animation
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
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        guard
            let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey),
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey),
            let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
            let containerView = transitionContext.containerView()
            else { return }
        
        let finalFrame = transitionContext.finalFrameForViewController(toViewController)
        let animateView = direction == .ZoomIn ? fromView : toView
        let animateViewSnapShot = animateView.resizableSnapshotViewFromRect(animateView.bounds, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        
        if direction == .ZoomIn {
            containerView.addSubview(toView)
            containerView.addSubview(animateViewSnapShot)
            
            UIView.animateWithDuration(transitionDuration(transitionContext),
                animations: {
                    animateViewSnapShot.frame = self.rect()
                },
                completion: { (success) in
                    animateViewSnapShot.removeFromSuperview()
                    transitionContext.completeTransition(success)
            })
            
        } else {
            animateViewSnapShot.frame = self.rect()
            containerView.addSubview(animateViewSnapShot)
            UIView.animateWithDuration(transitionDuration(transitionContext),
                animations: {
                    animateViewSnapShot.frame = finalFrame
                },
                completion: { (success) in
                    animateViewSnapShot.removeFromSuperview()
                    containerView.addSubview(toView)
                    transitionContext.completeTransition(success)
            })
            
            
            
        }
        
    }
}
