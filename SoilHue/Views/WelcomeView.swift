import SwiftUI
import PhotosUI

struct WelcomeView: View {
    @Binding var isCameraActive: Bool
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var showCalibration: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo y título
            VStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("SoilHue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Análisis de Color de Suelos")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Botones de acción
            VStack(spacing: 16) {
                Button(action: {
                    isCameraActive = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Tomar Foto")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                PhotosPicker(selection: $selectedItem,
                           matching: .images) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Seleccionar Foto")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showCalibration = true
                }) {
                    HStack {
                        Image(systemName: "camera.metering.center.weighted")
                        Text("Calibrar Cámara")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Texto informativo
            VStack(spacing: 8) {
                Text("Para obtener mejores resultados:")
                    .font(.headline)
                
                Text("• Calibra la cámara antes de empezar\n• Toma las fotos con buena iluminación\n• Mantén la cámara estable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}

#Preview {
    WelcomeView(
        isCameraActive: .constant(false),
        selectedItem: .constant(nil),
        showCalibration: .constant(false)
    )
} 