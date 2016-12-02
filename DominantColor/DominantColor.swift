//
//  DominantColor.swift
//  DominantColor
//
//  Created by Jonathan Cardasis on 12/1/16.
//  Copyright © 2016 Jonathan Cardasis. All rights reserved.
//

import UIKit
import ImageIO

struct Properties{
    static let maxImageDimension = 200
}

//extension Data {
//    func asArray<T>(type: T.Type) -> [T] {
//        return self.withUnsafeBytes{
//            [T](UnsafeBufferPointer(start: $0, count: self.count/MemoryLayout<T>.stride))
//        }
//    }
//}
//
//extension UIImage {
//    func getPixelColor(pos: CGPoint) -> [UInt8] {
//        
//        let pixelData = self.cgImage!.dataProvider!.data
//        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
//        
//        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
//        
//        //TODO: bitshift to make it faster?
//        let r = data[pixelInfo]
//        let g = data[pixelInfo+1]
//        let b = data[pixelInfo+2]
//        let a = data[pixelInfo+3]
//        
//        //return UIColor(red: r, green: g, blue: b, alpha: a)
//        return [r,g,b,a]
//    }
//}

func scaledImage(_ image: UIImage, ofMaxDimension dim: Int) -> CGImage{
    let imageSource = CGImageSourceCreateWithData(UIImagePNGRepresentation(image) as! CFData, nil)
    
    let scaleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSObject,
        kCGImageSourceThumbnailMaxPixelSize as String: dim as NSObject
    ]
    
    //let img = CGImageSourceCreateImageAtIndex(imageSource!, 0, scaleOptions as CFDictionary).flatMap{ UIImage(cgImage: $0) }!
    
    //return CGImageSourceCreateImageAtIndex(imageSource!, 0, scaleOptions as CFDictionary)!
    return CGImageSourceCreateThumbnailAtIndex(imageSource!, 0, scaleOptions as CFDictionary)!//.flatMap{ $0 }!
}


func getPixels(from image: UIImage) -> [PixelPoint]{
    let scaledImg = scaledImage(image, ofMaxDimension: Properties.maxImageDimension)
    var pixels = [PixelPoint?](repeating: nil, count: scaledImg.width * scaledImg.height)
    let imageData: UnsafePointer<UInt8> = CFDataGetBytePtr(scaledImg.dataProvider?.data)
    
    //DEBUG
    /*
    let rawData: UnsafeMutablePointer<UInt8> = malloc(scaledImg.width * scaledImg.height * 4)
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    let context = CGContext.init(data: rawData,
                                 width: scaledImg.width,
                                 height: scaledImg.height,
                                 bitsPerComponent: 8,
                                 bytesPerRow: 4*scaledImg.width,
                                 space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: bitmapInfo.rawValue)
    
    context?.draw(scaledImg, in: CGRect(x:0, y:0, width: scaledImg.width, height: scaledImg.height))
    
    //use rawData
    let bytesPerRow = 4 * scaledImg.width
    let y = 0, x = 0
    let startByte = (bytesPerRow * y) + x * 4
    
    print("red: \(rawData[startByte])\tgreen: \(rawData[startByte+1])\tblue:\(rawData[startByte+2])")
    
    free(rawData)*/
    
    //END DEBUG
    
    
    //DEBUG
    
    //END DEBUG

    for (i,_) in stride(from: 0, to: CFDataGetLength(scaledImg.dataProvider?.data), by: 4).enumerated() {
        //Read as RGBA8888 Big-endian
        
        
        //DEBUG
        //if i==1 {
    //        var str = ""
    //        for j in 0..<4 {
    //            str += String(format: "%2X", imageData[i*4+j])
    //        }
    //        print("\(str)")
        //}
        //END DEBUG
        
        let r = imageData[i*4 + 1]
        let g = imageData[i*4 + 2]
        let color_b = imageData[i*4 + 3] //TODO: bug? b not a valid variable?

        //let color = UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(color_b)/255.0, alpha: 1)
        pixels[i] = (PixelPoint(x: r, y: g, z: color_b))
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
    var points = getPixels(from: tempImage)
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
