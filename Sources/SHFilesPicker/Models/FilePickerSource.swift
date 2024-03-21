public enum FilePickerSource: Identifiable {
    /// Allows taking pictures from camera and applies selected crop mode / compression on selected image(s)
    case camera(
        cropMode: ImagePickerViewCropMode,
        compression: ImagePickerViewCompression = .compressed()
    )
    
    /// Allows picking photos exclusively and applies selected crop mode / compression on selected image(s)
    /// Note: If you specify the selection limit more than 1 and cropMode to `allowed` this is going to trigger an assertion
    case photos(
        selectionLimit: Int,
        cropMode: ImagePickerViewCropMode,
        compression: ImagePickerViewCompression = .compressed()
    )
    
    /// Allows picking files from documents
    case files(allowMultipleSelection: Bool)
    
    /// Allows picking multimedia (Photos / Videos) and applies selected image compression
    /// On selected images and preview images that's extracted off selected videos
    case multimedia(
        selectionLimit: Int,
        imageCompression: ImagePickerViewCompression = .compressed()
    )
    
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
