//
//  SavedSudokuViewController.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/18.
//

import UIKit
import CoreData
import Sudoku

class SavedSudokuViewController: UIViewController, SudokuViewDelegate, IOperationMenuPresenter,
                                 UIViewControllerTransitioningDelegate {
    

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
    var sudokuItem: SudokuItem?
    
    var inputMode: InputMode = .number
    var operationState: SudokuOperationState = .making
    var logStack: [InputLog] = []
    var hasChangeSaved = true
    
    /* button animation */
    var buttonAnimators: [UIButton:UIViewPropertyAnimator] = [:]
    
    // used for transition animation
    var cellIndex: IndexPath?
    var sourceSudokuFrame: CGRect?
    
    /* SudokuViewDelegate */
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
                            // reset hasChangeSaved
                            hasChangeSaved = false
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
                                // reset hasChangeSaved
                                hasChangeSaved = false
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
                if operationState == .making {
                    sudokuView.selectedCell = cell.nextCell(withSize: 3)
                }
                else if operationState == .playing {
                    checkIfSolved()
                }
                contradictionM = findContradictions(sudoku: sudoku)
                sudokuView.setNeedsDisplay()
            }
        }
    }
    
    @IBAction func colorButton(_ sender: UIButton) {
        // fade in color
        let animator = buttonAnimators[sender]
        animator?.stopAnimation(true)
        animator?.addAnimations {
            sender.backgroundColor = CustomColor.vividgreen
        }
        animator?.startAnimation()
    }
    
    @IBAction func fadeOutColor(_ sender: UIButton) {
        // fade out color
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
        
        // create button animators
        for button in numberButtons {
            buttonAnimators[button] = UIViewPropertyAnimator(duration: 0.4, curve: .linear)
        }
        
        if let sudokuStr = sudokuItem?.sudokuString,
           let parsedSudoku = parseSudoku(sudokuStr: sudokuStr, size: 3) {
            try? Sudoku.copySudoku(from: parsedSudoku, to: sudoku)
        }
        if let state = sudokuItem?.state {
            operationState = SudokuOperationState(rawValue: state) ?? .making
        }
        if operationState == .playing {
            timerLabel.text = sudokuItem?.time.toString(showHourIfZero: false)
        }
        
        contradictionM = findContradictions(sudoku: sudoku)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if operationState == .playing {
            // start the timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if let time = Time.parse(timeStr: self.timerLabel.text ?? "") {
                    self.timerLabel.text = (time+1).toString(showHourIfZero: false)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // stop the timer if valid
        timer?.invalidate()
        textDeleteTimer?.invalidate()
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier, identifier == "Show menu" {
            if let destination = segue.destination as? OperationMenuViewController {
                switch operationState {
                case .making:
                    destination.operationMenu = [
                        NSLocalizedString("action_save", comment: ""),
                        NSLocalizedString("action_play", comment: ""),
                        NSLocalizedString("action_clear_note", comment: ""),
                        NSLocalizedString("action_inspect", comment: ""),
                        NSLocalizedString("action_solve", comment: ""),
                        NSLocalizedString("action_quit", comment: "")
                    ]
                case .playing:
                    destination.operationMenu = [
                        NSLocalizedString("action_save", comment: ""),
                        NSLocalizedString("action_restart", comment: ""),
                        NSLocalizedString("action_clear_note", comment: ""),
                        NSLocalizedString("action_edit", comment: ""),
                        NSLocalizedString("action_solve", comment: ""),
                        NSLocalizedString("action_quit", comment: "")
                    ]
                case .solved:
                    destination.operationMenu = [
                        NSLocalizedString("action_save", comment: ""),
                        NSLocalizedString("action_edit", comment: ""),
                        NSLocalizedString("action_quit", comment: "")
                    ]
                }
            }
        }
    }
    
    /* IOperationMenuPresenter method */
    func doStuffWhenItemSelected(itemAt: Int) {
        switch operationState {
        case .making:
            switch itemAt {
            case 0:
                // save the current puzzle
                saveSudoku()
                closeMenu()
            case 1:
                // play the current sudoku
                changeToPlayingMode()
                closeMenu()
            case 2:
                // clear notes
                clearNotes()
                closeMenu()
            case 3:
                // check if whether the current sudoku is solvable
                inspectCurrentSudoku()
                closeMenu()
            case 4:
                // solve the current puzzle
                closeMenuImmediately()
                alertForSolveSudoku()
                closeMenu()
            case 5:
                // exit
                closeMenuImmediately()
                if !hasChangeSaved {
                    alertForChangeNotSaved()
                }
                else {
                    closeSelf()
                }
            default:
                break
            }
        case .playing:
            switch itemAt {
            case 0:
                // save the current puzzle
                saveSudoku()
                closeMenu()
            case 1:
                // restart
                closeMenuImmediately()
                alertForRestart()
                closeMenu()
            case 2:
                // clear notes
                clearNotes()
                closeMenu()
            case 3:
                // edit the current puzzle
                changeToMakingMode()
                closeMenu()
            case 4:
                // solve the current puzzle
                closeMenuImmediately()
                alertForSolveSudoku()
                closeMenu()
            case 5:
                // exit
                closeMenuImmediately()
                if !hasChangeSaved {
                    alertForChangeNotSaved()
                }
                else {
                    closeSelf()
                }
            default:
                break
            }
        case .solved:
            switch itemAt {
            case 0:
                // save the current puzzle
                saveSudoku()
                closeMenu()
            case 1:
                //  edit the current puzzle
                changeToMakingMode()
                closeMenu()
            case 2:
                // exit
                closeMenuImmediately()
                if !hasChangeSaved {
                    alertForChangeNotSaved()
                }
                else {
                    closeSelf()
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Private methods
    
    private func checkIfSolved() {
        if sudoku.isSolved() {
            // change to solved mode
            operationState = .solved
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
    
    private func saveSudoku() {
        if let context = container?.viewContext {
            sudokuItem?.state = operationState.rawValue
            sudokuItem?.sudokuString = serializeSudoku(sudoku: sudoku)
            if operationState == .playing, let timeStr = timerLabel.text {
                sudokuItem?.time = parseTime(timeStr: timeStr) ?? 0
            }
            do {
                try context.save()
                hasChangeSaved = true
                backgroundText = NSLocalizedString("message_change_save_successed", comment: "")
            }
            catch {
                backgroundText = NSLocalizedString("message_change_save_failed", comment: "")
            }
        }
    }
    
    private func changeToPlayingMode() {
        operationState = .playing
        sudoku.fixNumbers()
        sudokuView.setNeedsDisplay()
        // start the timer
        timer?.invalidate()
        timerLabel.text = "00:00"
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if let time = Time.parse(timeStr: self.timerLabel.text ?? "") {
                    self.timerLabel.text = (time+1).toString(showHourIfZero: false)
                    
                }
            }
        }
        hasChangeSaved = false
    }
    
    private func changeToMakingMode() {
        operationState = .making
        timer?.invalidate()
        timerLabel.text = ""
        sudoku.resetFixedNumbers()
        sudokuView.setNeedsDisplay()
        hasChangeSaved = false
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
        hasChangeSaved = false
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
                        self?.hasChangeSaved = false
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
    
    private func closeSelf() {
        // snapshot the sudokuView and remember its frame for transition animation
        if let sudokuNVC = navigationController as? SudokuNavigationViewController {
            sudokuNVC.sudokuViewSnapshot = sudokuView.snapshotView(afterScreenUpdates: true)
            sudokuNVC.destinationSudokuFrame = sudokuView.convert(sudokuView.bounds, to: view)
        }
        presentingViewController?.dismiss(animated: true)
    }
    
    private func alertForChangeNotSaved() {
        let alert = UIAlertController(
            title: "",
            message: NSLocalizedString("alert_text_change_notsaved", comment: ""),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_cancel", comment: ""),
                            style: .cancel))
        alert.addAction(UIAlertAction(
                            title: NSLocalizedString("alert_action_quit", comment: ""),
                            style: .destructive,
                            handler: { action in
                                self.closeSelf()
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
}
