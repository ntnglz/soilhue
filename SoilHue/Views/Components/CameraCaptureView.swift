import SwiftUI
import AVFoundation

/// Vista para capturar fotos usando la cámara del dispositivo.
///
/// Esta vista proporciona una interfaz para:
/// - Mostrar la vista previa de la cámara en tiempo real
/// - Capturar fotos
/// - Cancelar la captura
/// - Cambiar entre cámaras (frontal/trasera)
///
/// La vista utiliza `CameraService` para manejar la funcionalidad de la cámara
/// y `CameraPreviewView` para mostrar la previsualización.
struct CameraCaptureView: View {
    /// Servicio de la cámara
    @StateObject private var cameraService = CameraService()
    
    /// Imagen capturada
    @Binding var capturedImage: UIImage?
    
    /// Resolución de la cámara
    let resolution: CameraResolution
    
    /// Estado de la cámara
    @State private var isCameraReady = false
    @State private var error: Error?
    
    /// Entorno
    @Environment(\.dismiss) private var dismiss
    
    /// Show guide
    let showGuide: Bool
    
    var body: some View {
        ZStack {
            // Vista previa de la cámara
            if isCameraReady {
                CameraPreviewView(cameraService: cameraService)
                    .ignoresSafeArea()
                    .overlay {
                        if showGuide {
                            CameraGuideView()
                        }
                    }
            } else {
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
            }
            
            // Botón de captura
            VStack {
                Spacer()
                Button(action: capturePhoto) {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 8)
                }
                .padding(.bottom, 40)
            }
        }
        .task {
            do {
                try await cameraService.setup(resolution: resolution)
                try await Task.sleep(nanoseconds: 500_000_000)
                cameraService.start()
                isCameraReady = true
            } catch {
                self.error = error
            }
        }
        .alert("Error", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK") { error = nil }
        } message: {
            if let cameraError = error as? CameraService.CameraError {
                Text(cameraError.localizedDescription)
            } else {
                Text(error?.localizedDescription ?? "Error desconocido")
            }
        }
        .onDisappear {
            cameraService.stop()
        }
    }
    
    private func capturePhoto() {
        Task {
            do {
                capturedImage = try await cameraService.capturePhoto()
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    CameraCaptureView(
        capturedImage: .constant(nil),
        resolution: .high,
        showGuide: false
    )
}
