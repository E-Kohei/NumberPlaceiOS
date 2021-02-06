//
//  OperationMenuViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/08.
//

import UIKit

protocol IOperationMenuPresenter {
    func doStuffWhenItemSelected(itemAt: Int)
}

class OperationMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var menuTable: UITableView! {
        didSet {
            menuTable.delegate = self
            menuTable.dataSource = self
        }
    }
    
    var operationMenu: [String] = []
    
    
    @IBAction func closeMenu(_ sender: Any? = nil) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.5,
            delay: 0.0,
            options: [],
            animations: { [weak self] in
                self?.menuTable.transform = CGAffineTransform.identity.translatedBy(
                    x: (self?.view.bounds.width ?? 0.0)/2, y: 0)
            },
            completion: { [weak self] position in
                if let beingDismissed = self?.isBeingDismissed, !beingDismissed {
                    self?.presentingViewController?.dismiss(animated: true)
                }
            })
    }
    
    func closeMenuImmediately() {
        presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
//    // close this operation menu and then call completion
//    func closeMenu(completion: () -> Void) {
//        UIViewPropertyAnimator.runningPropertyAnimator(
//            withDuration: 0.5,
//            delay: 0.0,
//            options: [],
//            animations: { [weak self] in
//                self?.menuTable.transform = CGAffineTransform.identity.translatedBy(
//                    x: self?.view.bounds.width/2, y: 0)
//            },
//            completion: { positoin in
//                self.presentingViewController?.dismiss(animated: true, completion: completion)
//            }
//        )
//    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        menuTable.transform = CGAffineTransform.identity.translatedBy(
            x: self.view.bounds.width/2, y: 0)
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.5,
            delay: 0.0,
            options: [],
            animations: {
                self.menuTable.transform = CGAffineTransform.identity
            },
            completion: nil)
    }
    

    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return operationMenu.count + 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        if 0 <= row && row < operationMenu.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
            cell.textLabel?.text = operationMenu[row]
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "voidCell", for: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        if 0 <= row && row < operationMenu.count {
            if let presenter = presentingViewController?.contents as? IOperationMenuPresenter {
                presenter.doStuffWhenItemSelected(itemAt: row)
            }
        }
        else {
            closeMenu()
        }
    }

}


extension UIViewController {
    var contents: UIViewController? {
        if let nvc = self as? UINavigationController {
            return nvc.topViewController
        }
        else {
            return self
        }
    }
}
