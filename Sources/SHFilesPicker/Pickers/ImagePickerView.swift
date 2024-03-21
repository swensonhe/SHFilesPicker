import SwiftUI
import UIKit
import Mantis
import PhotosUI

extension PresetFixedRatioType: Equatable {
    public static func == (lhs: PresetFixedRatioType, rhs: PresetFixedRatioType) -> Bool {
        switch (lhs, rhs) {
        case (.alwaysUsingOnePresetFixedRatio(let lhsRatio), .alwaysUsingOnePresetFixedRatio(let rhsRatio)):
            return lhsRatio == rhsRatio
        case (.canUseMultiplePresetFixedRatio(let lhsDefaultRatio), .canUseMultiplePresetFixedRatio(let rhsDefaultRatio)):
            return lhsDefaultRatio == rhsDefaultRatio
        case (.alwaysUsingOnePresetFixedRatio, _), (.canUseMultiplePresetFixedRatio, _):
            return false
        }
    }
}

public enum ImagePickerViewCropMode: Equatable {
    case allowed(presetFixedRatioType: PresetFixedRatioType)
    case notAllowed
    
    var isCropAllowed: Bool {
        switch self {
        case .allowed:
            return true
            
        case .notAllowed:
            return false
        }
    }
}

public enum ImagePickerViewCompression: Equatable {
    public enum Quality {
        case low
        case medium
        case high
        case original
        
        var value: Double {
            switch self {
            case .low:
                return 0.25
                
            case .medium:
                return 0.5
                
            case .high:
                return 0.75
                
            case .original:
                return 1.0
            }
        }
    }
    
    case original
    case compressed(maximumSize: CGSize = .init(width: 1920, height: 1080), quality: Quality = .medium)
}

struct ImagePickerView: UIViewControllerRepresentable {
    enum Source: Equatable {
        /// Allows picking multimedia (Photos / Videos) and applies selected image compression
        /// On selected images and preview images that's extracted off selected videos
        case multimedia(
            selectionLimit: Int,
            imageCompression: ImagePickerViewCompression = .compressed()
        )
        
        /// Allows picking photos exclusively and applies selected crop mode / compression on selected image(s)
        /// Note: If you specify the selection limit more than 1 and cropMode to `allowed` this is going to trigger an assertion
        case photos(
            selectionLimit: Int,
            cropMode: ImagePickerViewCropMode,
            compression: ImagePickerViewCompression = .compressed()
        )
        
        /// Allows taking pictures from camera and applies selected crop mode / compression on selected image(s)
        case camera(
            cropMode: ImagePickerViewCropMode,
            compression: ImagePickerViewCompression = .compressed()
        )
    }
    
    // MARK: Environment
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: Properties
    private let source: Source
    private let cropMode: ImagePickerViewCropMode
    private let compression: ImagePickerViewCompression
    private let onSelect: ([File]) -> Void
    private let onCancel: () -> Void
    private let onStartAssetsProcessing: () -> Void
    private let onEndAssetsProcessing: () -> Void
    
