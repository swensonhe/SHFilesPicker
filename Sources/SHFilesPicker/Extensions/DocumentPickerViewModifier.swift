import SwiftUI

public struct DocumentPickerViewModifier: ViewModifier {
    // MARK: Binding
    @Binding private var isPresented: Bool
    
    // MARK: Properties
    private let doucmentPickerViewAllowsMultipleSelection: Bool
    private let onSelect: ([File]) -> Void
    private let onCancel: (() -> Void)?
    
    init(
        isPresented: Binding<Bool>,
        doucmentPickerViewAllowsMultipleSelection: Bool,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.doucmentPickerViewAllowsMultipleSelection = doucmentPickerViewAllowsMultipleSelection
        self.onSelect = onSelect
        self.onCancel = onCancel
    }
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                DocumentPickerView(
                    allowsMultipleSelection: doucmentPickerViewAllowsMultipleSelection,
                    onSelect: { files in
                        isPresented = false
                        onSelect(files)
                    },
                    onCancel: {
                        isPresented = false
                        onCancel?()
                    }
                )
                .ignoresSafeArea()
            }
    }
}

extension View {
    public func withDocumentPicker(
        isPresented: Binding<Bool>,
        doucmentPickerViewAllowsMultipleSelection: Bool,
        onSelect: @escaping ([File]) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(DocumentPickerViewModifier(
            isPresented: isPresented,
            doucmentPickerViewAllowsMultipleSelection: doucmentPickerViewAllowsMultipleSelection,
            onSelect: onSelect,
            onCancel: onCancel
        ))
    }
}
