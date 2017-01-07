//
//  DominantColor.swift
//  DominantColor
//
//  Created by Jonathan Cardasis on 12/1/16.
//  Copyright © 2016 Jonathan Cardasis. All rights reserved.
//
import UIKit
import ImageIO

fileprivate struct Properties{
    //Image will resized before calculations. Max dimension length.
    static let maxImageDimension: Int = 300
    
    //Count only every pixelOffset pixel in the image for calculation
    static let pixelOffset: Int = 2
}

func scaledImage(_ image: UIImage, ofMaxDimension dim: Int) -> CGImage{
    let imageSource = CGImageSourceCreateWithData(UIImagePNGRepresentation(image) as! CFData, nil)
    
    let imageDim = Int(max(image.size.width, image.size.height))
    let resizeDim = (dim > imageDim) ? dim : imageDim
    
    let scaleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSObject,
        kCGImageSourceThumbnailMaxPixelSize as String: resizeDim as NSObject
    ]
    
    return CGImageSourceCreateThumbnailAtIndex(imageSource!, 0, scaleOptions as CFDictionary)!//.flatMap{ $0 }!
}

// @param - pixelOffset: how many pixels should be skipped between each read (ex 2 will read every other pixel)
//TODO: need to fix pixelOffset - needs to calibrate to assume like pixels on border elements
func getPixels(from image: CGImage, pixelOffset: Int = Properties.pixelOffset) -> [PixelPoint]{
    //let scaledImg = scaledImage(image, ofMaxDimension: Properties.maxImageDimension)
    var pixels = [PixelPoint?](repeating: nil, count: (image.width * image.height)/pixelOffset)
    let imageData: UnsafePointer<UInt8> = CFDataGetBytePtr(image.dataProvider?.data)

    for i in 0..<(image.width*image.height)/pixelOffset {
        //Read as RGBA8888 Big-endian
        let r = imageData[i*4 + 1]
        let g = imageData[i*4 + 2]
        let b = imageData[i*4 + 3] 

        pixels[i] = (PixelPoint(x: r, y: g, z: b))
    }

    return pixels as! [PixelPoint]
}


func assignPointsToClusters(points: inout [PixelPoint], clusters: inout [Cluster]){
    for point in points {
        var bestDistance = Double.infinity
        var bestClusterMatch: Cluster?
        
        for cluster in clusters {
            let delta = point.distance(from: cluster.centroid)
            if(delta < bestDistance) {
                bestDistance = delta
                bestClusterMatch = cluster
            }
        }
        
        point.parentCluster = bestClusterMatch
        bestClusterMatch?.addPoint(point: point)
    }
}

func recalculateCentroids(clusters: inout [Cluster]){
    for cluster in clusters {
        if cluster.points.count > 0 {
            let pointsCount = cluster.points.count
            var sumX = 0
            var sumY = 0
            var sumZ = 0
            
            for point in cluster.points {
                sumX += Int(point.x)
                sumY += Int(point.y)
                sumZ += Int(point.z)
            }
            cluster.centroid.setCoords(x: UInt8(sumX/pointsCount), y: UInt8(sumY/pointsCount), z: UInt8(sumZ/pointsCount))
        }
    }
}