    init(
        source: Source,
        onSelect: @escaping ([File]) -> Void,
        onCancel: @escaping () -> Void,
        onStartAssetsProcessing: @escaping () -> Void,
        onEndAssetsProcessing: @escaping () -> Void
    ) {
        switch source {
        case .multimedia(_, let imageCompression):
            self.cropMode = .notAllowed
            self.compression = imageCompression
            
        case let .photos(selectionLimit, cropMode, compression):
            if selectionLimit > 1 && cropMode != .notAllowed {
                assertionFailure("Crop mode is not allowed when the selection limit is more than one")
            }
            
            self.cropMode = cropMode
            self.compression = compression
            
        case .camera(let cropMode, let compression):
            self.cropMode = cropMode
            self.compression = compression
        }
        
        self.source = source
        self.onSelect = onSelect
        self.onCancel = onCancel
        self.onStartAssetsProcessing = onStartAssetsProcessing
        self.onEndAssetsProcessing = onEndAssetsProcessing
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIViewController {
        switch source {
        case .multimedia(let selectionLimit, _):
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.images, .videos])
            configuration.selectionLimit = selectionLimit
            
            let photosPickerViewController = PHPickerViewController(configuration: configuration)
            photosPickerViewController.delegate = context.coordinator
            
            context.coordinator.viewController = photosPickerViewController
            
            return photosPickerViewController
            
        case .photos(let selectionLimit, _, _):
            assert(!(selectionLimit > 1 && cropMode.isCropAllowed), "Crop mode is set to allowed while selection limit is more than one, this is not allowed!")
            
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.images])
            configuration.selectionLimit = selectionLimit
            
            let photosPickerViewController = PHPickerViewController(configuration: configuration)
            photosPickerViewController.delegate = context.coordinator
            
            context.coordinator.viewController = photosPickerViewController
            
            return photosPickerViewController
            
        case .camera:
            let viewController = UIViewController()
            
            makeImagePickerController(
                delegate: context.coordinator,
                addedTo: viewController
            )
            
            context.coordinator.viewController = viewController
            
            return viewController
        }
    }
    
    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: UIViewControllerRepresentableContext<ImagePickerView>
    ) { }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    private func makeImagePickerController(
        delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate,
        addedTo parent: UIViewController
    ) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = delegate
        
        parent.children.forEach { $0.removeFromParent() }
        parent.view.subviews.forEach { $0.removeFromSuperview() }
        
        parent.view.addSubview(imagePickerController.view)
        parent.addChild(imagePickerController)
        
        imagePickerController.view.frame = parent.view.bounds
    }
    
    private func process(image: UIImage) -> File {
        return process(images: [image])[0]
    }
    
    private func process(images: [UIImage]) -> [File] {
        var files: [File] = []
        
        switch compression {
        case .compressed(let maximumSize, let quality):
            images.forEach { image in
                let resizedImage = image.resized(to: maximumSize)
                
                guard
                    let data = resizedImage.jpegData(compressionQuality: quality.value)
                else {
                    assertionFailure("The image has no data or the underlying CGImageRef contains data in an unsupported bitmap format.")
                    return
                }
                
                let file = File(
                    id: UUID().uuidString,
                    name: "image",
                    type: .image(ImageFile(data: data, image: resizedImage, size: resizedImage.size, uniformType: .jpeg))
                )
                
                files.append(file)
            }
            
        case .original:
            images.forEach { image in
                guard
                    let data = image.jpegData(compressionQuality: 1.0)
                else {
                    assertionFailure("The image has no data or the underlying CGImageRef contains data in an unsupported bitmap format.")
                    return
                }
                
                let file = File(
                    id: UUID().uuidString,
                    name: "image",
                    type: .image(ImageFile(data: data, image: image, size: image.size, uniformType: .jpeg))
                )
                
                files.append(file)
            }
        }
        
        return files
    }
    
    private func resolutionForVideo(at url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: .video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    private func process(video url: URL) async -> File? {
        let videoResolution = resolutionForVideo(at: url)
        
        if videoResolution == nil {
            debugPrint("Unable to calculate size for video, will default to image size")
        }
        
        switch compression {
        case .compressed(let maximumSize, let quality):
            do {
                let previewImage = try await url.getVideoPreviewImage()
                let resizedImage = previewImage.resized(to: maximumSize)
                guard let previewData = resizedImage.jpegData(compressionQuality: quality.value) else {
                    assertionFailure("Unable to create jpegData from resizedImage")
                    return nil
                }
                
                let videoFile = VideoFile(
                    url: url,
                    data: try Data(contentsOf: url),
                    previewData: previewData,
                    previewImage: resizedImage,
                    previewUniformType: .jpeg,
                    size: videoResolution ?? resizedImage.size,
                    uniformType: UTType(filenameExtension: url.pathExtension)
                )
                
                return File(
                    id: UUID().uuidString,
                    name: "video",
                    type: .video(videoFile)
                )

            } catch {
                debugPrint(error)
                return nil
            }
            
        case .original:
            do {
                let previewImage = try await url.getVideoPreviewImage()
                guard let previewData = previewImage.jpegData(compressionQuality: 1.0) else {
                    assertionFailure("Unable to create jpegData from resizedImage")
                    return nil
                }
                
                let videoFile = VideoFile(
                    url: url,
                    data: try Data(contentsOf: url),
                    previewData: previewData,
                    previewImage: previewImage,
                    previewUniformType: .jpeg,
                    size: videoResolution ?? previewImage.size,
                    uniformType: UTType(filenameExtension: url.pathExtension)
                )
                
                return File(
                    id: UUID().uuidString,
                    name: "video",
                    type: .video(videoFile)
                )
            } catch {
                debugPrint(error)
                return nil
            }
        }
    }
    
    private func process(videos: [URL]) async -> [File] {
        return await withTaskGroup(of: File?.self, returning: [File].self) { group in
            var files: [File] = []
            
            for video in videos {
                group.addTask {
                    return await self.process(video: video)
                }
            }
            
            for await file in group {
                if let file {
                    files.append(file)
                }
            }
            
            return files
        }
    }
}

extension ImagePickerView {
    class Coordinator: NSObject {
        private let parent: ImagePickerView
        weak var viewController: UIViewController?
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func makeCropViewController(with image: UIImage, presetFixedRatioType: PresetFixedRatioType) -> CropViewController {
            var config = Mantis.Config()
            config.presetFixedRatioType = presetFixedRatioType
            
            let cropViewController = Mantis.cropViewController(
                image: image,
                config: config
            )
            
            cropViewController.delegate = self
            
            return cropViewController
        }
    }
}

