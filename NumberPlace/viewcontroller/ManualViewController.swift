//
//  ManualViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/02/04.
//

import UIKit

class ManualViewController: UITableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var introductionLabel: UILabel!
    @IBOutlet weak var manualImageView1: UIImageView!
    @IBOutlet weak var manualDocument1: UILabel!
    @IBOutlet weak var manualImageView2: UIImageView!
    @IBOutlet weak var manualDocument2: UILabel!
    
    var manualID: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lang = NSLocalizedString("lang", comment: "")
        let rawDirName = (lang == "JA") ? "raw-ja" : "raw"
        
         // configure font
        var titleFont = UIFont.preferredFont(forTextStyle: .title1).withSize(40)
        titleFont = UIFontMetrics(forTextStyle: .title1).scaledFont(for: titleFont)

        var bodyFont = UIFont.preferredFont(forTextStyle: .body).withSize(20)
        bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)

        
        switch manualID {
        case 0:
            // basic operation
            titleLabel.attributedText = NSAttributedString(
                string: NSLocalizedString("menu_basic_operation", comment: ""),
                attributes: [ .font: titleFont ])
            introductionLabel.text = ""
            manualDocument1.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_basic_operation_1", subdirectory: rawDirName),
                attributes: [ .font: bodyFont])
            manualDocument2.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_basic_operation_2", subdirectory: rawDirName),
                attributes: [ .font: bodyFont ])
            manualImageView1.image = UIImage(named: "manual_basic_1_" + lang)
            manualImageView2.image = UIImage(named: "manual_basic_2_" + lang)
            
        case 1:
            // play manual
            titleLabel.attributedText = NSAttributedString(
                string: NSLocalizedString("menu_play_manual", comment: ""),
                attributes: [ .font: titleFont ])
            introductionLabel.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_intro_play", subdirectory: rawDirName),
                attributes: [ .font: bodyFont ])
            manualDocument1.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_play_puzzle_1", subdirectory: rawDirName),
                attributes: [ .font: bodyFont ])
            manualDocument2.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_play_puzzle_2", subdirectory: rawDirName),
                attributes: [ .font: bodyFont ])
            manualImageView1.image = UIImage(named: "manual_play_1_" + lang)
            manualImageView2.image = UIImage(named: "manual_play_2_" + lang)
            
        case 2:
            // make manual
            titleLabel.attributedText = NSAttributedString(
                string: NSLocalizedString("menu_make_manual", comment: ""),
                attributes: [ .font: titleFont ])
            introductionLabel.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_intro_make", subdirectory: rawDirName),
                attributes: [ .font: bodyFont])
            manualDocument1.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_make_puzzle", subdirectory: rawDirName),
                attributes: [ .font: bodyFont])
            manualDocument2.text = ""
            manualImageView1.image = UIImage(named: "manual_make_1_" + lang)
            
        case 3:
            // collection manual
            titleLabel.attributedText = NSAttributedString(
                string: NSLocalizedString("menu_saved_manual", comment: ""),
                attributes: [ .font: titleFont ])
            introductionLabel.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_intro_collection", subdirectory: rawDirName),
                attributes: [ .font: bodyFont])
            manualDocument1.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_collection_1", subdirectory: rawDirName),
                attributes: [ .font: bodyFont])
            manualDocument2.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_collection_2", subdirectory: rawDirName),
                attributes: [ .font: bodyFont])
            manualImageView1.image = UIImage(named: "manual_collection_1_" + lang)
            manualImageView2.image = UIImage(named: "manual_collection_2_" + lang)
            
        default:
            manualDocument1.attributedText = NSAttributedString(
                string: readFile(txtFile: "manual_none", subdirectory: rawDirName),
                attributes: [ .font: bodyFont])
        }
        
        if titleLabel.text != nil && titleLabel.text != "" {
            titleLabel.sizeToFit()
        }
        if manualDocument1 != nil && manualDocument1.text != "" {
            titleLabel.sizeToFit()
        }
        if manualDocument2.text != nil && manualDocument2.text != "" {
            manualDocument2.sizeToFit()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    private func readFile(txtFile: String, subdirectory: String?) -> String {
        if let url = Bundle.main.url(
            forResource: txtFile,
            withExtension: "txt",
            subdirectory: subdirectory) {
            let content = (try? String(contentsOf: url))
                ?? NSLocalizedString("message_io_error", comment: "")
            return content
        }
        else {
            return NSLocalizedString("message_io_error", comment: "")
        }
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
