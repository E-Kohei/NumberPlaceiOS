//
//  HomeMenuViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/02.
//

import UIKit
import CoreData

class HomeMenuViewController: UIViewController{
        
    @IBOutlet private var circles: [CircleIconView]!
    @IBOutlet private var labels: [UILabel]!
    
    
    @IBAction func segueToPlayMenu(_ sender: Any) {
        performSegue(withIdentifier: "Play", sender: sender)
    }
    
    @IBAction func segueToMakeSudoku(_ sender: Any) {
        performSegue(withIdentifier: "Make", sender: sender)
    }
    
    @IBAction func segueToCollections(_ sender: Any) {
        performSegue(withIdentifier: "Collections", sender: sender)
    }
    
    // CoreData container
    var container: NSPersistentContainer?
    
    let menus = [
        NSLocalizedString("menu_play", comment: ""),
        NSLocalizedString("menu_make", comment: ""),
        NSLocalizedString("menu_collections", comment: "")
    ]
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup persistent container
        container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        
        for i in 0..<3 {
            labels[i].text = menus[i]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for i in 0..<3 {
            labels[i].alpha = 0.0
            circles[i].alpha = 0.0
        }
        for i in 0..<3 {
            UIView.animateKeyframes(
                withDuration: AnimConstants.circleDropAnimDuration,
                delay: Double(i)*0.1,
                options: [],
                animations: {
                    
                    UIView.addKeyframe(
                        withRelativeStartTime: 0.0,
                        relativeDuration: AnimConstants.relativePreparationDuration,
                        animations: {
                            self.circles[i].transform = CGAffineTransform.identity
                                .scaledBy(x: 3.0, y: 3.0)
                        })
                    
                    for frame in stride(from: 0.1, to: 0.7, by: AnimConstants.plotInterval) {
                        UIView.addKeyframe(
                            withRelativeStartTime: frame / AnimConstants.circleDropAnimDuration,
                            relativeDuration: AnimConstants.relativePlotInterval,
                            animations: {
                                self.circles[i].transform = CGAffineTransform.identity
                                    .scaledBy(x: AnimConstants.scaleDownInterpolation(frame+AnimConstants.plotInterval),
                                              y: AnimConstants.scaleDownInterpolation(frame+AnimConstants.plotInterval))
                                self.circles[i].alpha = AnimConstants.circleAlphaInterpolation(frame)
                            })
                    }
                    
                    for frame in stride(from: 0.7, to: 0.8, by: AnimConstants.plotInterval) {
                        UIView.addKeyframe(
                            withRelativeStartTime: frame / AnimConstants.circleDropAnimDuration,
                            relativeDuration: AnimConstants.relativePlotInterval,
                            animations: {
                                self.circles[i].transform = CGAffineTransform.identity
                                    .scaledBy(x: AnimConstants.scaleUpInterpolation(frame+AnimConstants.plotInterval),
                                              y: AnimConstants.scaleUpInterpolation(frame+AnimConstants.plotInterval))
                                self.labels[i].alpha = AnimConstants.labelAlphaInterpolation(frame)
                            })
                    }
                },
                completion: { position in
                    self.circles[i].transform = CGAffineTransform.identity
                    self.circles[i].alpha = 1.0
                    self.labels[i].alpha = 1.0
                })
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "Play":
                if let psvc = segue.destination as? PlayMenuViewController {
                    psvc.container = self.container
                }
            case "Make":
                if let msvc = (segue.destination as? UINavigationController)?.topViewController
                    as? MakeSudokuViewController {
                    msvc.container = self.container
                }
            case "Collections":
                if let slvc = segue.destination as? SudokuListViewController {
                    slvc.container = self.container
                }
            default:
                break
                
            }
        }
    }
}

