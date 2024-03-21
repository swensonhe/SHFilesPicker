import UIKit
import UniformTypeIdentifiers

public struct ImageFile {
    public let data: Data
    public let image: UIImage
    public let size: CGSize
}

public struct VideoFile {
    public let localURL: URL?
    public let previewData: Data
    public let previewImage: UIImage
    public let size: CGSize
}

public struct OtherFile {
    public let data: Data
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
