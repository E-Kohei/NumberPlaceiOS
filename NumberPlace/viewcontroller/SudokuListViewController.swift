//
//  SudokuListViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/11.
//

import UIKit
import CoreData
import Sudoku

class SudokuListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                                NSFetchedResultsControllerDelegate,
                                UIViewControllerTransitioningDelegate {
    
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var sudokuListTableView: UITableView! {
        didSet {
            sudokuListTableView.delegate = self
            sudokuListTableView.dataSource = self
        }
    }
    
    var container: NSPersistentContainer? {
        didSet{ updateList() }
    }
    
    var fetchedResultController: NSFetchedResultsController<SudokuItem>? {
        didSet {
            fetchedResultController?.delegate = self
        }
    }
    
    var submenuIcons: [UIImage?] = []
    var submenuLabels: [NSAttributedString?] = []
    
    
    @IBAction func submenuAction(sender: RoundRectContainerView, forEvent event: UIEvent) {
        if let touchLoc = event.touches(for: sender)?.first?.location(in: sender) {
            if let context = container?.viewContext {
                let half = sender.bounds.width / 2
                if 0 <= touchLoc.x && touchLoc.x < half {
                    if let showingIndex = showingSubmenuIndex,
                       let sudokuItem = fetchedResultController?.object(at: showingIndex),
                       let sudokuCell = sudokuListTableView.cellForRow(at: showingIndex)
                        as? SudokuTableViewCell {
                        alertForDelete(sudokuCell: sudokuCell, sudokuItem: sudokuItem, context: context)
                    }
                }
                else {
                    if let showingIndex = showingSubmenuIndex,
                       let sudokuItem = fetchedResultController?.object(at: showingIndex) {
                        let newSudoku = SudokuItem(context: context)
                        newSudoku.state = sudokuItem.state
                        newSudoku.time = sudokuItem.time
                        newSudoku.sudokuString = sudokuItem.sudokuString
                        try? context.save()
                    }
                }
            }
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyLabel.text = NSLocalizedString("empty_text", comment: "")

        if let background = UIImage(named: "dripdrop_green") {
            view.backgroundColor = UIColor(patternImage: background)
        }
        
        // configure submenu images and labels
        submenuIcons = [UIImage(systemName: "trash")?.withTintColor(UIColor.red),
                        UIImage(systemName: "square.on.square")?.withTintColor(UIColor.blue)
        ]
        var font = UIFont.preferredFont(forTextStyle: .body).withSize(20)
        font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        submenuLabels = [NSAttributedString(string: NSLocalizedString("delete_text", comment: ""),
                                            attributes: [.font : font,
                                                         .paragraphStyle : paragraphStyle]),
                         NSAttributedString(string: NSLocalizedString("copy_text", comment: ""),
                                            attributes: [.font : font,
                                                         .paragraphStyle : paragraphStyle])
        ]
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, identifier == "SavedSudoku" {
            if let cell = sender as? SudokuTableViewCell,
               let indexPath = sudokuListTableView.indexPath(for: cell),
               let destination = segue.destination as? SudokuNavigationViewController {
                if let savedSudokuVC = destination.topViewController as? SavedSudokuViewController {
                    savedSudokuVC.container = self.container
                    savedSudokuVC.sudokuItem = fetchedResultController?.object(at: indexPath)
                }
                destination.cellIndex = indexPath
                destination.modalPresentationStyle = .custom
                destination.transitioningDelegate = destination
            }
        }
        else if let identifier = segue.identifier, identifier == "MakeFromList" {
            if let msvc = (segue.destination as? UINavigationController)?.topViewController
                as? MakeSudokuViewController {
                msvc.container = self.container
            }
        }
    }
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultController?.sections, sections.count > 0 {
            let numberOfRows = sections[section].numberOfObjects
            emptyLabel.isHidden = (numberOfRows != 0)
            return numberOfRows
        }
        else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sudokuCell", for: indexPath)
        if let sudokuCell = cell as? SudokuTableViewCell {
            if let sudokuItem = fetchedResultController?.object(at: indexPath) {
                try? Sudoku.copySudoku(from: parseSudoku(sudokuStr: sudokuItem.sudokuString!, size: 3)!,
                                       to: sudokuCell.sudoku)
                sudokuCell.contradictionM = findContradictions(sudoku: sudokuCell.sudoku)
                sudokuCell.stateLabel.text = SudokuOperationState(rawValue: sudokuItem.state)?.description
                if sudokuItem.time != -1 {
                    sudokuCell.playingTimeLabel.text =
                        sudokuItem.time.toString(showHourIfZero: false)
                }
                else {
                    sudokuCell.playingTimeLabel.text = ""
                }
                sudokuCell.sudokuView.setNeedsDisplay()
            }
            sudokuCell.submenuView.menuIcons = submenuIcons
            sudokuCell.submenuView.menuLabels = submenuLabels
            sudokuCell.submenuView.addTarget(self, action: #selector(submenuAction(sender:forEvent:)), for: .touchUpInside)
        }
        return cell
    }
    
    private var swiping = false
    private var showingSubmenuIndex: IndexPath?
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell = sudokuListTableView.cellForRow(at: indexPath) as? SudokuTableViewCell {
            // if there is another showing submenu, hide it and show new one
            if let showingIndex = showingSubmenuIndex,
               let showingCell = sudokuListTableView.cellForRow(at: showingIndex) as? SudokuTableViewCell,
               showingIndex != indexPath {
                animateToHideSubmenu(cell: showingCell)
            }
            animateToShowSubmenu(cell: cell)
            showingSubmenuIndex = indexPath
        }
        swiping = true
        return UISwipeActionsConfiguration()
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let showingIndex = showingSubmenuIndex,
           let cell = sudokuListTableView.cellForRow(at: showingIndex) as? SudokuTableViewCell {
            animateToHideSubmenu(cell: cell)
            showingSubmenuIndex = nil
        }
        swiping = true
        return UISwipeActionsConfiguration()
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // if swiping now, prevent selecting a row
        if swiping {
            swiping = false
            return nil
        }
        else {
            return indexPath
        }
    }
    
    // MARK: - ScrollView
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let showingIndex = showingSubmenuIndex,
           let sudokuCell = sudokuListTableView.cellForRow(at: showingIndex) as? SudokuTableViewCell{
            showingSubmenuIndex = nil
            animateToHideSubmenu(cell: sudokuCell)
        }
    }
    
    
    // MARK: - NSFetchedResultControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sudokuListTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            sudokuListTableView.insertRows(at: [newIndexPath!], with: .right)
        case .delete:
            sudokuListTableView.deleteRows(at: [indexPath!], with: .left)
        case .update:
            sudokuListTableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            sudokuListTableView.deleteRows(at: [indexPath!], with: .fade)
            sudokuListTableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sudokuListTableView.endUpdates()
        if let sections = controller.sections {
            if sections[0].numberOfObjects == 0 {
                emptyLabel.isHidden = false
            }
        }
    }
    
    // MARK: - Private methods
    
    private func updateList() {
        if let context = container?.viewContext {
            let request: NSFetchRequest<SudokuItem> = SudokuItem.fetchRequest()
            request.sortDescriptors = []
            //request.predicate = NSPredicate(format: "id > -1")
            fetchedResultController = NSFetchedResultsController<SudokuItem>(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            try? fetchedResultController?.performFetch()
            sudokuListTableView?.reloadData()
        }
    }
    
    
    private func animateToShowSubmenu(cell: SudokuTableViewCell) {
        let halfSize = cell.contentView.bounds.width / 2
        cell.submenuView.isHidden = false
        cell.submenuView.alpha = 0.0
        cell.submenuView.contentMode = .redraw
        cell.submenuWidthConstraint.constant = halfSize
        
        UIView.animate(
            withDuration: submenuOpenDuration,
            animations: {
                cell.contentView.layoutIfNeeded()
                cell.submenuView.alpha = 1.0
        })
    }
    
    private func animateToHideSubmenu(cell: SudokuTableViewCell) {
        cell.submenuView.alpha = 1.0
        cell.submenuView.contentMode = .scaleToFill
        cell.submenuWidthConstraint.constant = 0
        
        UIView.animate(
            withDuration: submenuDisappearDuration,
            animations: {
                cell.contentView.layoutIfNeeded()
                cell.submenuView.alpha = 0.0
            },
            completion: {succecced in
                cell.submenuView.isHidden = true
                cell.submenuView.alpha = 1.0
            })
    }
    
    private func hideSubmenuImmediately(cell: SudokuTableViewCell) {
        cell.submenuView.contentMode = .scaleToFill
        cell.submenuWidthConstraint.constant = 0
        cell.submenuView.isHidden = true
    }
    
    private func alertForDelete(sudokuCell: SudokuTableViewCell, sudokuItem: SudokuItem, context: NSManagedObjectContext) {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("alert_text_delete", comment: ""),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_cancel", comment: ""),
                            style: .cancel))
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_delete", comment: ""),
                            style: .destructive,
                            handler: { action in
                                self.hideSubmenuImmediately(cell: sudokuCell)
                                context.delete(sudokuItem)
                                try? context.save()
                            }))
        present(alert, animated: true)
    }
}
