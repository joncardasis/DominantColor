//
//  Cluster.swift
//  ColorSwatch
//
//  Created by Jonathan Cardasis on 11/12/16.
//  Copyright © 2016 Jonathan Cardasis. All rights reserved.
//

import Foundation

class Cluster {
    var points: [PixelPoint]
    var centroid: PixelPoint
    var id: Int
    
    init(id: Int) {
        self.id = id
        points = [PixelPoint]()
        centroid = PixelPoint(x: 0, y: 0, z: 0)
    }
    
    func addPoint(point: PixelPoint) {
        points.append(point)
    }
    
    //Will set the centroid to a random 3d point between values of min (inclusive) to max (exclusive)
    func setCentroidRandom(min: UInt32, max: UInt32) {
        centroid = PixelPoint(x: UInt8(arc4random_uniform(max) + min), y: UInt8(arc4random_uniform(max) + min), z: UInt8(arc4random_uniform(max) + min))
    }
    
    
    func debugPrint(){
        print("Cluster: \(self.id)")
        print("\tCentroid:\(centroid)")
        for attachedPoint in points {
            print("\t\(attachedPoint)")
        }
    }
    
    
}
