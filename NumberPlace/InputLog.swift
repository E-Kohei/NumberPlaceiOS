//
//  InputLog.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/02/03.
//

import Foundation
import Sudoku

struct InputLog {
    
    let mode: InputMode
    let cell: Cell
    let beforeVal: Int
    let afterVal: Int
    
    init(before: Int, after: Int, at cell: Cell, mode: InputMode) {
        self.mode = mode
        self.cell = cell
        self.beforeVal = before
        self.afterVal = after
    }
    
    init(before: Int, after: Int, cell_x: Int, cell_y: Int, mode: InputMode) {
        self.mode = mode
        self.cell = Cell(row: cell_x, col: cell_y)
        self.beforeVal = before
        self.afterVal = after
    }
}
