//
//  SudokuNavigationViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/02/01.
//

import UIKit

// An interface navigation view controller between SudokuListViewController and SavedSudokuViewController.
// This view controller is responsible for transition animation between them.
class SudokuNavigationViewController: UINavigationController, UIViewControllerTransitioningDelegate {
    
    // used for transition animation
    var cellIndex: IndexPath?
    var sourceSudokuFrame: CGRect?        // sudokuView's frame in the SudouListViewController
    var sudokuViewSnapshot: UIView?       // sudokuView's snapshot in the SavedSudokuViewController
    var destinationSudokuFrame: CGRect?   // sudokuView's frame in the SavedSudokuViewController

    
    // MARK: - TransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        var sharedView: UIView? = nil
        var fromRect: CGRect? = nil
        let toRect: CGRect = calcSudokuViewFrame()
        if let sudokuListVC = source as? SudokuListViewController {
            if let index = cellIndex,
               let fromView = (sudokuListVC.sudokuListTableView.cellForRow(at: index) as? SudokuTableViewCell)?.sudokuView {
                sharedView = fromView
                fromRect = fromView.convert(fromView.bounds, to: sudokuListVC.view)
                sourceSudokuFrame = fromRect
            }
        }
        if sharedView != nil && fromRect != nil   {
            return SharedViewAnimatedTransitioning(
                sharedView: sharedView!, from: fromRect!, to: toRect, type: .present
            )
        }
        else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if sudokuViewSnapshot != nil && destinationSudokuFrame != nil && sourceSudokuFrame != nil {
            return SharedViewAnimatedTransitioning(
                sharedView: sudokuViewSnapshot!,
                from: destinationSudokuFrame!,
                to: sourceSudokuFrame!,
                type: .dismiss)
        }
        else {
            return nil
        }
    }
    
    
    private func calcSudokuViewFrame() -> CGRect {
        switch traitCollection.verticalSizeClass {
        case .regular, .unspecified:
            let screenSize = UIScreen.main.bounds.size
            let safeAreaInsets = UIApplication.shared.windows[0].safeAreaInsets
            let safeAreaTop = safeAreaInsets.top
            let safeAreaBottom = safeAreaInsets.bottom
            let navBarHeight: CGFloat = UIDevice.current.model == "iPad" ? 50 : 44
            let labelHeight = min(CGFloat(50), screenSize.width/10)
            let restHeight = screenSize.height - safeAreaTop
                - navBarHeight - labelHeight - safeAreaBottom
            if screenSize.width*5/4 < restHeight {
                // the sudokuView's width is equal to the screen width
                return CGRect(x: 0.0,
                              y: safeAreaTop + navBarHeight + labelHeight,
                              width: screenSize.width,
                              height: screenSize.width)
            }
            else {
                // the sudokuView's size shrinks for the number buttons
                let sudokuWidth = restHeight - screenSize.width*1/4
                return CGRect(x: (screenSize.width - sudokuWidth) / 2,
                              y: safeAreaTop + navBarHeight + labelHeight,
                              width: sudokuWidth,
                              height: sudokuWidth)
            }
        case .compact:
            let screenSize = UIScreen.main.bounds.size
            let safeAreaInsets = UIApplication.shared.windows[0].safeAreaInsets
            let safeAreaTop = safeAreaInsets.top
            let safeAreaBottom = safeAreaInsets.bottom
            let safeAreaLeft = safeAreaInsets.left
            let navBarHeight: CGFloat = UIDevice.current.model == "iPad" ? 50 : 44
            let sudokuWidth = screenSize.height - safeAreaTop - navBarHeight - safeAreaBottom
            
            return CGRect(x: safeAreaLeft,
                          y: safeAreaTop + navBarHeight,
                          width: sudokuWidth,
                          height: sudokuWidth)
            
        @unknown default:
            // deal with as regular case
            let screenSize = UIScreen.main.bounds.size
            let safeAreaInsets = UIApplication.shared.windows[0].safeAreaInsets
            let safeAreaTop = safeAreaInsets.top
            let safeAreaBottom = safeAreaInsets.bottom
            let navBarHeight: CGFloat = UIDevice.current.model == "iPad" ? 50 : 44
            let labelHeight = min(CGFloat(50), screenSize.width/10)
            let restHeight = screenSize.height - safeAreaTop
                - navBarHeight - labelHeight - safeAreaBottom
            if screenSize.width*5/4 < restHeight {
                // the sudokuView's width is equal to the screen width
                return CGRect(x: 0.0,
                              y: safeAreaTop + navBarHeight + labelHeight,
                              width: screenSize.width,
                              height: screenSize.width)
            }
            else {
                // the sudokuView's size shrinks for the number buttons
                let sudokuWidth = restHeight - screenSize.width*1/4
                return CGRect(x: (screenSize.width - sudokuWidth) / 2,
                              y: safeAreaTop + navBarHeight + labelHeight,
                              width: sudokuWidth,
                              height: sudokuWidth)
            }
        }
    }
}
