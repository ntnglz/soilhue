import SwiftUI

/// Vista que permite al usuario seleccionar una región poligonal de una imagen.
///
/// Esta vista proporciona una interfaz interactiva para:
/// - Mostrar una imagen
/// - Permitir al usuario tocar puntos para crear un polígono
/// - Mostrar visualmente el polígono seleccionado
/// - Convertir las coordenadas de selección a valores normalizados (0-1)
///
/// La vista está diseñada para ser usada en conjunto con el análisis de color,
/// permitiendo al usuario seleccionar una región específica de la imagen para analizar.
struct PolygonSelectionView: View {
    /// La imagen sobre la que se realizará la selección.
    let image: UIImage
    
    /// Binding a los puntos del polígono seleccionado, en coordenadas normalizadas (0-1).
    @Binding var polygonPoints: [CGPoint]?
    
    /// Puntos actuales del polígono en coordenadas de la vista.
    @State private var currentPoints: [CGPoint] = []
    
    /// Indica si el polígono está completo.
    @State private var isPolygonComplete = false
    
    /// Contenido principal de la vista.
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Mostrar la imagen
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Mostrar el polígono si hay puntos
                if !currentPoints.isEmpty {
                    Path { path in
                        // Dibujar el polígono
                        path.move(to: currentPoints[0])
                        for point in currentPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                        
                        // Cerrar el polígono si está completo
                        if isPolygonComplete {
                            path.closeSubpath()
                        }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5, 5], dashPhase: 0))
                    .background(
                        Path { path in
                            path.move(to: currentPoints[0])
                            for point in currentPoints.dropFirst() {
                                path.addLine(to: point)
                            }
                            if isPolygonComplete {
                                path.closeSubpath()
                            }
                        }
                        .fill(Color.blue.opacity(0.2))
                    )
                    
                    // Mostrar los puntos del polígono
                    ForEach(0..<currentPoints.count, id: \.self) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                            .position(currentPoints[index])
                    }
                }
                
                // Instrucciones para el usuario
                if currentPoints.isEmpty {
                    Text(NSLocalizedString("selection.polygon.instruction", comment: "Polygon selection instruction"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                } else if !isPolygonComplete {
                    Text(NSLocalizedString("selection.polygon.complete", comment: "Complete polygon instruction"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
                
                // Botón para reiniciar la selección
                if !currentPoints.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                resetSelection()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                addPoint(at: location, in: geometry)
            }
            .onTapGesture(count: 2) {
                completePolygon(in: geometry)
            }
        }
    }
    
    /// Añade un punto al polígono en la ubicación especificada.
    ///
    /// - Parameters:
    ///   - location: La ubicación del toque en coordenadas de la vista.
    ///   - geometry: El GeometryProxy que proporciona el tamaño de la vista.
    private func addPoint(at location: CGPoint, in geometry: GeometryProxy) {
        // Si el polígono ya está completo, reiniciar
        if isPolygonComplete {
            resetSelection()
        }
        
        // Añadir el nuevo punto
        currentPoints.append(location)
        
        // Si hay al menos 3 puntos, actualizar el binding
        if currentPoints.count >= 3 {
            updateBinding(in: geometry)
        }
    }
    
    /// Completa el polígono y actualiza el binding.
    ///
    /// - Parameter geometry: El GeometryProxy que proporciona el tamaño de la vista.
    private func completePolygon(in geometry: GeometryProxy) {
        // Solo completar si hay al menos 3 puntos
        if currentPoints.count >= 3 {
            isPolygonComplete = true
            updateBinding(in: geometry)
        }
    }
    
    /// Actualiza el binding con los puntos normalizados.
    ///
    /// - Parameter geometry: El GeometryProxy que proporciona el tamaño de la vista.
    private func updateBinding(in geometry: GeometryProxy) {
        // Convertir las coordenadas a valores relativos (0-1)
        let normalizedPoints = currentPoints.map { point in
            CGPoint(
                x: point.x / geometry.size.width,
                y: point.y / geometry.size.height
            )
        }
        polygonPoints = normalizedPoints
    }
    
    /// Reinicia la selección del polígono.
    private func resetSelection() {
        currentPoints = []
        isPolygonComplete = false
        polygonPoints = nil
    }
}

#Preview {
    PolygonSelectionView(
        image: UIImage(systemName: "photo")!,
        polygonPoints: .constant(nil)
    )
} 