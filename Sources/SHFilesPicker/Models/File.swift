import UIKit
import UniformTypeIdentifiers

public struct ImageFile {
    let data: Data
    let image: UIImage
    let size: CGSize
}

public struct VideoFile {
    let localURL: URL?
    let previewData: Data
    let previewImage: UIImage
    let size: CGSize
}

public struct OtherFile {
    let data: Data
}

public enum FileType {
    case image(ImageFile)
    case video(VideoFile)
    case file(OtherFile)
}

public struct File {
    public let id: String
    public let name: String
    public let type: FileType
    public let uniformType: UTType?
    
    public var isImage: Bool {
        return uniformType?.conforms(to: .image) == true
    }
    
    public var isVideo: Bool {
        return uniformType?.conforms(to: .movie) == true
    }
}
