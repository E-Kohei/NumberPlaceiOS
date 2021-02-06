//
//  SudokuVCUtils.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/05.
//

import Foundation
import Sudoku

enum SudokuLevel: String, CustomStringConvertible {
    case newbie   = "newbie"
    case beginner = "beginner"
    case medium   = "medium"
    case master   = "master"
    case legend   = "legend"
    
    var description: String { return rawValue }
}

enum InputMode {
    case number
    case note
}

enum SudokuOperationState: Int16, CustomStringConvertible {
    var description: String {
        switch self {
        case .playing:
            return "Playing"
        case .making:
            return "Making"
        case .solved:
            return "Solved"
        }
    }
    
    case playing = 0
    case making  = 1
    case solved  = 2
    
    
}

func parseSudoku(sudokuStr: String, size: Int) -> Sudoku? {
    let ss = size*size
    let cellVals = sudokuStr.split(separator: ",")
    let numbers: [Int] = cellVals.compactMap {
        Int($0.prefix(upTo: $0.firstIndex(of: "f") ?? $0.endIndex))
    }
    if numbers.count != ss*ss {
        return nil
    }
    let s = Sudoku(size: size)
    for row in 0..<ss {
        for col in 0..<ss {
            s[row, col] = numbers[row*ss + col]
            if cellVals[row*ss + col].hasSuffix("f") {
                s.fixCell(row: row, col: col, isFixed: true)
            }
        }
    }
    return s
}

func serializeSudoku(sudoku: Sudoku) -> String {
    let ss = sudoku.size*sudoku.size
    var sudokuStr = ""
    for row in 0..<ss {
        for col in 0..<ss {
            if sudoku.isFixedCell(row: row, col: col) {
                sudokuStr += "\(sudoku[row,col])f,"
            }
            else {
                sudokuStr += "\(sudoku[row,col]),"
            }
        }
    }
    return sudokuStr
}

func parseTime(timeStr: String) -> Int32? {
    var seconds = Int32(0)
    let nums = timeStr.split(separator: ":")
        .map { return Int32($0) }
    for i in 0..<nums.count {
        var sec = Int32(1)
        for _ in 0..<i {
            sec *= 60
        }
        if let n = nums[nums.count-i-1] {
            seconds += n * sec
        }
        else {
            return nil
        }
    }
    return seconds
}
