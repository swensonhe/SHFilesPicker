import SwiftUI

public struct FilePickerViewModifier: ViewModifier {
    // MARK: Binding
    @Binding private var filePickerSource: FilePickerSource?
    
    // MARK: Properties
    private let onSelect: ([File]) -> Void
    private let onCancel: (() -> Void)?
    private let onStartAssetsProcessing: (() -> Void)?
    private let onEndAssetsProcessing: (() -> Void)?
    
    init(
        filePickerSource: Binding<FilePickerSource?>,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartAssetsProcessing: (() -> Void)? = nil,
        onEndAssetsProcessing: (() -> Void)? = nil
    ) {
        self._filePickerSource = filePickerSource
        self.onSelect = onSelect
        self.onCancel = onCancel
        self.onStartAssetsProcessing = onStartAssetsProcessing
        self.onEndAssetsProcessing = onEndAssetsProcessing
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(item: $filePickerSource) { filePickerSource in
                switch filePickerSource {
                case .camera(let cropMode, let compression):
                    ImagePickerView(
                        source: .camera(cropMode: cropMode, compression: compression),
                        onSelect: { files in
                            self.filePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartAssetsProcessing: {
                            self.filePickerSource = nil
                            onStartAssetsProcessing?()
                        },
                        onEndAssetsProcessing: {
                            self.filePickerSource = nil
                            onEndAssetsProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .photos(let selectionLimit, let cropMode, let compression):
                    ImagePickerView(
                        source: .photos(
                            selectionLimit: selectionLimit,
                            cropMode: cropMode,
                            compression: compression
                        ),
                        onSelect: {
                            files in
                            self.filePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartAssetsProcessing: {
                            self.filePickerSource = nil
                            onStartAssetsProcessing?()
                        },
                        onEndAssetsProcessing: {
                            self.filePickerSource = nil
                            onEndAssetsProcessing?()
                        }
                    )
                    .ignoresSafeArea()
                    
                case .files(let allowMultipleSelection):
                    DocumentPickerView(
                        allowsMultipleSelection: allowMultipleSelection,
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
                    
                case .multimedia(let selectionLimit, let imageCompression):
                    ImagePickerView(
                        source: .multimedia(selectionLimit: selectionLimit, imageCompression: imageCompression),
                        onSelect: { files in
                            self.filePickerSource = nil
                            onSelect(files)
                        },
                        onCancel: {
                            self.filePickerSource = nil
                            onCancel?()
                        },
                        onStartAssetsProcessing: {
                            self.filePickerSource = nil
                            onStartAssetsProcessing?()
                        },
                        onEndAssetsProcessing: {
                            self.filePickerSource = nil
                            onEndAssetsProcessing?()
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
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartAssetsProcessing: (() -> Void)? = nil,
        onEndAssetsProcessing: (() -> Void)? = nil
    ) -> some View {
        modifier(FilePickerViewModifier(
            filePickerSource: source,
            onSelect: onSelect,
            onCancel: onCancel,
            onStartAssetsProcessing: onStartAssetsProcessing,
            onEndAssetsProcessing: onEndAssetsProcessing
        ))
    }
}
