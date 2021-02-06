//
//  PlayMenuViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/02.
//

import UIKit
import CoreData

class PlayMenuViewController: UIViewController {

    @IBOutlet var circles: [CircleIconView]!
    
    @IBOutlet var labels: [UILabel]!
    
    @IBAction func startPlayingSudoku(_ sender: Any) {
        performSegue(withIdentifier: "PlaySudoku", sender: sender)
    }
    
    var container: NSPersistentContainer?
    
    let menus = [
        NSLocalizedString("menu_newbie", comment: ""),
        NSLocalizedString("menu_beginner", comment: ""),
        NSLocalizedString("menu_medium", comment: ""),
        NSLocalizedString("menu_master", comment: ""),
        NSLocalizedString("menu_legend", comment: "")
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for i in 0..<5 {
            labels[i].text = menus[i]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for i in 0..<5 {
            labels[i].alpha = 0.0
            circles[i].alpha = 0.0
        }
        for i in 0..<5 {
            UIView.animateKeyframes(
                withDuration: 0.8,
                delay: Double(i)*0.1,
                options: [],
                animations: {
                    
                    // scale up firstly. note that items are invisible here
                    UIView.addKeyframe(
                        withRelativeStartTime: 0.0,
                        relativeDuration: 0.1/0.8,
                        animations: {
                            self.circles[i].transform = CGAffineTransform.identity
                                .scaledBy(x: 3.0, y: 3.0)
                        })
                    
                    //  the circles emerge and get smaller with overshoot
                    for frame in stride(from: 0.1, to: 0.7, by: 0.01) {
                        UIView.addKeyframe(
                            withRelativeStartTime: frame / 0.8,
                            relativeDuration: 0.01/0.8,
                            animations: {
                                self.circles[i].transform = CGAffineTransform.identity
                                    .scaledBy(x: AnimConstants.scaleDownInterpolation(frame+0.01),
                                              y: AnimConstants.scaleDownInterpolation(frame+0.01))
                                self.circles[i].alpha = CGFloat(10.0*(frame+0.01)/6.0 - 1.0/6.0)
                            })
                    }
                    
                    // the circles get back to ordinary size and the labels emerge
                    for frame in stride(from: 0.7, to: 0.8, by: 0.01) {
                        UIView.addKeyframe(
                            withRelativeStartTime: frame / 0.8,
                            relativeDuration: 0.01/0.8,
                            animations: {
                                self.circles[i].transform = CGAffineTransform.identity
                                    .scaledBy(x: AnimConstants.scaleUpInterpolation(frame+0.01),
                                              y: AnimConstants.scaleUpInterpolation(frame+0.01))
                                self.labels[i].alpha = CGFloat(10*(frame+0.01) - 7.0)
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
        if let identifier = segue.identifier, identifier == "PlaySudoku" {
            if let pvc = (segue.destination as? UINavigationController)?.topViewController
                as? PlaySudokuViewController {
                pvc.container = self.container
                if let tag = (sender as? UIView)?.tag {
                    switch tag {
                    case 0:
                        pvc.level = .newbie
                    case 1:
                        pvc.level = .beginner
                    case 2:
                        pvc.level = .medium
                    case 3:
                        pvc.level = .master
                    case 4:
                        pvc.level = .legend
                    default:
                        break
                    }
                }
            }
        }
    }
}
