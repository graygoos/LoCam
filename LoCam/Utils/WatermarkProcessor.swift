//
//  WatermarkProcessor.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import UIKit
import AVFoundation
import CoreLocation

// MARK: - Watermark Processor
class WatermarkProcessor {
    static let shared = WatermarkProcessor()
    private init() {}
    
    func addWatermark(to image: UIImage, location: CLLocation?, settings: SettingsManager.WatermarkSettings) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            // Create watermark text
            let watermarkText = createWatermarkText(location: location, settings: settings)
            guard !watermarkText.isEmpty else { return }
            
            // Configure text attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: settings.fontSize),
                .foregroundColor: settings.textColor
            ]
            
            let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
            let textSize = attributedString.size()
            
            // Calculate position
            let position = calculateWatermarkPosition(
                imageSize: image.size,
                textSize: textSize,
                position: settings.position
            )
            
            // Draw background
            let backgroundRect = CGRect(
                x: position.x - 8,
                y: position.y - 4,
                width: textSize.width + 16,
                height: textSize.height + 8
            )
            
            settings.backgroundColor.setFill()
            UIBezierPath(roundedRect: backgroundRect, cornerRadius: 4).fill()
            
            // Draw text
            attributedString.draw(at: position)
        }
    }
    
    func addWatermark(to videoURL: URL, location: CLLocation?, settings: SettingsManager.WatermarkSettings, completion: @escaping (URL) -> Void) {
        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(videoURL)
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
        let watermarkText = createWatermarkText(location: location, settings: settings)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: settings.fontSize * 2), // Scale up for video
            .foregroundColor: settings.textColor
        ]
        
        let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
        let textLayer = CATextLayer()
        textLayer.string = attributedString
        textLayer.shouldRasterize = true
        textLayer.rasterizationScale = UIScreen.main.scale
        
        // Position the text layer
        let textSize = attributedString.size()
        let position = calculateWatermarkPosition(
            imageSize: size,
            textSize: textSize,
            position: settings.position
        )
        
        textLayer.frame = CGRect(origin: position, size: textSize)
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
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: overlayLayer
        )
        
        // Export the video with watermark
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(videoURL)
            return
        }
        
        exportSession.videoComposition = videoComposition
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(outputURL)
                case .failed, .cancelled:
                    completion(videoURL)
                default:
                    break
                }
            }
        }
    }
    
    private func createWatermarkText(location: CLLocation?, settings: SettingsManager.WatermarkSettings) -> String {
        var components: [String] = []
        
        if settings.showDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            components.append(formatter.string(from: Date()))
        }
        
        if settings.showLocation, let location = location {
            let locationString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
            components.append(locationString)
        }
        
        if settings.showCustomText && !settings.customText.isEmpty {
            components.append(settings.customText)
        }
        
        return components.joined(separator: "\n")
    }
    
    private func calculateWatermarkPosition(imageSize: CGSize, textSize: CGSize, position: SettingsManager.WatermarkPosition) -> CGPoint {
        let margin: CGFloat = 20
        
        switch position {
        case .topLeft:
            return CGPoint(x: margin, y: margin)
        case .topRight:
            return CGPoint(x: imageSize.width - textSize.width - margin, y: margin)
        case .bottomLeft:
            return CGPoint(x: margin, y: imageSize.height - textSize.height - margin)
        case .bottomRight:
            return CGPoint(x: imageSize.width - textSize.width - margin, y: imageSize.height - textSize.height - margin)
        }
    }
}