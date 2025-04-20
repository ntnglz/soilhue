import SwiftUI
import AVFoundation

/// Vista para la captura de imágenes con la cámara
struct CameraCaptureView: View {
    /// Imagen capturada
    @Binding var capturedImage: UIImage?
    
    /// Resolución de la cámara
    let resolution: CameraResolution
    
    /// Si se debe mostrar la guía de calibración
    let showGuide: Bool
    
    /// Environment para cerrar la vista
    @Environment(\.dismiss) private var dismiss
    
    /// Servicio de cámara
    @StateObject private var cameraService = CameraService()
    
    /// Estado de la previsualización
    @State private var previewImage: UIImage?
    
    /// Estado de error
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Vista de la cámara
            if let preview = previewImage {
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            }
            
            // Guía de calibración
            if showGuide {
                CalibrationGuideView()
            }
            
            // Controles de la cámara
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Botón de captura
                    Button {
                        captureImage()
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 2)
                                    .frame(width: 65, height: 65)
                            )
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            do {
                for try await image in try await cameraService.startSession() {
                    previewImage = image
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    /// Configura la cámara
    private func setupCamera() {
        Task {
            do {
                try await cameraService.setup(resolution: resolution)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    /// Captura una imagen
    private func captureImage() {
        Task {
            do {
                let image = try await cameraService.capturePhoto()
                await MainActor.run {
                    capturedImage = image
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    CameraCaptureView(
        capturedImage: .constant(nil),
        resolution: .high,
        showGuide: true
    )
}
