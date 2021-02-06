//
//  SudokuTableViewCell.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/11.
//

import UIKit
import Sudoku

class SudokuTableViewCell: UITableViewCell, SudokuViewDelegate {

    @IBOutlet weak var sudokuView: SudokuView! {
        didSet { sudokuView.delegate = self }
    }
    
    @IBOutlet weak var stateLabel: UILabel!
    
    @IBOutlet weak var playingTimeLabel: UILabel!
    
    @IBOutlet weak var mainmenuView: RoundRectContainerView!
    
    @IBOutlet weak var submenuView: RoundRectContainerMenuView!
    
    @IBOutlet weak var submenuWidthConstraint: NSLayoutConstraint!
    
    var sudoku = Sudoku(size: 3)
    
    var note = Note(size: 3)
    
    var contradictionM: [[Bool]] = Array(repeating: Array(repeating: false, count: 9), count: 9)

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
