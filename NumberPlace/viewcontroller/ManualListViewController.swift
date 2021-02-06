//
//  ManualListViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/02/04.
//

import UIKit

class ManualListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var manualTableView: UITableView! {
        didSet {
            manualTableView.delegate = self
            manualTableView.dataSource = self
        }
    }
    
    var manualMenu = [
        NSLocalizedString("menu_basic_operation", comment: ""),
        NSLocalizedString("menu_play_manual", comment: ""),
        NSLocalizedString("menu_make_manual", comment: ""),
        NSLocalizedString("menu_saved_manual", comment: "")
    ]

    @IBAction func closeManual(_ sender: Any) {
        navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show detail manual", let cell = sender as? UITableViewCell {
            if let destination = segue.destination as? ManualViewController {
                if let row = manualTableView?.indexPath(for: cell)?.row {
                    destination.manualID = row
                }
            }
        }
    }
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manualMenu.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = manualTableView.dequeueReusableCell(withIdentifier: "manualCell", for: indexPath)
        cell.textLabel?.text = manualMenu[indexPath.row]
        return cell
    }
}
