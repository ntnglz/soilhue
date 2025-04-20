import SwiftUI

/// Vista que muestra una guía visual para la calibración correcta
struct CalibrationGuideView: View {
    /// Overlay que muestra las guías de calibración
    struct CalibrationOverlay: View {
        /// Tamaño del área objetivo para la tarjeta
        let targetSize: CGSize
        /// Opacidad del overlay
        let overlayOpacity: Double
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Guías de alineación
                    VStack(spacing: 0) {
                        // Guía horizontal superior
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: targetSize.width + 40, height: 1)
                            .offset(y: -targetSize.height/2)
                        
                        // Guía horizontal inferior
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: targetSize.width + 40, height: 1)
                            .offset(y: targetSize.height/2)
                    }
                    
                    HStack(spacing: 0) {
                        // Guía vertical izquierda
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1, height: targetSize.height + 40)
                            .offset(x: -targetSize.width/2)
                        
                        // Guía vertical derecha
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1, height: targetSize.height + 40)
                            .offset(x: targetSize.width/2)
                    }
                    
                    // Esquinas
                    ForEach([
                        CGPoint(x: -1, y: -1), // Superior izquierda
                        CGPoint(x: 1, y: -1),  // Superior derecha
                        CGPoint(x: -1, y: 1),  // Inferior izquierda
                        CGPoint(x: 1, y: 1)    // Inferior derecha
                    ], id: \.x) { point in
                        CornerGuide()
                            .position(
                                x: geometry.size.width/2 + point.x * targetSize.width/2,
                                y: geometry.size.height/2 + point.y * targetSize.height/2
                            )
                    }
                    
                    // Texto de instrucciones
                    VStack {
                        Text(NSLocalizedString("calibration.guide.align", comment: "Instruction to align the calibration card"))
                            .foregroundColor(.white)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.4))
                                    .blur(radius: 3)
                            )
                            .padding(.top, geometry.size.height * 0.1)
                        Spacer()
                    }
                }
                .compositingGroup()
            }
        }
    }
    
    /// Vista para las esquinas guía
    struct CornerGuide: View {
        var body: some View {
            ZStack {
                // Línea horizontal
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 2)
                
                // Línea vertical
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 20)
            }
        }
    }
    
    /// Tamaño objetivo para la tarjeta de calibración
    let targetSize: CGSize
    /// Opacidad del overlay
    let overlayOpacity: Double
    
    init(targetSize: CGSize = CGSize(width: 280, height: 180), overlayOpacity: Double = 0.5) {
        self.targetSize = targetSize
        self.overlayOpacity = overlayOpacity
    }
    
    var body: some View {
        CalibrationOverlay(targetSize: targetSize, overlayOpacity: overlayOpacity)
            .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.blue // Fondo para simular la cámara
        CalibrationGuideView()
    }
}
