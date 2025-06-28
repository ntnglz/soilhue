import SwiftUI

struct ImageSelectionView: View {
    @Binding var isCameraActive: Bool
    @Binding var showImagePicker: Bool
    @Binding var showCalibration: Bool
    @State private var showHelp = false
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo y título
            VStack(spacing: 15) {
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                
                Text("SoilHue")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Análisis de Color del Suelo")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 44) // Altura del NavigationBar
            
            // Descripción
            Text("Captura o selecciona una imagen de una muestra de suelo para analizar su color utilizando el sistema Munsell.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)
                .padding(.top, 30)
            
            // Características principales
            HStack(spacing: 25) {
                FeatureItem(icon: "camera.viewfinder", title: "Captura\nPrecisa")
                FeatureItem(icon: "eyedropper.halffull", title: "Análisis\nMunsell")
                FeatureItem(icon: "square.stack.3d.up", title: "Clasificación\nde Suelos")
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            
            Spacer(minLength: 40)
            
            // Botones de acción
            VStack(spacing: 15) {
                Button(action: { isCameraActive = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Tomar Foto")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(radius: 2)
                }
                
                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)
                        Text("Seleccionar Imagen")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                
                // Botón de calibración
                Button(action: { showCalibration = true }) {
                    HStack {
                        Image(systemName: "camera.aperture")
                        Text("Calibrar Cámara")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal, 30)
            
            // Botón de ayuda
            Button(action: { showHelp = true }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Ayuda")
                }
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
    }
}

#Preview {
    ImageSelectionView(
        isCameraActive: .constant(false),
        showImagePicker: .constant(false),
        showCalibration: .constant(false),
        onImageSelected: { _ in }
    )
} 
