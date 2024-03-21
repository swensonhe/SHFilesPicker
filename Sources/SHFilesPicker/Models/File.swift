import UIKit
import UniformTypeIdentifiers

public struct ImageFile {
    public let data: Data
    public let image: UIImage
    public let size: CGSize
    public let uniformType: UTType?
}

public struct VideoFile {
    public let url: URL?
    public let data: Data
    public let previewData: Data
    public let previewImage: UIImage
    public let previewUniformType: UTType?
    public let size: CGSize
    public let uniformType: UTType?
}

public struct OtherFile {
    public let data: Data
    public let uniformType: UTType?
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
}
