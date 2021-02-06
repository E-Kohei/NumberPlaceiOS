//
//  RoundRectContainerView.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/11.
//

import UIKit

@IBDesignable
class RoundRectContainerView: UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat = 10
    
    @IBInspectable
    var foregroundColor: UIColor = UIColor.white

    override func draw(_ rect: CGRect) {
        let roundRect = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        roundRect.addClip()
        foregroundColor.setFill()
        roundRect.fill()
    }

}
