import SwiftUI

struct SelectionModePickerView: View {
    @Binding var selectionMode: SelectionMode
    
    var body: some View {
        Picker("Modo de selección", selection: $selectionMode) {
            Text("Rectángulo").tag(SelectionMode.rectangle)
            Text("Polígono").tag(SelectionMode.polygon)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
} 