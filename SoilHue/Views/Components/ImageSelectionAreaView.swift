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
                }
            case .full:
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                
                Text("Se analizará la imagen completa")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
} 