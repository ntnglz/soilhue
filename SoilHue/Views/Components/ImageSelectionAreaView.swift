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
                    Text("Área seleccionada: \(Int(rect.width * 100))% x \(Int(rect.height * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Arrastra para seleccionar un área\no pulsa Analizar para procesar la imagen completa")
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
                    Text("Polígono con \(points.count) vértices")
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