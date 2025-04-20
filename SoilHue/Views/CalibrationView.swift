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
                            errorMessage = NSLocalizedString("calibration.error.generic", comment: "Error generating calibration card")
                            showError = true
                        }
                    }
                )
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(NSLocalizedString("button.close", comment: "Close button")) {
            onCalibrationComplete?()
        })
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .camera:
                CameraCaptureView(
                    capturedImage: $selectedImage,
                    capturedLocation: .constant(nil),
                    resolution: .high,
                    showGuide: true
                )
            case .imagePicker:
                ImagePicker(image: $selectedImage)
            case .share(let image):
                ActivityViewController(activityItems: [image])
            }
        }
        .alert(NSLocalizedString("alert.error.title", comment: "Error alert title"), isPresented: $showError) {
            Button(NSLocalizedString("button.ok", comment: "OK button"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(NSLocalizedString("calibration.success.title", comment: "Calibration success title"), isPresented: $showSuccess) {
            Button(NSLocalizedString("button.ok", comment: "OK button"), role: .cancel) {
                onCalibrationComplete?()
            }
        } message: {
            Text(NSLocalizedString("calibration.success.message", comment: "Calibration success message"))
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
            errorMessage = NSLocalizedString("calibration.error.generic", comment: "Error generating calibration card")
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
                Text(NSLocalizedString("calibration.status.notCalibrated", comment: "Not calibrated status"))
                    .foregroundColor(.red)
            case .calibrating:
                HStack {
                    ProgressView()
                    Text(NSLocalizedString("calibration.status.calibrating", comment: "Calibrating status"))
                }
            case .calibrated:
                Text(NSLocalizedString("calibration.status.calibrated", comment: "Calibrated status"))
                    .foregroundColor(.green)
            case .error(let message):
                Text(String(format: NSLocalizedString("calibration.status.error", comment: "Error status with message"), message))
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
                Label(NSLocalizedString("calibration.button.takePhoto", comment: "Take photo button"), systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: onGalleryTap) {
                Label(NSLocalizedString("calibration.button.selectPhoto", comment: "Select photo button"), systemImage: "photo.on.rectangle")
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
            Text(NSLocalizedString("calibration.info.title", comment: "Calibration card info title"))
                .font(.headline)
            
            Text(NSLocalizedString("calibration.info.description", comment: "Calibration card description"))
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("calibration.info.features.title", comment: "Features title"))
                    .font(.subheadline)
                    .bold()
                
                Text(NSLocalizedString("calibration.info.features.certified", comment: "Certified colors feature"))
                Text(NSLocalizedString("calibration.info.features.resistant", comment: "UV resistant feature"))
                Text(NSLocalizedString("calibration.info.features.patches", comment: "Color patches feature"))
                Text(NSLocalizedString("calibration.info.features.values", comment: "sRGB values feature"))
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
            Text(NSLocalizedString("calibration.alternative.title", comment: "Alternative card title"))
                .font(.headline)
            
            Text(NSLocalizedString("calibration.alternative.description", comment: "Alternative card description"))
                .font(.subheadline)
            
            Button(action: onDownloadTap) {
                Label(NSLocalizedString("calibration.alternative.download", comment: "Download basic card button"), systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Text(NSLocalizedString("calibration.alternative.note", comment: "Alternative card note"))
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
