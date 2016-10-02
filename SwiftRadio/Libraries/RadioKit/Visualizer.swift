//
//  Visualizer.swift
//
//  Created by Brian Stormont on 10/12/15.
//  Copyright © 2015 Stormy Productions. All rights reserved.
//


import UIKit

class Visualizer: UIView {

    weak var radioKit: RadioKit!
  
    var plot: [CGFloat] = [0.0, 0.0, 0.0, 0.0]
    var currPlotPt: Int = 0
    
    
    deinit{
        radioKit = nil;
    }
    
    override func draw(_ rect: CGRect) {
        let size: CGSize = bounds.size
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setAllowsAntialiasing(false)
        
        context.setFillColor(gray: 1.0, alpha: 1.0)
        context.fill(CGRect(x:0, y:size.height, width:5, height:-(size.height * plot[0])));
        context.fill(CGRect(x:6, y:size.height, width:5, height:-(size.height * plot[1])));
        context.fill(CGRect(x:15, y:size.height, width:5, height:-(size.height * plot[2])));
        context.fill(CGRect(x:21, y:size.height, width:5, height:-(size.height * plot[3])));
        
        context.setAllowsAntialiasing(true);
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateData(){
        // Do some rudimentary audio visualization
        
        var avgLevel: [Float32] = [1.0, 0.0]
        var peakLevel: [Float32] = [0.0, 0.0]
        
        radioKit.getAudioLevels(&avgLevel, peakLevels:&peakLevel)

        plot[0] = CGFloat(avgLevel[0])
        plot[1] = CGFloat(peakLevel[0])
        plot[2] = CGFloat(avgLevel[1])
        plot[3] = CGFloat(peakLevel[1])
        
        setNeedsDisplay()
    }
}
