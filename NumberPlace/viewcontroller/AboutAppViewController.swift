//
//  AboutAppViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/02/05.
//

import UIKit

class AboutAppViewController: UITableViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var aboutAppLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let background = UIImage(named: "dripdrop_blue") {
            tableView.backgroundColor = UIColor(patternImage: background)
        }

        let lang = NSLocalizedString("lang", comment: "")
        let rawDirName = (lang == "JA") ? "raw-ja" : "raw"
        
        var titleFont = UIFont.preferredFont(forTextStyle: .title1).withSize(40)
        titleFont = UIFontMetrics(forTextStyle: .title1).scaledFont(for: titleFont)
        let titleText = NSAttributedString(
            string: NSLocalizedString("title_about_app", comment: ""),
            attributes: [
                .font: titleFont
            ]
        )
        
        var bodyFont = UIFont.preferredFont(forTextStyle: .body).withSize(20)
        bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
        let body = NSAttributedString(
            string: readFile(txtFile: "about_app", subdirectory: rawDirName),
            attributes: [ .font: bodyFont ])
        
        titleLabel.attributedText = titleText
        aboutAppLabel.attributedText = body
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

}
