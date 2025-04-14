import SwiftUI
import AVFoundation

/// Vista que muestra la previsualización de la cámara en tiempo real.
///
/// Esta vista utiliza `UIViewRepresentable` para mostrar la capa de previsualización
/// de AVFoundation en SwiftUI. Se integra con `CameraService` para mostrar
/// la vista previa de la cámara y capturar fotos.
struct CameraPreviewView: UIViewRepresentable {
    /// El servicio de cámara que proporciona la previsualización.
    let cameraService: CameraService
    
    /// Crea la vista de UIKit que mostrará la previsualización.
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.backgroundColor = .black
        
        let previewLayer = cameraService.previewLayer
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        // Asegurarse de que la capa de previsualización está en el hilo principal
        DispatchQueue.main.async {
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    /// Actualiza la vista cuando cambian las propiedades.
    func updateUIView(_ uiView: UIView, context: Context) {
        // Asegurarse de que la actualización se realiza en el hilo principal
        DispatchQueue.main.async {
            cameraService.previewLayer.frame = uiView.bounds
        }
    }
}

/// Vista que integra la previsualización de la cámara con controles de captura.
struct CameraView: View {
    /// El servicio de cámara que maneja la captura.
    @StateObject private var cameraService = CameraService()
    
    /// Indica si la cámara está lista para usar.
    @State private var isCameraReady = false
    
    /// Indica si se muestra un mensaje de error.
    @State private var showError = false
    
    /// Mensaje de error a mostrar.
    @State private var errorMessage = ""
    
    /// Callback que se ejecuta cuando se captura una imagen.
    var onImageCaptured: ((UIImage) -> Void)?
    
    /// Entorno que proporciona acceso a funciones de presentación.
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if isCameraReady {
                    GeometryReader { geometry in
                        CameraPreviewView(cameraService: cameraService)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: capturePhoto) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                                        )
                                }
                                Spacer()
                            }
                            .padding(.bottom, 30)
                        }
                    )
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .task {
            do {
                try await cameraService.setup()
                // Pequeña pausa para asegurar que la cámara está lista
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 segundos
                cameraService.start()
                isCameraReady = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .onDisappear {
            cameraService.stop()
        }
    }
    
    /// Captura una foto usando la cámara.
    private func capturePhoto() {
        Task {
            do {
                let image = try await cameraService.capturePhoto()
                onImageCaptured?(image)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    CameraView()
} 