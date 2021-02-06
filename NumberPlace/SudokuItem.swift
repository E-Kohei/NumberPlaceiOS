//
//  SudokuItem.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/14.
//

import UIKit
import CoreData

class SudokuItem: NSManagedObject {
    
}

typealias Time = Int32

extension Time {
    static func parse(timeStr: String) -> Time? {
        var seconds = Int32(0)
        let nums = timeStr.split(separator: ":")
            .map { return Int32($0) }
        for i in 0..<nums.count {
            var sec = Int32(1)
            for _ in 0..<i {
                sec *= 60
            }
            if let n = nums[nums.count-i-1], n >= 0 {
                seconds += n * sec
            }
            else {
                return nil
            }
        }
        return seconds
    }
    
    func toString(showHourIfZero: Bool) -> String {
        let h = self / 3600
        let m = (self - h*3600) / 60
        let s = self - h*3600 - m*60
        if !showHourIfZero && h == 0 {
            return String(format: "%02d:%02d", m, s)
        }
        else {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
    }
}