extension ImagePickerView.Coordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        var image = UIImage()
        
        if let editedImage = info[.editedImage] as? UIImage {
            image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            image = originalImage
        }
        
        switch parent.cropMode {
        case .allowed(let presetFixedRatioType):
            viewController?.present(
                makeCropViewController(with: image, presetFixedRatioType: presetFixedRatioType),
                animated: true
            )
            
        case .notAllowed:
            parent.presentationMode.wrappedValue.dismiss()
            let file = parent.process(image: image)
            parent.onSelect([file])
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.presentationMode.wrappedValue.dismiss()
        parent.onCancel()
    }
}

extension ImagePickerView.Coordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.isEmpty {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCancel()
        } else {
            Task { @MainActor in
                switch parent.cropMode {
                case .notAllowed:
                    parent.presentationMode.wrappedValue.dismiss()
                    parent.onStartAssetsProcessing()
                    
                default:
                    break
                }
                
                let itemProviders = results.map(\.itemProvider)
                let images = await loadImages(from: itemProviders)
                let videos = await loadVideos(from: itemProviders)
                
                switch parent.cropMode {
                case .allowed(let presetFixedRatioType):
                    if images.count == 1 && videos.isEmpty {
                        let image = images[0]
                        
                        viewController?.present(
                            makeCropViewController(with: image, presetFixedRatioType: presetFixedRatioType),
                            animated: true
                        )
                    } else {
                        assertionFailure("Crop mode is set to allowed while there is video or more than one image, this is not allowed!")
                        let files = parent.process(images: images)
                        parent.onSelect(files)
                    }
                    
                case .notAllowed:
                    let images = parent.process(images: images)
                    let videos = await parent.process(videos: videos)
                    parent.onSelect(images + videos)
                    parent.onEndAssetsProcessing()
                }
            }
        }
    }
    
    private func loadImage(from itemProvider: NSItemProvider) async -> Data? {
        return await withCheckedContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
                let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                
                let downsampleOptions = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 2_000,
                ] as [CFString : Any] as CFDictionary
                
                let destinationProperties = [
                    kCGImageDestinationLossyCompressionQuality: 1
                ] as CFDictionary
                
                let data = NSMutableData()
                
                guard
                    let url,
                    let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions),
                    let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions),
                    let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
                else {
                    continuation.resume(returning: nil)
                    return
                }
                
                CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
                CGImageDestinationFinalize(imageDestination)
                
                continuation.resume(returning: data as Data)
            }
        }
    }
    
    private func loadImages(from itemProviders: [NSItemProvider]) async -> [UIImage] {
        return await withTaskGroup(of: Data?.self, returning: [UIImage].self) { group in
            var images: [UIImage] = []
            
            for itemProvider in itemProviders {
                group.addTask {
                    return await self.loadImage(from: itemProvider)
                }
            }
            
            for await data in group {
                if let data, let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            return images
        }
    }
    
    private func loadVideo(from itemProvider: NSItemProvider) async -> URL? {
        return await withCheckedContinuation { continuation in
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error {
                        debugPrint(error)
                    }
                    
                    do {
                        let tempURL = try url?.moveToTempDirectory(fileName: UUID().uuidString)
                        continuation.resume(returning: tempURL)
                    } catch {
                        debugPrint(error)
                        continuation.resume(returning: nil)
                    }
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func loadVideos(from itemProviders: [NSItemProvider]) async -> [URL] {
        return await withTaskGroup(of: URL?.self, returning: [URL].self) { group in
            var videos: [URL] = []
            
            for itemProvider in itemProviders {
                group.addTask {
                    return await self.loadVideo(from: itemProvider)
                }
            }
            
            for await url in group {
                if let url {
                    videos.append(url)
                }
            }
            
            return videos
        }
    }
}

extension ImagePickerView.Coordinator: CropViewControllerDelegate {
    func cropViewControllerDidCrop(
        _ cropViewController: CropViewController,
        cropped: UIImage,
        transformation: Transformation,
        cropInfo: CropInfo
    ) {
        let file = parent.process(image: cropped)
        parent.onSelect([file])
        cropViewController.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true) { [weak self] in
            guard
                let self,
                let viewController = viewController
            else {
                return
            }
            
            // If the sourceType is camera, we need to recreate the ViewController
            switch parent.source {
            case .multimedia, .photos:
                // No-op
                break
                
            case .camera:
                parent.makeImagePickerController(
                    delegate: self,
                    addedTo: viewController
                )
            }
        }
    }
    
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
        
    }
    
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController) {
        
    }
    
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo) {
        
    }
}

extension NSItemProvider: @unchecked Sendable {
    
}
