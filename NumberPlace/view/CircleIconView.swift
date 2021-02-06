//
//  CircleIconView.swift
//  NumberPlace
//
//  Created by 江崎航平 on 2021/01/01.
//

import UIKit

@IBDesignable
class CircleIconView: UIView {
    
    @IBInspectable
    var strokeColor: UIColor = UIColor.black {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable
    var strokeWidth: CGFloat = 2.0 {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable
    var fillColor: UIColor = UIColor.clear {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable
    var radiusRatioToBounds: CGFloat = 0.7 {
        didSet { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) * radiusRatioToBounds / 2
        let path = UIBezierPath()
        path.addArc(
            withCenter: center,
            radius: radius,
            startAngle: 0.0,
            endAngle: 2*CGFloat.pi,
            clockwise: false)
        strokeColor.setStroke()
        fillColor.setFill()
        path.lineWidth = strokeWidth
        path.stroke()
        path.fill()
    }

}
