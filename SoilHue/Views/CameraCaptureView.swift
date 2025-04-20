import SwiftUI
import AVFoundation
import CoreLocation

/// Vista para la captura de imágenes con la cámara
struct CameraCaptureView: View {
    /// Imagen capturada
    @Binding var capturedImage: UIImage?
    
    /// Localización capturada
    @Binding var capturedLocation: CLLocation?
    
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
    
    @StateObject private var locationService = LocationService()
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isCapturing = false
    @State private var previewStream: AsyncStream<UIImage>?
    @State private var isLocationEnabled = false
    
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
                // Indicador de localización
                HStack(spacing: 8) {
                    Image(systemName: isLocationEnabled ? "location.fill" : "location.slash.fill")
                        .foregroundColor(isLocationEnabled ? .green : .red)
                    Text(isLocationEnabled ? 
                         NSLocalizedString("location.status.enabled", comment: "Location enabled status") :
                         NSLocalizedString("location.status.disabled", comment: "Location disabled status"))
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(.black.opacity(0.6))
                .cornerRadius(8)
                .padding(.top, 44)
                
                Spacer()
                
                // Botón de captura
                Button {
                    Task {
                        await capturePhoto()
                    }
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(.black.opacity(0.8), lineWidth: 2)
                        )
                        .shadow(radius: 4)
                }
                .disabled(isCapturing)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if isCapturing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .task {
            do {
                try await setupCamera()
                locationService.requestAuthorization()
                updateLocationStatus()
            } catch {
                showAlert(
                    title: NSLocalizedString("alert.error.title", comment: "Error alert title"),
                    message: error.localizedDescription
                )
            }
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button(NSLocalizedString("button.ok", comment: "OK button"), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .modifier(LocationStatusChangeModifier(locationService: locationService, updateStatus: updateLocationStatus))
    }
    
    private func updateLocationStatus() {
        isLocationEnabled = locationService.authorizationStatus == .authorizedWhenInUse || 
                          locationService.authorizationStatus == .authorizedAlways
    }
    
    /// Configura la cámara
    private func setupCamera() async throws {
        // Configurar la cámara
        try await cameraService.setup(resolution: resolution)
        
        // Iniciar la sesión y obtener el stream de previsualización
        let stream = try await cameraService.startSession()
        
        // Actualizar la UI con las imágenes del stream
        for await image in stream {
            await MainActor.run {
                previewImage = image
            }
        }
    }
    
    private func capturePhoto() async {
        isCapturing = true
        do {
            let location = try await locationService.getCurrentLocation()
            let image = try await cameraService.capturePhoto(location: location)
            await MainActor.run {
                capturedImage = image
                capturedLocation = location
                isCapturing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                showAlert(
                    title: NSLocalizedString("alert.error.title", comment: "Error alert title"),
                    message: error.localizedDescription
                )
                isCapturing = false
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // Modifier para manejar los cambios de estado de localización
    private struct LocationStatusChangeModifier: ViewModifier {
        let locationService: LocationService
        let updateStatus: () -> Void
        
        func body(content: Content) -> some View {
            if #available(iOS 17.0, *) {
                content.onChange(of: locationService.authorizationStatus) { _, _ in
                    updateStatus()
                }
            } else {
                content.onChange(of: locationService.authorizationStatus) { _ in
                    updateStatus()
                }
            }
        }
    }
}

#Preview {
    CameraCaptureView(
        capturedImage: .constant(nil),
        capturedLocation: .constant(nil),
        resolution: .high,
        showGuide: true
    )
}
