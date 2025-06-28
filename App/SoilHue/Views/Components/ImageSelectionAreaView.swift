import SwiftUI

struct ImageSelectionAreaView: View {
    let image: UIImage
    let selectionMode: SelectionMode
    @Binding var selectionRect: CGRect?
    @Binding var polygonPoints: [CGPoint]?
    
    var body: some View {
        VStack {
            switch selectionMode {
            case .rectangle:
                ColorSelectionView(image: image, selectionRect: $selectionRect)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                
                if let rect = selectionRect {
                    Text(String(format: NSLocalizedString("analysis.area.selected", comment: "Selected area format"), Int(rect.width * 100), Int(rect.height * 100)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(NSLocalizedString("analysis.drag.select", comment: "Drag to select instruction"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
            case .polygon:
                PolygonSelectionView(image: image, polygonPoints: $polygonPoints)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                
                if let points = polygonPoints, points.count >= 3 {
                    Text(String(format: NSLocalizedString("selection.polygon.vertices", comment: ""), points.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Toca para crear un polígono\no pulsa Analizar para procesar la imagen completa")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                }
            }
        }
    }
} 