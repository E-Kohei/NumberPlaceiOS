//
//  SudokuView.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2020/12/24.
//

import UIKit
import Sudoku

protocol SudokuViewDelegate : class {
    var sudoku: Sudoku { get }
    var note: Note { get }
    var contradictionM: [[Bool]] { get }
}

class SudokuView: UIView {
    
    /* costants for UI */
    private let maxThinLineWidth  = CGFloat(1.5)
    private let maxThickLineWidth = CGFloat(2.5)
    private let thinLineWidthRatio = CGFloat(0.005)
    private let thickLineWidthRatio = CGFloat(0.01)
    private let thinLineColor = UIColor.gray
    private let thickLineColor = UIColor.black
    private let padding = CGFloat(0.0)
    private let selectedCellColor = UIColor(red: 63.0/255, green: 191.0/255, blue: 180.0/255, alpha: 128.0/255)
    private let fixedCellColor = UIColor(red: 210.0/255, green: 210.0/255, blue: 210.0/255, alpha: 128.0/255)
    private let numberParagraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return paragraphStyle
    }()
    
    private var contentWidth: CGFloat {
        return frame.size.width - 2*padding
    }
    private var blankWidth: CGFloat {
        return contentWidth / 9
    }
    private var numberFont: UIFont {
        let font = UIFont.preferredFont(forTextStyle: .body).withSize(contentWidth/10)
//        print("contentWidth: \(contentWidth)")
//        print("first font pointSize: \(font.pointSize)")
//        font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
//        print("second font pointSize: \(font.pointSize)")
        return font
    }
    private var noteFont: UIFont {
        let font = UIFont.preferredFont(forTextStyle: .body).withSize(contentWidth/35)
//        font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        return font
    }
    var selectedCell: Cell? {
        didSet { setNeedsDisplay() }
    }
    
    
    /* UI properties */
    /*private let sudoku: Sudoku = Sudoku(size: 3)
    var note: Note = Note(size: 3) {
        didSet { setNeedsDisplay() }
    }*/
    
    weak var delegate: SudokuViewDelegate?
    
    // selecte cell
    @objc func selectCell(sender recoginzer: UITapGestureRecognizer) {
        if recoginzer.state == .ended {
            self.selectedCell = getCellFromCGPoint(recoginzer.location(in: self))
        }
    }

    override func draw(_ rect: CGRect) {
        
        if let context = UIGraphicsGetCurrentContext() {
            
            // draw numbers of sudoku and note
            if let sudoku = delegate?.sudoku, let note = delegate?.note, let contradictionM = delegate?.contradictionM {
                for cell in getAllCells(size: sudoku.size) {
                    let n = sudoku[cell.row, cell.col]
                    if n != 0 {
                        if sudoku.isFixedCell(row: cell.row, col: cell.col) {
                            colorCell(context: context, cell: cell, color: fixedCellColor)
                        }
                        if contradictionM[cell.row][cell.col] {
                            // if the number at the cell is contradicted
                            drawNumber(cell: cell, n: n, color: UIColor.red)
                        }
                        else {
                            // if the number at the cell is not contradicted
                            drawNumber(cell: cell, n: n, color: UIColor.black)
                        }
                    }
                    else {
                        // if n == 0, draw notes at the cell
                        drawNote(cell: cell, note: note)
                    }
                }
            }
            
            //color the selected cell
            if let cell = selectedCell {
                colorCell(context: context, cell: cell, color: selectedCellColor)
            }
            
            // draw sudoku cells
            context.beginPath()
            // thin lines
            for i in stride(from: CGFloat(0.0), to: CGFloat(10.0), by: 1.0) {
                context.move(to: CGPoint(x: padding, y: contentWidth*i / 9 + padding))
                context.addLine(to: CGPoint(x: contentWidth + padding, y: contentWidth*i / 9 + padding))
                context.move(to: CGPoint(x: contentWidth*i / 9 + padding, y: padding))
                context.addLine(to: CGPoint(x: contentWidth*i / 9 + padding, y: contentWidth + padding))
            }
            thinLineColor.setStroke()
            context.setLineWidth( min(maxThinLineWidth, thinLineWidthRatio*contentWidth) )
            context.strokePath()
            context.beginPath()
            // thick lines
            for i in stride(from: CGFloat(0.0), to: CGFloat(4.0), by: 1.0) {
                context.move(to: CGPoint(x: padding, y: contentWidth*i / 3 + padding))
                context.addLine(to: CGPoint(x: contentWidth + padding, y: contentWidth*i / 3 + padding))
                context.move(to: CGPoint(x: contentWidth*i / 3 + padding, y: padding))
                context.addLine(to: CGPoint(x: contentWidth*i / 3 + padding, y: contentWidth + padding))
            }
            thickLineColor.setStroke()
            context.setLineWidth( min(maxThickLineWidth, thickLineWidthRatio*contentWidth) )
            context.strokePath()
            
        }
    }

    // color a cell
    private func colorCell(context: CGContext, cell: Cell, color: UIColor) {
        let left = CGFloat(cell.col) * contentWidth / 9 + padding
        let top = CGFloat(cell.row) * contentWidth / 9 + padding
        context.addRect(CGRect(x: left, y: top, width: blankWidth, height: blankWidth))
        color.setFill()
        context.fillPath()
    }
    
    // draw a number
    private func drawNumber(cell: Cell, n: Int, color: UIColor) {
        let ch = NSAttributedString(string: String(n), attributes: [
            .font : numberFont,
            .paragraphStyle : numberParagraphStyle,
            //.baselineOffset : NSNumber(50.5),
            NSAttributedString.Key.baselineOffset : 50.5,
            .foregroundColor : color,
        ])
        ch.draw(in: getCellRect(cell))
    }
    
    // draw notes
    private func drawNote(cell: Cell, note: Note) {
        let noteNum = note[cell.row, cell.col]
        for n in 0..<9 {
            if (noteNum >> n & 1) == 1 {
                let ch = NSAttributedString(string: String(n+1), attributes: [
                    .font : noteFont,
                    .paragraphStyle : numberParagraphStyle
                    
                ])
                ch.draw(in: getNoteCellRect(cell, n: n))
            }
        }
        
        
    }
    
    // get CGRect which matches the cell
    private func getCellRect(_ cell: Cell) -> CGRect {
        let left = CGFloat(cell.col) * blankWidth + padding
        let top  = CGFloat(cell.row) * blankWidth + padding
        return CGRect(x: left, y: top, width: blankWidth, height: blankWidth)
    }
    
    // get CGRect which matches the smaller cell of note
    private func getNoteCellRect(_ cell: Cell, n: Int) -> CGRect {
        let left = (3*CGFloat(cell.col)+CGFloat(n%3)) * blankWidth/3 + padding
        let top  = (3*CGFloat(cell.row)+CGFloat(n/3)) * blankWidth/3 + padding
        return CGRect(x: left, y: top, width: blankWidth/3, height: blankWidth/3)
    }
    
    // get cell which contains the given CGPoint
    private func getCellFromCGPoint(_ point: CGPoint) -> Cell {
        let row = Int((point.y - padding) / blankWidth)
        let col = Int((point.x - padding) / blankWidth)
        return Cell(row: row, col: col)
    }
}
