import UIKit
import AVKit

extension UIImage {
    
    func resized(to size: CGSize) -> UIImage {
        let isLandscape = self.size.width > self.size.height
        
        let landscapeSize = size
        let portraitSize = CGSize(width: landscapeSize.height, height: landscapeSize.width)
        
        let maximumSize: CGSize = isLandscape ?
            landscapeSize :
            portraitSize
        
        let availableRect = AVMakeRect(aspectRatio: self.size, insideRect: .init(origin: .zero, size: maximumSize))
        let targetSize = availableRect.size
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resized
    }
    
}
