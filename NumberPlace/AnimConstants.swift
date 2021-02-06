//
//  AnimConstants.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/03.
//

import UIKit


struct AnimConstants {
    
    static let circleDropAnimDuration = 0.8
    
    static let preparationDuration = 0.1
    
    static let plotInterval = 0.01
    
    static let relativePreparationDuration = preparationDuration / circleDropAnimDuration
    
    static let relativePlotInterval = plotInterval / circleDropAnimDuration
    
    
    static func scaleDownInterpolation(_ x: Double) -> CGFloat {
        return CGFloat( 230.0/36.0 * pow(x-0.7, 2) + 0.7 )
    }

    static func scaleUpInterpolation(_ x: Double) -> CGFloat {
        return CGFloat( 30.0 * pow(x-0.7, 2) + 0.7 )
    }
    
    static func circleAlphaInterpolation(_ x: Double) -> CGFloat {
        return CGFloat(10.0*(x+0.01)/6.0 - 1.0/6.0)
    }
    
    static func labelAlphaInterpolation(_ x: Double) -> CGFloat {
        return CGFloat(10*(x+0.01) - 7.0)
    }
}

/* Animation constants for SudokuListViewController */
let submenuOpenDuration = 0.5
let submenuDisappearDuration = 3 * submenuOpenDuration / 4
let submenuCloseDuration = submenuOpenDuration / 4


enum PresentationType {
    case present
    case dismiss
}

class SharedViewAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    var viewToMove: UIView?
    
    var sourceRect: CGRect
    var destinationRect: CGRect
    
    var presentationType: PresentationType
    
    init(sharedView: UIView, from: CGRect, to: CGRect, type: PresentationType) {
        viewToMove = sharedView.snapshotView(afterScreenUpdates: true)
        sourceRect = from
        destinationRect = to
        presentationType = type
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TimeInterval(0.9)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let blankViewFrom = UIView(frame: sourceRect)
        let blankViewTo = UIView(frame: destinationRect)
        blankViewFrom.backgroundColor = UIColor.white
        blankViewTo.backgroundColor = UIColor.white
        switch presentationType {
        case .present:
            transitionContext.containerView.addSubview(blankViewFrom)
            if let destination =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)?.view {
                destination.tag = 1001
                destination.alpha = 0.0
                destination.addSubview(blankViewTo)
                transitionContext.containerView.addSubview(destination)
            }
            if let view = viewToMove {
                view.tag = 1002
                view.frame = sourceRect
                transitionContext.containerView.addSubview(view)
            }
            UIView.animate(
                withDuration: 0.8,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: {
                    transitionContext.containerView.viewWithTag(1001)?.alpha = 1.0
                    transitionContext.containerView.viewWithTag(1002)?.frame = self.destinationRect
                })
            UIView.animate(
                withDuration: 0.1,
                delay: 0.8,
                options: [],
                animations: {
                    transitionContext.containerView.viewWithTag(1002)?.alpha = 0.0
                    blankViewTo.alpha = 0.0
                },
                completion: { successed in
                    // cleanup of the animation
                    blankViewFrom.removeFromSuperview()
                    blankViewTo.removeFromSuperview()
                    self.viewToMove?.removeFromSuperview()
                    transitionContext.completeTransition(true)
                })
        case .dismiss:
            // presented view must be already exists in the contaier view
            if let from =
                transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)?.view {
                from.tag = 2001
                from.addSubview(blankViewFrom)
            }
            transitionContext.containerView.insertSubview(blankViewTo, at: 0)
            if let view = viewToMove {
                view.tag = 2002
                view.frame = sourceRect
                transitionContext.containerView.addSubview(view)
            }
            UIView.animate(
                withDuration: 0.8,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: {
                    // move the shared view first
                    transitionContext.containerView.viewWithTag(2001)?.alpha = 0.0
                    transitionContext.containerView.viewWithTag(2002)?.frame = self.destinationRect
                })
            UIView.animate(
                withDuration: 0.1,
                delay: 0.8,
                options: [],
                animations: {
                    // and then fade the actual view in
                    transitionContext.containerView.viewWithTag(2002)?.alpha = 0.0
                    blankViewTo.alpha = 0.0
                },
                completion: { successed in
                    // cleanup of the animation
                    blankViewFrom.removeFromSuperview()
                    blankViewTo.removeFromSuperview()
                    self.viewToMove?.removeFromSuperview()
                    for view in transitionContext.containerView.subviews {
                        view.removeFromSuperview()
                    }
                    transitionContext.completeTransition(true)
                })
        }
        
    }
}

class SudokuShowAnimatedTransitioning: SharedViewAnimatedTransitioning {
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // SavedSudokuViewController must be loaded here
        if presentationType == .present,
           let sudokuNavigationVC =
            transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
            as? SudokuNavigationViewController {
            if let savedSudokuVC = sudokuNavigationVC.topViewController as? SavedSudokuViewController {
                if let toView = savedSudokuVC.sudokuView {
                    destinationRect = toView.convert(toView.bounds, to: savedSudokuVC.view)
                }
            }
        }
        super.animateTransition(using: transitionContext)
    }
}
