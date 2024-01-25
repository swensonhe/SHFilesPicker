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
    
    private func process(image: UIImage) {
        process(images: [image])
    }
    
    private func process(images: [UIImage]) {
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
                    width: image.size.width,
                    height: image.size.height
                )
                
                files.append(file)
            }
        }
        
        onSelect(files)
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
            parent.process(image: image)
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
                
                switch parent.cropMode {
                case .allowed(let presetFixedRatioType):
                    if images.count == 1 {
                        let image = images[0]
                        
                        viewController?.present(
                            makeCropViewController(with: image, presetFixedRatioType: presetFixedRatioType),
                            animated: true
                        )
                        
                    } else {
                        assertionFailure("Crop mode is set to allowed while there is more than one image, this is not allowed!")
                        parent.process(images: images)
                    }
                    
                case .notAllowed:
                    parent.process(images: images)
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
}

extension ImagePickerView.Coordinator: CropViewControllerDelegate {
    
    func cropViewControllerDidCrop(
        _ cropViewController: CropViewController,
        cropped: UIImage,
        transformation: Transformation,
        cropInfo: CropInfo
    ) {
        parent.process(image: cropped)
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
