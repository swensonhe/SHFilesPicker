import Foundation
import UniformTypeIdentifiers

public struct File {
    public let id: String
    public let name: String
    public let data: Data?
    public let uniformType: UTType?
    public let url: URL?
    public let previewURL: URL?
    public let width: CGFloat?
    public let height: CGFloat?
    
    public var isImage: Bool {
        return uniformType?.conforms(to: .image) == true
    }
    
    public var isVideo: Bool {
        return uniformType?.conforms(to: .movie) == true
    }
}
