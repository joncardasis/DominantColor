//
//  PixelPoint.swift
//  ColorSwatch
//
//  Created by Jonathan Cardasis on 11/12/16.
//  Copyright © 2016 Jonathan Cardasis. All rights reserved.
//

import UIKit

class PixelPoint {
    private(set) var x: UInt8 = 0
    private(set) var y: UInt8 = 0
    private(set) var z: UInt8 = 0
    var parentCluster: Cluster?
    
    init(x: UInt8, y: UInt8, z: UInt8){
        self.x = x
        self.y = y
        self.z = z
    }
    
    required init(_ model: PixelPoint) {
        self.x = model.x
        self.y = model.y
        self.z = model.z
        self.parentCluster = model.parentCluster
    }
    
    /* Returns a deep copy of Self */
    func copy() -> PixelPoint {
        return PixelPoint.init(self)
    }
    
    func setCoords(x: UInt8, y: UInt8, z: UInt8) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    func distance(from centroid: PixelPoint) -> Double{
        let deltaX = Double(centroid.x)-Double(self.x)
        let deltaY = Double(centroid.y)-Double(self.y)
        let deltaZ = Double(centroid.z)-Double(self.z)
        
        return sqrt(pow(deltaX, 2) + pow(deltaY, 2) + pow(deltaZ, 2))
    }
    
    func colorValue() -> UIColor {
        return UIColor(red: CGFloat(x)/255.0, green: CGFloat(y)/255.0, blue: CGFloat(z)/255.0, alpha: 1)
    }

}
