import SwiftUI

/// Vista que permite al usuario seleccionar una región de una imagen.
///
/// Esta vista proporciona una interfaz interactiva para:
/// - Mostrar una imagen
/// - Permitir al usuario dibujar un rectángulo para seleccionar una región
/// - Mostrar visualmente la región seleccionada
/// - Convertir las coordenadas de selección a valores normalizados (0-1)
///
/// La vista está diseñada para ser usada en conjunto con el análisis de color,
/// permitiendo al usuario seleccionar una región específica de la imagen para analizar.
struct ColorSelectionView: View {
    /// La imagen sobre la que se realizará la selección.
    let image: UIImage
    
    /// Binding a la región seleccionada, en coordenadas normalizadas (0-1).
    @Binding var selectionRect: CGRect?
    
    /// Punto de inicio de la selección.
    @State private var startPoint: CGPoint?
    
    /// Rectángulo actual de selección.
    @State private var currentRect: CGRect?
    
    /// Indica si el usuario está actualmente arrastrando para seleccionar.
    @State private var isDragging = false
    
    /// Contenido principal de la vista.
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Mostrar la imagen
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Mostrar el rectángulo de selección si existe
                if let rect = currentRect {
                    Rectangle()
                        .path(in: rect)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5, 5], dashPhase: 0))
                        .background(
                            Rectangle()
                                .path(in: rect)
                                .fill(Color.blue.opacity(0.2))
                        )
                }
                
                // Instrucciones para el usuario
                if currentRect == nil {
                    Text(NSLocalizedString("analysis.drag.select", comment: "Drag to select area instruction"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            startPoint = value.location
                            isDragging = true
                        }
                        
                        if let start = startPoint {
                            let rect = CGRect(
                                x: min(start.x, value.location.x),
                                y: min(start.y, value.location.y),
                                width: abs(value.location.x - start.x),
                                height: abs(value.location.y - start.y)
                            )
                            currentRect = rect
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        if let rect = currentRect {
                            // Convertir las coordenadas a valores relativos (0-1)
                            let relativeRect = CGRect(
                                x: rect.origin.x / geometry.size.width,
                                y: rect.origin.y / geometry.size.height,
                                width: rect.width / geometry.size.width,
                                height: rect.height / geometry.size.height
                            )
                            selectionRect = relativeRect
                        }
                    }
            )
        }
    }
}

#Preview {
    ColorSelectionView(
        image: UIImage(systemName: "photo")!,
        selectionRect: .constant(nil)
    )
} 