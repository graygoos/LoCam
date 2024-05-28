//
//  Experiments.swift
//  LoCam
//
//  Created by Femi Aliu on 28/05/2024.
//

import Foundation

/*
private func addWatermarkToVideo(at url: URL, completion: @escaping (URL) -> Void) {
    let asset = AVAsset(url: url)
    let composition = AVMutableComposition()
    
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
        completion(url) // In case of failure, return the original video URL
        return
    }
    
    let videoComposition = AVMutableVideoComposition()
    videoComposition.renderSize = videoTrack.naturalSize
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
    
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    instruction.layerInstructions = [layerInstruction]
    videoComposition.instructions = [instruction]
    
    let size = videoTrack.naturalSize
    
    // Create watermark layer
    let watermarkLayer = CALayer()
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateString = formatter.string(from: date)
    
    let locationString = currentLocation != nil ? "\(currentLocation!.coordinate.latitude), \(currentLocation!.coordinate.longitude)" : "Unknown Location"
    let watermarkText = "\(dateString)\n\(locationString)"
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 40),
        .foregroundColor: UIColor.red
    ]
    
    let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
    let textLayer = CATextLayer()
    textLayer.string = attributedString
    textLayer.shouldRasterize = true
    textLayer.rasterizationScale = UIScreen.main.scale
    textLayer.frame = CGRect(x: 20, y: 20, width: size.width - 40, height: 100)
    
    watermarkLayer.addSublayer(textLayer)
    watermarkLayer.frame = CGRect(origin: .zero, size: size)
    watermarkLayer.masksToBounds = true
    
    // Create parent layer
    let videoLayer = CALayer()
    videoLayer.frame = CGRect(origin: .zero, size: size)
    
    let overlayLayer = CALayer()
    overlayLayer.frame = CGRect(origin: .zero, size: size)
    overlayLayer.addSublayer(videoLayer)
    overlayLayer.addSublayer(watermarkLayer)
    
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: overlayLayer)
    
    // Export the video with watermark
    let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
    exportSession?.videoComposition = videoComposition
    let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
    exportSession?.outputURL = outputURL
    exportSession?.outputFileType = .mov
    
    exportSession?.exportAsynchronously {
        DispatchQueue.main.async {
            switch exportSession?.status {
            case .completed:
                completion(outputURL)
            case .failed, .cancelled:
                completion(url) // Return the original URL in case of failure
            default:
                break
            }
        }
    }
}
*/
