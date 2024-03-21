import UIKit
import UniformTypeIdentifiers

public struct ImageFile: Sendable {
    public let data: Data
    public let image: UIImage
    public let size: CGSize
    public let uniformType: UTType?
}

public struct VideoFile: Sendable {
    public let url: URL?
    public let data: Data
    public let previewData: Data
    public let previewImage: UIImage
    public let previewUniformType: UTType?
    public let size: CGSize
    public let uniformType: UTType?
}

public struct OtherFile: Sendable {
    public let data: Data
    public let uniformType: UTType?
}

public enum FileType: Sendable {
    case image(ImageFile)
    case video(VideoFile)
    case file(OtherFile)
}

public struct File: Sendable {
    public let name: String
    public let type: FileType
    
    init(type: FileType) {
        self.name = switch type {
        case .image(let file):
            "\(UUID().uuidString).\(file.uniformType?.preferredFilenameExtension ?? "")"
        case .video(let file):
            "\(UUID().uuidString).\(file.uniformType?.preferredFilenameExtension ?? "")"
        case .file(let file):
            "\(UUID().uuidString).\(file.uniformType?.preferredFilenameExtension ?? "")"
        }
        
        self.type = type
    }
}
