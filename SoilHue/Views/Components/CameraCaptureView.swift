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
    
    /// Estado de la cámara
    @State private var isCameraReady = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    /// Entorno
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Vista previa de la cámara
            CameraPreviewView(cameraService: cameraService)
                .ignoresSafeArea()
            
            // Botones de control
            VStack {
                Spacer()
                
                HStack {
                    // Botón de cancelar
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Botón de captura
                    Button {
                        Task {
                            do {
                                capturedImage = try await cameraService.capturePhoto()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 80, height: 80)
                            )
                    }
                    
                    Spacer()
                    
                    // Botón de cambiar cámara
                    Button {
                        // TODO: Implementar cambio de cámara
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
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
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            cameraService.stop()
        }
    }
}
