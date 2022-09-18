////
////  VideoHelper.swift
////  xrecorder
////
////  Created by Huy on 15/03/2022
////
//
//import UIKit
//import AVFoundation
//
//public class VideoHelper: NSObject {
//
//    static public func thumbnailFromVideo(videoUrl: URL, time: CMTime) -> UIImage{
//        let asset: AVAsset = AVAsset(url: videoUrl) as AVAsset
//        let imgGenerator = AVAssetImageGenerator(asset: asset)
//        imgGenerator.appliesPreferredTrackTransform = true
//        do{
//            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
//            let uiImage = UIImage(cgImage: cgImage)
//            return uiImage
//        }catch{
//            
//        }
//        return UIImage()
//    }
//    
//    static public func videoDuration(videoURL: URL) -> Float64 {
//        let source = AVURLAsset(url: videoURL)
//        return CMTimeGetSeconds(source.duration)
//    }
//    
//}
