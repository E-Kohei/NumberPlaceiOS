//
//  MakeSudokuViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/02.
//

import UIKit
import CoreData
import Sudoku

class MakeSudokuViewController: UIViewController, SudokuViewDelegate, IOperationMenuPresenter {

    @IBOutlet weak var messageLabel: UILabel!
    var backgroundText: String? {
        didSet {
            messageLabel.text = backgroundText
            // if new value is not blank, clear it 5 seconds later
            if backgroundText != nil && backgroundText != "" {
                if let currentTimer = textDeleteTimer, currentTimer.isValid {
                    currentTimer.invalidate()
                }
                textDeleteTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] timer in
                    self?.backgroundText = ""
                }
            }
        }
    }
    
    @IBOutlet weak var sudokuView: SudokuView! {
        didSet { sudokuView.delegate = self }
    }
    
    
    @IBOutlet var changeModeButtons: [UIButton]!
    
    @IBOutlet var numberButtons: [UIButton]!
    
    private weak var textDeleteTimer: Timer?
    
    var container: NSPersistentContainer?
    
    var inputMode: InputMode = .number
    var logStack: [InputLog] = []
    
    /* button animation */
    var buttonAnimators: [UIButton:UIViewPropertyAnimator] = [:]
    
    /* SudokuViewDelegate properties */
    var sudoku: Sudoku = Sudoku(size:3)
    var note: Note = Note(size: 3)
    var contradictionM: [[Bool]] = {
        let matrix = Array(repeating: Array(repeating: false, count: 9), count: 9)
        return matrix
    }()
    
    
    @IBAction func changeInputMode(_ sender: UIButton) {
        if inputMode == .number {
            inputMode = .note
            if let icon = UIImage(named: "sudoku_icon_note") {
                changeModeButtons.forEach {
                    $0.setImage(icon, for: .normal)
                }
            }
        }
        else {
            inputMode = .number
            if let icon = UIImage(named: "sudoku_icon_number") {
                changeModeButtons.forEach {
                    $0.setImage(icon, for: .normal)
                }
            }
        }
    }
    
    @IBAction func enterNumber(_ sender: UIButton) {
        
        // fade out color
        buttonAnimators[sender]?.stopAnimation(true)
        buttonAnimators[sender]?.addAnimations {
            sender.backgroundColor = UIColor.white
        }
        buttonAnimators[sender]?.startAnimation()
        
        if let cell = sudokuView.selectedCell {
            if let title = sender.currentTitle {
                // clear the cell
                if title == "C" {
                    switch inputMode {
                    case .number:
                        let before = sudoku[cell.row, cell.col]
                        if sudoku.setNumber(row: cell.row, col: cell.col, number: 0) {
                            // store log object
                            let log = InputLog(before: before, after: 0, at: cell, mode: .number)
                            logStack.append(log)
                        }
                    case .note:
                        let before = note[cell.row, cell.col]
                        note[cell.row, cell.col] = 0
                        let log = InputLog(before: before, after: 0, at: cell, mode: .note)
                        logStack.append(log)
                    }
                }
                // fill in a number or toggle note
                else {
                    if let n = Int(title) {
                        switch inputMode {
                        case .number:
                            let before = sudoku[cell.row, cell.col]
                            if sudoku.setNumber(row: cell.row, col: cell.col, number: n) {
                                // store log object
                                let log = InputLog(before: before, after: n, at: cell, mode: .number)
                                logStack.append(log)
                            }
                        case .note:
                            let before = note[cell.row, cell.col]
                            note.toggleNoteNumber(row: cell.row, col: cell.col, m: n)
                            let after = note[cell.row, cell.col]
                            let log = InputLog(before: before, after: after, at: cell, mode: .note)
                            logStack.append(log)
                        }
                    }
                }
                sudokuView.selectedCell = cell.nextCell(withSize: 3)
                contradictionM = findContradictions(sudoku: sudoku)
                sudokuView.setNeedsDisplay()
            }
        }
    }
    
    @IBAction func colorButton(_ sender: UIButton) {
        
        // fade in color
        buttonAnimators[sender]?.stopAnimation(true)
        buttonAnimators[sender]?.addAnimations {
            sender.backgroundColor = CustomColor.faintblue
        }
        buttonAnimators[sender]?.startAnimation()
    }
    

    @IBAction func fadeOutColor(_ sender: UIButton) {
        buttonAnimators[sender]?.stopAnimation(true)
        buttonAnimators[sender]?.addAnimations {
            sender.backgroundColor = UIColor.white
        }
        buttonAnimators[sender]?.startAnimation()
    }
    
    @IBAction func undoInput(_ sender: Any) {
        if let log = logStack.popLast() {
            let mode = log.mode
            let cell = log.cell
            let n = log.beforeVal
            switch mode {
            case .number:
                sudoku.setNumber(row: cell.row, col: cell.col, number: n)
                sudokuView.setNeedsDisplay()
            case .note:
                note[cell.row, cell.col] = n
                sudokuView.setNeedsDisplay()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: sudokuView,
                                         action: #selector(SudokuView.selectCell(sender:)))
        sudokuView.addGestureRecognizer(tap)
        
        changeModeButtons.forEach {
            $0.imageView?.contentMode = .scaleAspectFit
        }
        changeModeButtons.forEach {
            $0.adjustsImageWhenHighlighted = false
        }
        if let numberModeImage = UIImage(named: "sudoku_icon_number") {
            changeModeButtons.forEach {
                $0.setImage(numberModeImage, for: .normal)
            }
        }
        
        // configure button font
        var buttonFont = UIFont.preferredFont(forTextStyle: .body).withSize(30)
        buttonFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: buttonFont)
        for button in numberButtons {
            button.titleLabel?.font = buttonFont
        }
        
        // create button animator
        for button in numberButtons {
            buttonAnimators[button] = UIViewPropertyAnimator(duration: 0.4, curve: .linear)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // stop the timer
        textDeleteTimer?.invalidate()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, identifier == "Show menu" {
            if let destination = segue.destination as? OperationMenuViewController {
                destination.operationMenu = [
                    NSLocalizedString("action_save", comment: ""),
                    NSLocalizedString("action_clear_note", comment: ""),
                    NSLocalizedString("action_inspect", comment: ""),
                    NSLocalizedString("action_solve", comment: ""),
                    NSLocalizedString("action_quit", comment: "")
                ]
            }
        }
    }

    /* IOperationMenuOwner method */
    func doStuffWhenItemSelected(itemAt: Int) {
        switch itemAt {
        case 0:
            // save the current puzzle
            saveSudoku()
            closeMenu()
        case 1:
            // clear notes
            clearNotes()
            closeMenu()
        case 2:
            // check if whether the current sudoku is solvable
            inspectCurrentSudoku()
            closeMenu()
        case 3:
            // solve the current puzzle
            closeMenuImmediately()
            alertForSolveSudoku()
            closeMenu()
        case 4:
            // exit
            closeMenuImmediately()
            presentingViewController?.dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
    
    private func saveSudoku() {
        if let context = container?.viewContext {
            let newSudoku = SudokuItem(context: context)
            newSudoku.state = SudokuOperationState.making.rawValue
            newSudoku.time = -1
            newSudoku.sudokuString = serializeSudoku(sudoku: sudoku)
            do {
                try context.save()
                backgroundText = NSLocalizedString("message_save_successed", comment: "")
            }
            catch {
                backgroundText = NSLocalizedString("message_save_failed", comment: "")
            }
        }
    }
    
    private func clearNotes() {
        note.clear()
        sudokuView.setNeedsDisplay()
    }
    
    private func inspectCurrentSudoku() {
        backgroundText = NSLocalizedString("message_checking", comment: "")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let currentSudoku = self?.sudoku {
                let status = analyzeSudoku(sudoku: currentSudoku)
                switch status {
                case .solvable:
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_solvable", comment: "")
                    }
                case .fewNumbers, .unsolvable:
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_not_solvable", comment: "")
                    }
                case .hasSomeSolutions:
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_several_solutions", comment: "")
                    }
                case .unknown:
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_computation_error", comment: "")
                    }
                }
            }
        }
    }
    
    private func solveCurrentSudoku() {
        backgroundText = NSLocalizedString("message_solving", comment: "")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let currentSudoku = self?.sudoku {
                let result = solveSudokuWithTrials(sudoku: currentSudoku)
                switch result.status {
                case .solvable:
                    if self != nil {
                        try? Sudoku.copySudoku(from: result.answer!, to: self!.sudoku)
                        self!.contradictionM = findContradictions(sudoku: result.answer!)
                    }
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_solving_finished", comment: "")
                        self?.sudokuView.setNeedsDisplay()
                    }
                case .fewNumbers, .unsolvable:
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_not_solvable", comment: "")
                    }
                case .hasSomeSolutions:
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_several_solutions", comment: "")
                    }
                case .unknown:
                    DispatchQueue.main.async {
                        self?.backgroundText = NSLocalizedString("message_computation_error", comment: "")
                    }
                }
            }
        }
    }
    
    private func closeMenu() {
        if let operationMenuVC = presentedViewController as? OperationMenuViewController {
            operationMenuVC.closeMenu()
        }
    }
    
    private func closeMenuImmediately() {
        if let operationMenuVC = presentedViewController as? OperationMenuViewController {
            operationMenuVC.closeMenuImmediately()
        }
    }
    
    private func alertForSolveSudoku() {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("alert_text_solve", comment: ""),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_no", comment: ""),
                            style: .cancel))
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_yes", comment: ""),
                            style: .default,
                            handler: { action in
                                self.solveCurrentSudoku()
                            }))
        present(alert, animated: true)
    }
}


extension Cell {
    func nextCell(withSize: Int) -> Cell {
        let ss = withSize*withSize
        if self.col == ss-1 {
            if self.row == ss-1 {
                // end of the squares, go back to the first
                return Cell(row: 0, col: 0)
            }
            else {
                // end of a row
                return Cell(row: self.row+1, col: 0)
            }
        }
        else {
            // the next cell is right cell
            return Cell(row: self.row, col: self.col+1)
        }
    }
}
