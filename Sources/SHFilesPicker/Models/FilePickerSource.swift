public enum FilePickerSource: Identifiable {
    case camera
    case photos(selectionLimit: Int)
    case files
    case multimedia(selectionLimit: Int)
    
    public var id: String {
        switch self {
        case .camera:
            return "camera"
            
        case .photos:
            return "photos"
            
        case .files:
            return "files"
            
        case .multimedia:
            return "multimedia"
        }
    }
}
