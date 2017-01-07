//
//  DominantColorTests.swift
//  DominantColorTests
//
//  Created by Jon Cardasis on 12/30/16.
//  Copyright © 2016 Jonathan Cardasis. All rights reserved.
//

import XCTest
@testable import DominantColor

class DominantColorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    /*
    func testSubcomponentPerformance() {
        let numClusters = 3
        let image = UIImage(named: "Nike_small.jpeg")!
        
        var adjustedImage: CGImage!
        //self.measure { //MARK: Measure scaledImage
            adjustedImage = scaledImage(image, ofMaxDimension: 200) //avg 0.004s
        //}
        
        var pixels = [PixelPoint]()
        //self.measure { //MARK: Measure getPixels
            pixels = getPixels(from: adjustedImage) //avg 0.020s
        //}
        
        var clusters = [Cluster]()
        //self.measure { //MARK: Measure k++ distribution
            kPlusPlusClusterDistribution(points: &pixels, clusters: &clusters, numClusters: numClusters)//avg 0.280s
        //}
        
        //While: //0.1s x ~30 iterations = 3s
        self.measure{
            assignPointsToClusters(points: &pixels, clusters: &clusters) //0.05s
        }
        
        //self.measure {
            assignPointsToClusters(points: &pixels, clusters: &clusters) //avg 0.05s
            for cluster in clusters {
                cluster.points.removeAll()
            }
        //}
        
    }*/
    
    func testKMeansPerformance() {
        let image = UIImage(named: "Nike_small.jpeg")!
        var centroids: [PixelPoint]!
        var colors = Array<Array<UIColor>>(repeating: [UIColor](), count: 10)
        
        var iteration = 0
        self.measure {
            centroids = kmeans(tempImage: image, numClusters: 4)
            
            for point in centroids {
                colors[iteration].append(point.colorValue())
            }
            iteration += 1
        }
        
        print(colors)
    }
    

}
