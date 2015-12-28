//
//  MandelbrotView.swift
//  MandelbrotSwift
//
//  Created by Clara Cyon on 2015-12-07.
//  Copyright (c) 2015 Clara Cyon. All rights reserved.
//

import Foundation
import UIKit

class MandelbrotView : UIView {
    
    //MARK: - Variables
    var bitmapContext: CGContextRef!
    let MAX_INTERATION_COUNT = 10000
    private var zoomUsed: Float = 1.0
    private var centerUsed: CGPoint = CGPointZero
    
    //MARK: - Initialization
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    //MARK: - Private Methods
    private func setup() {
        /* Create "Canvas" that we can draw Mandelbrot in */
        bitmapContext = createCustomBitmapContextWithSize(self.frame.size)
        
        centerUsed = center
        
        /* Draw = "Paint", the bitmapContext "Canvas" */
        drawMandelbrot()
        
        let tappedGestureReconizer = UITapGestureRecognizer(target: self, action: "tapped:")
        addGestureRecognizer(tappedGestureReconizer)
        
        let zoomGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "zoomed:")
        addGestureRecognizer(zoomGestureRecognizer)
    }
    
    /* Create a CoreGraphics Canvas that we can draw in */
    private func createCustomBitmapContextWithSize(size: CGSize) -> CGContextRef {
        var bitmapBytesPerRow = size.width * 4
        bitmapBytesPerRow += (16 - (bitmapBytesPerRow % 16)) % 16
        var bitMapByteCount = bitmapBytesPerRow * size.height
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()!
        let bitmapInfo: UInt32 = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).rawValue
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), 8, Int(bitmapBytesPerRow), colorSpace, bitmapInfo)!
        return context
    }
    
    private func backgroundThread(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if(background != nil) {
                background!()
            }
            
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(popTime, dispatch_get_main_queue()) {
                if(completion != nil) {
                    completion!()
                }
            }
        }
    }
    
    private var drawDetailed = false
    private var currentlyDrawing = false
    private func drawMandelbrot(maxInterationCountOverriden: Int? = nil) {
        let maxIterationCountUsed = maxInterationCountOverriden ?? MAX_INTERATION_COUNT
        
        if !currentlyDrawing {
            currentlyDrawing = true
            backgroundThread(background: {
                () -> Void in
                self.drawMandelbrotAtPoint(self.centerUsed, andZoom: self.zoomUsed, maxIterationCount: maxIterationCountUsed)
                }) { () -> Void in
                    self.currentlyDrawing = false
                    self.setNeedsDisplay()
                    if self.drawDetailed {
                        self.drawDetailed = false
                        self.drawMandelbrot()
                    }
            }
        }
    }
    
    var counterOfPixelsInSet = 0
    private func drawMandelbrotAtPoint(centerPoint: CGPoint, andZoom zoom: Float, maxIterationCount: Int) {
        print("centerPoint: \(centerPoint.x):\(centerPoint.y), zoom: \(zoom)")
        
        CGContextSetAllowsAntialiasing(bitmapContext, false)
        var real: Float
        var img: Float
        
        /**
         * Mapping the bounding box to pixels
         * Zoom 1 has to be between -2 to 1 and -1 to 1
         * any additional zoom divides these by the zoom
         */
        
        /* Iterate through every pixel of the frame... */
        for i in 0...Int(self.frame.width) {
            for j in 0...Int(self.frame.height) {
                real = (Float(i) - 1.33 * Float(centerPoint.x))/160
                img = (Float(j) - 1.00 * Float(centerPoint.y))/160
                
                real /= zoom
                img /= zoom
                
                let mandelbrotInSetResult = inMandelbrotSet(real, img: img, maxIterationCount: maxIterationCount)
                if mandelbrotInSetResult.inSet {
                    counterOfPixelsInSet++
                    /* BLACK COLOR */
                    CGContextSetRGBFillColor(bitmapContext, 0, 0, 0, 1.0)
                } else {
                    /* White to BLUE COLOR */
                    let iterationCount = mandelbrotInSetResult.interationCount
                    let iterationCut: CGFloat = CGFloat(iterationCount)/CGFloat(maxIterationCount)
                    let grayScale = 255 * iterationCut
                    CGContextSetRGBFillColor(bitmapContext, grayScale, grayScale, grayScale, 1.0)
                }
                CGContextFillRect(bitmapContext, CGRectMake(CGFloat(i), CGFloat(j), 1, 1))
            }
        }
        
        print("Pixels in set: \(counterOfPixelsInSet)")
 
    }
    
    //MARK: - Selector Methods
    func tapped(gestureReconizer: UITapGestureRecognizer) {
        let point = gestureReconizer.locationInView(self)
        centerUsed = point
        
        drawMandelbrot()
    }
    
    private var lastZoom: Float = 1
    func zoomed(gestureReconizer: UIPinchGestureRecognizer) {
        let zoomScale = Float(gestureReconizer.scale)
        print("scale: \(zoomScale)")
        let point = gestureReconizer.locationInView(self)
        zoomUsed = lastZoom * zoomScale
        centerUsed = point
        if gestureReconizer.state == .Ended {
            drawDetailed = true
            lastZoom = zoomUsed
        } else if gestureReconizer.state == .Changed {
            drawMandelbrot(10)
        }
    }
    
    /* Using the "Escape Time" algorithm discribed here: https://en.wikipedia.org/wiki/Mandelbrot_set#Escape_time_algorithm */
    private func inMandelbrotSet(real: Float, img: Float, maxIterationCount: Int) -> (inSet: Bool, interationCount: Int) {
        var inSet = true
        var iterationCount = 0
        
        var x: Float = 0
        var y: Float = 0
        var nextX: Float = 0
        var nextY: Float = 0
        
        for _ in 0...maxIterationCount {
            iterationCount++
            /* Calculate the real part of the sequence */
            nextX = x*x - y*y + real
            
            /* Calculate the imaginary part of the sequence */
            nextY = 2*x*y + img
            
            /* Check that magnitude is great than 2 */
            if (nextX*nextX + nextY*nextY) > 4 {
                inSet = false
                break
            }
            
            x = nextX
            y = nextY
        }
        
        return (inSet, iterationCount)
    }
    
    //MARK: - Overridden Methods
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let mandelbrotImage = CGBitmapContextCreateImage(self.bitmapContext)
        CGContextDrawImage(context, rect, mandelbrotImage)
    }
}