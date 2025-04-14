import SwiftUI

/// Vista para el proceso de calibración de la cámara.
///
/// Esta vista permite al usuario:
/// - Ver instrucciones para la calibración
/// - Capturar una imagen de la tarjeta de calibración
/// - Ver el estado de la calibración
/// - Reiniciar la calibración si es necesario
struct CalibrationView: View {
    /// Servicio de calibración
    @StateObject private var calibrationService = CalibrationService()
    
    /// Servicio de cámara
    @StateObject private var cameraService = CameraService()
    
    /// Indica si la cámara está activa
    @State private var isCameraActive = false
    
    /// Indica si se debe mostrar el selector de imágenes
    @State private var showImagePicker = false
    
    /// Imagen seleccionada para calibración
    @State private var selectedImage: UIImage?
    
    /// Indica si se debe mostrar la vista de resultados
    @State private var showResults = false
    
    /// Indica si se debe mostrar un mensaje de error
    @State private var showError = false
    
    /// Mensaje de error
    @State private var errorMessage = ""
    
    /// Indica si se debe mostrar un mensaje de éxito
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Título y descripción
                VStack(spacing: 10) {
                    Text("Calibración de la Cámara")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Para obtener resultados precisos, calibra la cámara usando una tarjeta de referencia de color.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Estado de calibración
                VStack(spacing: 5) {
                    Text("Estado de Calibración:")
                        .font(.headline)
                    
                    switch calibrationService.calibrationState {
                    case .notCalibrated:
                        Text("No calibrado")
                            .foregroundColor(.red)
                    case .calibrating:
                        Text("Calibrando...")
                            .foregroundColor(.orange)
                    case .calibrated:
                        Text("Calibrado")
                            .foregroundColor(.green)
                    case .error(let message):
                        Text("Error: \(message)")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                // Instrucciones
                VStack(alignment: .leading, spacing: 10) {
                    Text("Instrucciones:")
                        .font(.headline)
                    
                    Text("1. Coloca la tarjeta de calibración en una superficie plana.")
                    Text("2. Asegúrate de que la iluminación sea uniforme.")
                    Text("3. Captura una foto de la tarjeta completa.")
                    Text("4. Verifica que todos los colores sean visibles.")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                // Imagen de referencia
                Image("calibration_card")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                
                // Botones de acción
                HStack(spacing: 20) {
                    Button(action: {
                        isCameraActive = true
                    }) {
                        VStack {
                            Image(systemName: "camera")
                                .font(.system(size: 30))
                            Text("Tomar Foto")
                                .font(.caption)
                        }
                        .frame(width: 100, height: 80)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        VStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 30))
                            Text("Seleccionar")
                                .font(.caption)
                        }
                        .frame(width: 100, height: 80)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                // Botón para reiniciar calibración
                if calibrationService.calibrationState == .calibrated {
                    Button(action: {
                        calibrationService.resetCalibration()
                    }) {
                        Text("Reiniciar Calibración")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Calibración", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cerrar") {
                // Cerrar la vista
            })
            .sheet(isPresented: $isCameraActive) {
                CameraCaptureView(capturedImage: $selectedImage)
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage {
                            processCalibrationImage(image)
                        }
                    }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage {
                            processCalibrationImage(image)
                        }
                    }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showSuccess) {
                Alert(
                    title: Text("Calibración Exitosa"),
                    message: Text("La cámara ha sido calibrada correctamente."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                calibrationService.loadCalibrationFactors()
            }
        }
    }
    
    /// Procesa la imagen de calibración
    /// - Parameter image: Imagen capturada o seleccionada
    private func processCalibrationImage(_ image: UIImage) {
        calibrationService.startCalibration()
        
        // Procesar la imagen de calibración
        calibrationService.processCalibrationImage(image)
        
        // Verificar el resultado
        switch calibrationService.calibrationState {
        case .calibrated:
            showSuccess = true
        case .error(let message):
            errorMessage = message
            showError = true
        default:
            break
        }
    }
}
