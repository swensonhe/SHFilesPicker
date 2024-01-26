import UIKit
import AVKit

extension URL {
    func getVideoPreviewImage() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVURLAsset(url: URL(fileURLWithPath: self.path))
            
            let assetIG = AVAssetImageGenerator(asset: asset)
            assetIG.appliesPreferredTrackTransform = true
            assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
            
            let cmTime = CMTime(seconds: 0, preferredTimescale: 60)
            let thumbnailImage: CGImage
            
            do {
                thumbnailImage = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
                continuation.resume(returning: UIImage(cgImage: thumbnailImage))
            } catch let error {
                debugPrint(error)
                continuation.resume(throwing: error)
            }
        }
    }
    
    func moveToTempDirectory(fileName: String) throws -> URL {
        let pathName = fileName + "." + pathExtension
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let targetURL = temporaryDirectoryURL.appendingPathComponent(pathName)
        try FileManager.default.copyItem(at: self, to: targetURL)
        return targetURL
    }
}
