//
//  SlideRightAnimationController.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/13/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class SlideRightAnimationController: NSObject, UIViewControllerAnimatedTransitioning{
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        
        let offScreenRight = CGAffineTransform(translationX: container.frame.width, y: 0)
        let offScreenLeft = CGAffineTransform(translationX: -container.frame.width, y: 0)
        
        toView.transform = offScreenLeft
        
        container.addSubview(toView)
        container.addSubview(fromView)
        
        let duration = self.transitionDuration(using: transitionContext)
        
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [],
            animations: {
                fromView.transform = offScreenRight
                toView.transform = CGAffineTransform.identity
            }, completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1
    }
}