//https://msdn.microsoft.com/en-us/magazine/mt185575.aspx
//Using algorithmic seeding, distribute clusters to the best of our knowledge of the data set
//Pre: clusters must be initalized with size 0 
//     numClusters > 0
//Post: clusters will have numClusters elements and be the best mapped random points from the points array
func kPlusPlusClusterDistribution(points: inout [PixelPoint], clusters: inout [Cluster], numClusters: Int) {
    var usedPoints = [Int]() //stores indices of used points from points array
    
    //Assign first cluster to random point in points
    let randomPointIndex = Int(arc4random_uniform(UInt32(points.count)))
    let firstCluster = Cluster(id: 0)
    firstCluster.centroid.setCoords(x: points[randomPointIndex].x, y: points[randomPointIndex].y, z: points[randomPointIndex].z)
    clusters.append(firstCluster)
    usedPoints.append(randomPointIndex)
    
    for k in 1..<numClusters {
        //Get distance-squared values from each point to its closest cluster
        var dSquared = [Double](repeating: 0, count: points.count)
        for (i,point) in points.enumerated() {
            if !usedPoints.contains(i) {
                //Dist between point and cluster
                var distances = [Double](repeating: 0, count: k)
                for i in 0..<distances.count {
                    let deltaX = Double(clusters.last!.centroid.x)-Double(point.x)
                    let deltaY = Double(clusters.last!.centroid.y)-Double(point.y)
                    let deltaZ = Double(clusters.last!.centroid.z)-Double(point.z)
                    let distSquared = pow(deltaX, 2) + pow(deltaY, 2) + pow(deltaZ, 2)
                    
                    distances[i] = distSquared
                }
                dSquared[i] = distances.min()!
            }
        }
        
        //Generate random value [0.0, 1.0] and sum total distances
        let rand = Double(arc4random_uniform(101)) / 100.0 //random val b/w 0 and 1.0
        var totalDist: Double = 0.0
        for dist in dSquared {
            totalDist += dist
        }
        
        //Find the best index (in points array) which is not taken and is 'far' away from other centroids
        var cumulative: Double = 0.0
        var bestIndex: Int = 0 //best index from other centroids
        for _ in 0..<points.count*2 where usedPoints.last != bestIndex {
            cumulative += dSquared[bestIndex]
            if cumulative >= rand && !usedPoints.contains(bestIndex) {
                usedPoints.append(bestIndex) //don't pick again
            }
            else{
                bestIndex += 1
                if bestIndex >= dSquared.count { //loop num back to zero
                    bestIndex = 0
                }
            }
        }
        
        let newCluster = Cluster(id: k)
        newCluster.centroid.setCoords(x: points[bestIndex].x, y: points[bestIndex].y, z: points[bestIndex].z)
        clusters.append(newCluster)
    }
}


func kmeans(tempImage: UIImage/*, points: [PixelPoint]*/, numClusters k: Int, minDelta: Double = 0.001) -> [PixelPoint]{
    var clusters = [Cluster]()
    let adjustedImage = scaledImage(tempImage, ofMaxDimension: Properties.maxImageDimension)
    var points = getPixels(from: adjustedImage)
    var finished = false
    
    /* Create inital clusters */
    kPlusPlusClusterDistribution(points: &points, clusters: &clusters, numClusters: k)
//    for i in 0..<n {
//        let cluster = Cluster(id: i)
//        cluster.setCentroidRandom(min: 0, max: 256)
//        clusters.append(cluster)
//    }
    
    
    
    
    /* Initialize iteration variables */
    var iteration = 0
    var previousCentroids: [PixelPoint]
    let temps = clusters.map { $0.centroid } //MARK: DEBUG
    for temp in temps {
        print("Original centroids: \(temp.x) \(temp.y) \(temp.z)") }//MARK: DEBUG
    
    while !finished {
        print("Iteration \(iteration)")
    
        previousCentroids = clusters.map { $0.centroid.copy() } //Create shallow copy of centroids (we set them above)
        
        iteration += 1
        
        /* Assign points to a cluster closest to each */
        assignPointsToClusters(points: &points, clusters: &clusters)
        
        /* Assign centroids based on closest points to cluster */
        recalculateCentroids(clusters: &clusters)
        
        var centroidDelta = 0.0 //distance of centroids from last iteration
        for (index, centroid) in previousCentroids.enumerated() {
            centroidDelta += centroid.distance(from: clusters[index].centroid)
        }
        
        /* Erase points in clusters */ //-> nope overflow
        for cluster in clusters { //MARK: test
            cluster.points.removeAll()
        }
        
        
        print("Total centroid distances: \(centroidDelta)")
        
        if centroidDelta <= minDelta {
            finished = true
        }
    }
    
    return clusters.map { $0.centroid }
}
