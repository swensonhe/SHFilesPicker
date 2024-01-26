import SwiftUI
import UIKit
import Mantis
import PhotosUI

public enum ImagePickerViewCropMode {
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

public enum ImagePickerViewCompression {
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
        case multimedia(selectionLimit: Int)
        case photos(selectionLimit: Int)
        case camera
    }
    
    private let source: Source
    private let cropMode: ImagePickerViewCropMode
    private let compression: ImagePickerViewCompression
    private let onSelect: ([File]) -> Void
    private let onCancel: () -> Void
    private let onStartImageProcessing: () -> Void
    private let onEndImageProcessing: () -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    
    init(
        source: Source,
        cropMode: ImagePickerViewCropMode,
        compression: ImagePickerViewCompression = .compressed(),
        onSelect: @escaping ([File]) -> Void,
        onCancel: @escaping () -> Void,
        onStartImageProcessing: @escaping () -> Void,
        onEndImageProcessing: @escaping () -> Void
    ) {
        self.source = source
        self.cropMode = cropMode
        self.compression = compression
        self.onSelect = onSelect
        self.onCancel = onCancel
        self.onStartImageProcessing = onStartImageProcessing
        self.onEndImageProcessing = onEndImageProcessing
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIViewController {
        switch source {
        case .multimedia(let selectionLimit):
            assert(!(selectionLimit > 1 && cropMode.isCropAllowed), "Crop mode is set to allowed while selection limit is more than one, this is not allowed!")
            
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.images, .videos])
            configuration.selectionLimit = selectionLimit
            
            let photosPickerViewController = PHPickerViewController(configuration: configuration)
            photosPickerViewController.delegate = context.coordinator
            
            context.coordinator.viewController = photosPickerViewController
            
            return photosPickerViewController
            
        case .photos(let selectionLimit):
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
                    name: "Image",
                    data: data,
                    uniformType: .jpeg,
                    url: nil,
                    previewURL: nil,
                    width: resizedImage.size.width,
                    height: resizedImage.size.height
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
                    name: "Image",
                    data: data,
                    uniformType: .jpeg,
                    url: nil,
                    previewURL: nil,
                    width: image.size.width,
                    height: image.size.height
                )
                
                files.append(file)
            }
        }
        
        return files
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
    
    private func process(video url: URL) async -> File? {
        switch compression {
        case .original:
            do {
                let previewImage = try await url.getVideoPreviewImage()
                let previewData = previewImage.jpegData(compressionQuality: 1.0)
                let previewURL = try previewData?.writeToTempDirectory(fileName: "\(UUID().uuidString).jpeg")
                
                return File(
                    id: UUID().uuidString,
                    name: "Video",
                    data: nil,
                    uniformType: UTType(filenameExtension: url.pathExtension),
                    url: url,
                    previewURL: previewURL,
                    width: previewImage.size.width,
                    height: previewImage.size.height
                )
            } catch {
                debugPrint(error)
                return nil
            }
            
        case .compressed(let maximumSize, let quality):
            do {
                let previewImage = try await url.getVideoPreviewImage()
                let resizedImage = previewImage.resized(to: maximumSize)
                let previewData = resizedImage.jpegData(compressionQuality: quality.value)
                let previewURL = try previewData?.writeToTempDirectory(fileName: "\(UUID().uuidString).jpeg")
                
                return File(
                    id: UUID().uuidString,
                    name: "Video",
                    data: nil,
                    uniformType: UTType(filenameExtension: url.pathExtension),
                    url: url,
                    previewURL: previewURL,
                    width: previewImage.size.width,
                    height: previewImage.size.height
                )
            } catch {
                debugPrint(error)
                return nil
            }
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
                    parent.onStartImageProcessing()
                    
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
                    parent.onSelect((images + videos).shuffled())
                    parent.onEndImageProcessing()
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
    
    private func loadVideo(from itemProvider: NSItemProvider) async -> URL? {
        return await withCheckedContinuation { continuation in
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
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
            self.parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true) { [weak self] in
            guard
                let self,
                let viewController = self.viewController
            else {
                return
            }
            
            // If the sourceType is camera, we need to recreate the ViewController
            if self.parent.source == .camera {
                self.parent.makeImagePickerController(
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
