import SwiftUI

public struct ImagePickerViewModifier: ViewModifier {
    
    @Binding private var imagePickerSource: FilePickerSource?
    
    private let cropMode: ImagePickerViewCropMode
    private let compression: ImagePickerViewCompression
    private let onSelect: ([File]) -> Void
    private let onCancel: (() -> Void)?
    
    init(
        imagePickerSource: Binding<FilePickerSource?>,
        cropMode: ImagePickerViewCropMode,
        compression: ImagePickerViewCompression,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self._imagePickerSource = imagePickerSource
        self.cropMode = cropMode
        self.compression = compression
        self.onSelect = onSelect
        self.onCancel = onCancel
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(item: $imagePickerSource) { imagePickerSource in
                switch imagePickerSource {
                case .camera:
                    ImagePickerView(
                        source: .camera,
                        cropMode: cropMode,
                        compression: compression,
                        onSelect: { files in
                            self.imagePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.imagePickerSource = nil
                            onCancel?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .photos(let selectionLimit):
                    ImagePickerView(
                        source: .photos(selectionLimit: selectionLimit),
                        cropMode: cropMode,
                        compression: compression,
                        onSelect: { files in
                            self.imagePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.imagePickerSource = nil
                            onCancel?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .files:
                    makeEmptyView()
                }
            }
    }
    
    private func makeEmptyView() -> EmptyView {
        assertionFailure("Unsupported type for ImagePickerViewModifier")
        return EmptyView()
    }
    
}

extension View {
    
    public func withImagePicker(
        source: Binding<FilePickerSource?>,
        cropMode: ImagePickerViewCropMode,
        compression: ImagePickerViewCompression,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(ImagePickerViewModifier(
            imagePickerSource: source,
            cropMode: cropMode,
            compression: compression,
            onSelect: onSelect,
            onCancel: onCancel
        ))
    }
    
}
