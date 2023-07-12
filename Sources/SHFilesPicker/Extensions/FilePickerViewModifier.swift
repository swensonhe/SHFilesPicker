import SwiftUI

public struct FilePickerViewModifier: ViewModifier {
    
    @Binding private var filePickerSource: FilePickerSource?
    
    private let imagePickerViewCropMode: ImagePickerViewCropMode
    private let imagePickerViewCompression: ImagePickerViewCompression
    private let doucmentPickerViewAllowsMultipleSelection: Bool
    private let onSelect: ([File]) -> Void
    private let onCancel: (() -> Void)?
    private let onStartImageProcessing: (() -> Void)?
    private let onEndImageProcessing: (() -> Void)?
    
    init(
        filePickerSource: Binding<FilePickerSource?>,
        imagePickerViewCropMode: ImagePickerViewCropMode,
        imagePickerViewCompression: ImagePickerViewCompression,
        doucmentPickerViewAllowsMultipleSelection: Bool,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartImageProcessing: (() -> Void)? = nil,
        onEndImageProcessing: (() -> Void)? = nil
    ) {
        self._filePickerSource = filePickerSource
        self.imagePickerViewCropMode = imagePickerViewCropMode
        self.imagePickerViewCompression = imagePickerViewCompression
        self.doucmentPickerViewAllowsMultipleSelection = doucmentPickerViewAllowsMultipleSelection
        self.onSelect = onSelect
        self.onCancel = onCancel
        self.onStartImageProcessing = onStartImageProcessing
        self.onEndImageProcessing = onEndImageProcessing
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(item: $filePickerSource) { filePickerSource in
                switch filePickerSource {
                case .camera:
                    ImagePickerView(
                        source: .camera,
                        cropMode: imagePickerViewCropMode,
                        compression: imagePickerViewCompression,
                        onSelect: { files in
                            self.filePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartImageProcessing: {
                            self.filePickerSource = nil
                            onStartImageProcessing?()
                        },
                        onEndImageProcessing: {
                            self.filePickerSource = nil
                            onEndImageProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .photos(let selectionLimit):
                    ImagePickerView(
                        source: .photos(selectionLimit: selectionLimit),
                        cropMode: imagePickerViewCropMode,
                        compression: imagePickerViewCompression,
                        onSelect: { files in
                            self.filePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartImageProcessing: {
                            self.filePickerSource = nil
                            onStartImageProcessing?()
                        },
                        onEndImageProcessing: {
                            self.filePickerSource = nil
                            onEndImageProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .files:
                    DocumentPickerView(
                        allowsMultipleSelection: doucmentPickerViewAllowsMultipleSelection,
                        onSelect: { files in
                            self.filePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        }
                    )
                    .ignoresSafeArea()
                }
            }
    }
    
}

extension View {
    
    public func withFilePicker(
        source: Binding<FilePickerSource?>,
        imagePickerViewCropMode: ImagePickerViewCropMode,
        imagePickerViewCompression: ImagePickerViewCompression,
        doucmentPickerViewAllowsMultipleSelection: Bool,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartImageProcessing: (() -> Void)? = nil,
        onEndImageProcessing: (() -> Void)? = nil
    ) -> some View {
        modifier(FilePickerViewModifier(
            filePickerSource: source,
            imagePickerViewCropMode: imagePickerViewCropMode,
            imagePickerViewCompression: imagePickerViewCompression,
            doucmentPickerViewAllowsMultipleSelection: doucmentPickerViewAllowsMultipleSelection,
            onSelect: onSelect,
            onCancel: onCancel,
            onStartImageProcessing: onStartImageProcessing,
            onEndImageProcessing: onEndImageProcessing
        ))
    }
    
}
