import SwiftUI

struct SelectionModePickerView: View {
    @Binding var selectionMode: SelectionMode
    
    var body: some View {
        Picker("Modo de selección", selection: $selectionMode) {
            Text(NSLocalizedString("selection.mode.rectangle", comment: "Rectangle selection mode"))
                .tag(SelectionMode.rectangle)
            Text(NSLocalizedString("selection.mode.polygon", comment: "Polygon selection mode"))
                .tag(SelectionMode.polygon)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
} 