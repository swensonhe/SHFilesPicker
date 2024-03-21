import SwiftUI

public struct FilePickerViewModifier: ViewModifier {
    // MARK: Binding
    @Binding private var filePickerSource: FilePickerSource?
    
    // MARK: Properties
    private let onSelect: ([File]) -> Void
    private let onCancel: (() -> Void)?
    private let onStartImageProcessing: (() -> Void)?
    private let onEndImageProcessing: (() -> Void)?
    
    init(
        filePickerSource: Binding<FilePickerSource?>,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartImageProcessing: (() -> Void)? = nil,
        onEndImageProcessing: (() -> Void)? = nil
    ) {
        self._filePickerSource = filePickerSource
        self.onSelect = onSelect
        self.onCancel = onCancel
        self.onStartImageProcessing = onStartImageProcessing
        self.onEndImageProcessing = onEndImageProcessing
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
                }
            }
    }
}

extension View {
    public func withFilePicker(
        source: Binding<FilePickerSource?>,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil,
        onStartImageProcessing: (() -> Void)? = nil,
        onEndImageProcessing: (() -> Void)? = nil
    ) -> some View {
        modifier(FilePickerViewModifier(
            filePickerSource: source,
            onSelect: onSelect,
            onCancel: onCancel,
            onStartImageProcessing: onStartImageProcessing,
            onEndImageProcessing: onEndImageProcessing
        ))
    }
}
