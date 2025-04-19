import SwiftUI
import PDFKit

/// Vista para el proceso de calibración de la cámara.
///
/// Esta vista permite al usuario:
/// - Ver instrucciones para la calibración
/// - Capturar una imagen de la tarjeta de calibración
/// - Ver el estado de la calibración
/// - Reiniciar la calibración si es necesario
/// - Descargar la tarjeta de calibración
struct CalibrationView: View {
    /// Servicio de calibración
    @StateObject private var calibrationService = CalibrationService()
    
    /// Servicio de cámara
    @StateObject private var cameraService = CameraService()
    
    /// Servicio de tarjeta de calibración
    private let cardService = CalibrationCardService()
    
    /// Enum para controlar qué sheet se muestra
    private enum SheetType: Identifiable {
        case camera
        case imagePicker
        case share(UIImage)
        
        var id: Int {
            switch self {
            case .camera: return 1
            case .imagePicker: return 2
            case .share: return 3
            }
        }
    }
    
    /// Estado actual del sheet
    @State private var activeSheet: SheetType?
    
    /// Imagen seleccionada para calibración
    @State private var selectedImage: UIImage?
    
    /// Indica si se debe mostrar un mensaje de error
    @State private var showError = false
    
    /// Mensaje de error
    @State private var errorMessage = ""
    
    /// Indica si se debe mostrar un mensaje de éxito
    @State private var showSuccess = false
    
    /// Callback para cuando se completa la calibración
    var onCalibrationComplete: (() -> Void)?
    
    init(onCalibrationComplete: (() -> Void)? = nil) {
        // Cargar factores de calibración al inicio
        _calibrationService = StateObject(wrappedValue: CalibrationService())
        self.onCalibrationComplete = onCalibrationComplete
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Estado de calibración
                CalibrationStatusView(state: calibrationService.calibrationState)
                
                // Imagen capturada
                if let image = selectedImage {
                    CapturedImageView(image: image)
                }
                
                // Botones de acción
                ActionButtonsView(
                    onCameraTap: { activeSheet = .camera },
                    onGalleryTap: { activeSheet = .imagePicker }
                )
                
                // Información de calibración
                CalibrationInfoView()
                
                // Alternativa para aficionados
                BasicCalibrationCardView(
                    onDownloadTap: {
                        if let image = cardService.generateCalibrationCard() {
                            activeSheet = .share(image)
                        } else {
                            errorMessage = "Error al generar la tarjeta de calibración"
                            showError = true
                        }
                    }
                )
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Cerrar") {
            onCalibrationComplete?()
        })
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .camera:
                CameraCaptureView(
                    capturedImage: $selectedImage,
                    resolution: .high,
                    showGuide: true
                )
            case .imagePicker:
                ImagePicker(image: $selectedImage)
            case .share(let image):
                ActivityViewController(activityItems: [image])
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Calibración Exitosa", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                onCalibrationComplete?()
            }
        } message: {
            Text("La cámara ha sido calibrada correctamente.")
        }

        .onChange(of: selectedImage) { oldImage, newImage in
            if let image = newImage {
                processCalibrationImage(image)
            }
        }
    }
    
    /// Procesa la imagen de calibración
    /// - Parameter image: Imagen capturada o seleccionada
    private func processCalibrationImage(_ image: UIImage) {
        // Mostrar indicador de progreso
        calibrationService.startCalibration()
        
        // Procesar la imagen
        calibrationService.processCalibrationImage(image)
        
        // Manejar el resultado
        switch calibrationService.calibrationState {
        case .calibrated:
            showSuccess = true
            // Mostrar los factores de calibración en la consola para debug
            print("Calibración exitosa. Factores: R=\(calibrationService.correctionFactors.red), G=\(calibrationService.correctionFactors.green), B=\(calibrationService.correctionFactors.blue)")
        case .error(let message):
            errorMessage = message
            showError = true
        case .calibrating:
            // Esperar a que termine la calibración
            break
        case .notCalibrated:
            errorMessage = "La calibración no se completó correctamente"
            showError = true
        }
    }
}

// MARK: - Vistas de Componentes

/// Vista que muestra el estado actual de la calibración
struct CalibrationStatusView: View {
    let state: CalibrationService.CalibrationState
    
    var body: some View {
        Group {
            switch state {
            case .notCalibrated:
                Text("No calibrado")
                    .foregroundColor(.red)
            case .calibrating:
                HStack {
                    ProgressView()
                    Text("Calibrando...")
                }
            case .calibrated:
                Text("Calibrado")
                    .foregroundColor(.green)
            case .error(let message):
                Text("Error: \(message)")
                    .foregroundColor(.red)
            }
        }
        .font(.headline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

/// Vista que muestra la imagen capturada
struct CapturedImageView: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .cornerRadius(10)
    }
}

/// Vista con los botones de acción
struct ActionButtonsView: View {
    let onCameraTap: () -> Void
    let onGalleryTap: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onCameraTap) {
                Label("Tomar Foto", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: onGalleryTap) {
                Label("Seleccionar", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
}

/// Vista con la información de calibración
struct CalibrationInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tarjeta de Calibración")
                .font(.headline)
            
            Text("Se recomienda usar el X-Rite ColorChecker Classic con 24 parches para obtener resultados precisos.")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Características:")
                    .font(.subheadline)
                    .bold()
                
                Text("• Colores certificados y estables")
                Text("• Resistente a UV")
                Text("• 24 parches de color específicos")
                Text("• Valores de referencia sRGB precisos")
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

/// Vista para la tarjeta de calibración básica
struct BasicCalibrationCardView: View {
    let onDownloadTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alternativa para Aficionados")
                .font(.headline)
            
            Text("Si no tienes acceso a una tarjeta profesional, puedes usar nuestra tarjeta básica de calibración.")
                .font(.subheadline)
            
            Button(action: onDownloadTap) {
                Label("Descargar Tarjeta Básica", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Text("Nota: La tarjeta básica proporciona una calibración aproximada. Para resultados profesionales, se recomienda usar el ColorChecker certificado.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Vistas Auxiliares

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
