import Foundation
import UniformTypeIdentifiers

public struct File {
    public let id: String
    public let name: String
    public let data: Data
    public let uniformType: UTType?
    public let width: CGFloat?
    public let height: CGFloat?
    
    public var isImage: Bool {
        return uniformType?.conforms(to: .image) == true
    }
}
