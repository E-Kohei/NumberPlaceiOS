//
//  RoundRectContainerMenuView.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/13.
//

import UIKit

@IBDesignable
class RoundRectContainerMenuView: UIButton {
    
    @IBInspectable
    var cornerRadius: CGFloat = 10
    
    @IBInspectable
    var foregroundColor: UIColor = UIColor.white
    
    @IBInspectable
    var menuCount: Int = 2
    
    var menuIcons: [UIImage?] = []
    
    var menuLabels: [NSAttributedString?] = []

    override func draw(_ rect: CGRect) {
        let roundRect = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        roundRect.addClip()
        foregroundColor.setFill()
        roundRect.fill()
        
        // add separator lines
        let separator = UIBezierPath()
        for i in stride(from: CGFloat(1.0), to: CGFloat(menuCount), by: 1.0) {
            separator.move(to: CGPoint(x: i*bounds.width/CGFloat(menuCount), y: 0))
            separator.addLine(to: CGPoint(x: i*bounds.width/CGFloat(menuCount), y: bounds.height))
        }
        UIColor.gray.setStroke()
        separator.stroke()
        
        let iconWidth = min(bounds.height/3, bounds.width/CGFloat(menuCount))
        for i in 0..<menuIcons.count {
            menuIcons[i]?.draw(in: CGRect(
                                x: CGFloat(2*i+1)*bounds.width/CGFloat(menuCount)/2 - iconWidth/2,
                                y: bounds.midY - iconWidth/2,
                                width:  iconWidth,
                                height: iconWidth))
        }
        for i in 0..<menuLabels.count {
            menuLabels[i]?.draw(in: CGRect(
                                    x: CGFloat(i) * bounds.width / CGFloat(menuCount),
                                    y: bounds.height * 4 / 5,
                                    width:  bounds.width / CGFloat(menuCount),
                                    height: bounds.height / 5))
        }
        
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        // this will not send action for swipe
        return false
    }

}
