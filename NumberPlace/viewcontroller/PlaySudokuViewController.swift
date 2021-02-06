//
//  ViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2020/11/28.
//

import UIKit
import CoreData
import Sudoku

class PlaySudokuViewController: UIViewController, SudokuViewDelegate, IOperationMenuPresenter {
    
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
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var sudokuView: SudokuView! {
        didSet { sudokuView.delegate = self }
    }
    
    @IBOutlet var changeModeButtons: [UIButton]!
    
    @IBOutlet var numberButtons: [UIButton]!
    
    private weak var timer: Timer?
    private weak var textDeleteTimer: Timer?
    
    var container: NSPersistentContainer?
    
    var level: SudokuLevel = .beginner
    var inputMode: InputMode = .number
    var logStack: [InputLog] = []
    var hasSaved = false
    
    /* button animation */
    var buttonAnimators: [UIButton:UIViewPropertyAnimator] = [:]

    /* SudokuViewDelegate variables */
    var sudoku: Sudoku = Sudoku(size: 3)
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
        let animator = buttonAnimators[sender]
        animator?.stopAnimation(true)
        animator?.addAnimations {
            sender.backgroundColor = UIColor.white
        }
        animator?.startAnimation()

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
                checkIfSolved()
                contradictionM = findContradictions(sudoku: sudoku)
                sudokuView.setNeedsDisplay()
            }
        }
    }
    
    @IBAction func colorButton(_ sender: UIButton) {
        let animator = buttonAnimators[sender]
        animator?.stopAnimation(true)
        animator?.addAnimations {
            sender.backgroundColor = CustomColor.faintpink
        }
        animator?.startAnimation()
    }
    
    @IBAction func fadeOutColor(_ sender: UIButton) {
        let animator = buttonAnimators[sender]
        animator?.stopAnimation(true)
        animator?.addAnimations {
            sender.backgroundColor = UIColor.white
        }
        animator?.startAnimation()
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
        
        timerLabel.text = "00:00"
        
        changeModeButtons.forEach {
            $0.imageView?.contentMode = .scaleAspectFit
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
        
        // make sudoku in background
        DispatchQueue.global(qos: .userInitiated).async {
            if let createdSudoku = self.makeSudoku() {
                self.sudoku = createdSudoku
                
                DispatchQueue.main.async {
                    self.backgroundText = NSLocalizedString("message_making_successed", comment: "")
                    self.sudokuView.setNeedsDisplay()
                }
            }
            else {
                DispatchQueue.main.async {
                    self.backgroundText = NSLocalizedString("message_making_failed", comment: "")
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let time = Time.parse(timeStr: self.timerLabel.text ?? "") {
                self.timerLabel.text = (time+1).toString(showHourIfZero: false)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // stop the timer
        timer?.invalidate()
        textDeleteTimer?.invalidate()
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, identifier == "Show menu" {
            if let mvc = segue.destination as? OperationMenuViewController {
                mvc.operationMenu = [
                    NSLocalizedString("action_new", comment: ""),
                    NSLocalizedString("action_save", comment: ""),
                    NSLocalizedString("action_restart", comment: ""),
                    NSLocalizedString("action_clear_note", comment: ""),
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
            // play new puzzle
            closeMenuImmediately()
            alertForNewPuzzle()
            closeMenu()
        case 1:
            // save the current puzzle
            saveSudoku()
            hasSaved = true
            closeMenu()
        case 2:
            // restart
            closeMenuImmediately()
            alertForRestart()
            closeMenu()
        case 3:
            // clear notes
            clearNotes()
            closeMenu()
        case 4:
            // sudoku the current puzzle
            closeMenuImmediately()
            alertForSolveSudoku()
            closeMenu()
        case 5:
            // exit
            closeMenuImmediately()
            if !hasSaved {
                alertForNotSaved()
            }
            else {
                presentingViewController?.dismiss(animated: true, completion: nil)
            }
        default:
            break
        }
    }
    
    // MARK: - Private methods
    
    private func checkIfSolved() {
        if sudoku.isSolved() {
            // stop the timer
            timer?.invalidate()
            // alert that you solved the sudoku!
            let alertText = String(
                format: NSLocalizedString("alert_text_solved", comment: ""),
                timerLabel.text ?? "")
            let alert = UIAlertController(
                title: NSLocalizedString("alert_title_solved", comment: ""),
                message: alertText,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(
                                title: NSLocalizedString("alert_action_ok",comment: ""),
                                style: .default,
                                handler: nil))
            present(alert, animated: true)
        }
    }
    
    private func playNewSudoku() {
        backgroundText = NSLocalizedString("message_making", comment: "")
        // reset the timer
        timer?.invalidate()
        timerLabel.text = "00:00"
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if let time = Time.parse(timeStr: self.timerLabel.text ?? "") {
                    self.timerLabel.text = (time+1).toString(showHourIfZero: false)
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let createdSudoku = self?.makeSudoku() {
                self?.sudoku = createdSudoku
                self?.contradictionM = findContradictions(sudoku: createdSudoku)
                
                DispatchQueue.main.async {
                    self?.backgroundText = NSLocalizedString("message_making_successed", comment: "")
                    self?.sudokuView.setNeedsDisplay()
                    // clear log stack
                    self?.logStack.removeAll()
                }
            }
            else {
                DispatchQueue.main.async {
                    self?.backgroundText = NSLocalizedString("message_making_failed", comment: "")
                }
            }
        }
    }
    
    private func saveSudoku() {
        if let context = container?.viewContext {
            let newSudoku = SudokuItem(context: context)
            newSudoku.state = SudokuOperationState.playing.rawValue
            newSudoku.time = 1
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
    
    private func restart() {
        // reset the timer
        timer?.invalidate()
        timerLabel.text = "00:00"
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if let time = Time.parse(timeStr: self.timerLabel.text ?? "") {
                    self.timerLabel.text = (time+1).toString(showHourIfZero: false)
                }
            }
        }
        // clear log stack
        logStack.removeAll()
        sudoku.resetSudoku()
        sudokuView.setNeedsDisplay()
    }
    
    private func clearNotes() {
        note.clear()
        sudokuView.setNeedsDisplay()
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
    
    private func alertForNotSaved() {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("alert_text_notsaved", comment: ""),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_cancel", comment: ""),
                            style: .cancel))
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_quit", comment: ""),
                            style: .destructive,
                            handler: { action in
                                self.presentingViewController?.dismiss(animated: true, completion: nil)
                            }))
        present(alert, animated: true)
    }
    
    private func alertForNewPuzzle() {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("alert_text_newpuzzle", comment: ""),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_no", comment: ""),
                            style: .cancel))
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_yes", comment: ""),
                            style: .default,
                            handler: { action in
                                self.playNewSudoku()
                            }))
        present(alert, animated: true)
    }
    
    private func alertForRestart() {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("alert_text_restart", comment: ""),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_no", comment: ""),
                            style: .cancel))
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_yes", comment: ""),
                            style: .default,
                            handler: { action in
                                self.restart()
                            }))
        present(alert, animated: true)
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
    
    private func makeSudoku() -> Sudoku? {
        var resFile: String
        switch level {
        case .newbie, .beginner, .medium, .master:
            resFile = level.rawValue + String( Int.random(in: 0..<50) )
        case .legend:
            resFile = level.rawValue + String( Int.random(in: 0..<5) )
        }
        
        if let url = Bundle.main.url(forResource: resFile, withExtension: "txt", subdirectory: level.rawValue),
           let sudokuS = try? String(contentsOf: url), let parsed = parseSudoku(sudokuStr: sudokuS, size: 3) {
            switch level {
            case .newbie, .beginner, .medium, .master:
                transformSudokuKeepingSymmetry(sudoku: parsed)
            case .legend:
                transformSudokuRandomly(sudoku: parsed)
            }
            parsed.fixNumbers()
            return parsed
        }
        else {
            return nil
        }
        
    }
}
