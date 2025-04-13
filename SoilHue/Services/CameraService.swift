//
//  CameraService.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import SwiftUI
import AVFoundation

/// Servicio que maneja la funcionalidad de la cámara del dispositivo.
///
/// Este servicio proporciona una interfaz para:
/// - Gestionar permisos de la cámara
/// - Configurar y controlar la sesión de captura
/// - Capturar fotos
/// - Proporcionar una vista previa de la cámara
///
/// El servicio está diseñado para ser usado como un `ObservableObject` en SwiftUI,
/// permitiendo a las vistas reaccionar a cambios en el estado de la cámara.
@MainActor
class CameraService: ObservableObject {
    /// Errores específicos que pueden ocurrir durante la operación de la cámara.
    enum CameraError: Error {
        /// El usuario ha denegado los permisos de acceso a la cámara.
        case permissionDenied
        /// Ocurrió un error durante la captura de la foto.
        case captureError
        /// No se pudo acceder al dispositivo de la cámara.
        case invalidDevice
        /// Error durante la configuración de la sesión de captura.
        case configurationError
    }
    
    /// El error actual, si existe.
    @Published var error: CameraError?
    
    /// Indica si la sesión de la cámara está activa.
    @Published var isRunning = false
    
    /// Sesión de captura de AVFoundation.
    private let session = AVCaptureSession()
    
    /// Dispositivo de entrada de la cámara.
    private var deviceInput: AVCaptureDeviceInput?
    
    /// Salida para capturar fotos.
    private let photoOutput = AVCapturePhotoOutput()
    
    /// Capa de previsualización de la cámara.
    private var _previewLayer: AVCaptureVideoPreviewLayer?
    
    /// Capa de previsualización accesible públicamente.
    var previewLayer: AVCaptureVideoPreviewLayer? {
        return _previewLayer
    }
    
    /// Verifica y solicita los permisos de acceso a la cámara.
    ///
    /// - Returns: `true` si se concedieron los permisos, `false` en caso contrario.
    func checkPermissions() async -> Bool {
        switch await AVCaptureDevice.requestAccess(for: .video) {
        case true:
            return true
        case false:
            error = .permissionDenied
            return false
        }
    }
    
    /// Configura la sesión de la cámara con los ajustes necesarios.
    ///
    /// Este método:
    /// 1. Verifica los permisos
    /// 2. Configura el dispositivo de entrada (cámara trasera)
    /// 3. Configura la salida de fotos
    /// 4. Configura la capa de previsualización
    ///
    /// - Throws: `CameraError` si hay algún problema durante la configuración
    func setup() async throws {
        guard await checkPermissions() else {
            throw CameraError.permissionDenied
        }
        
        session.beginConfiguration()
        
        // Configurar la calidad de la sesión
        session.sessionPreset = .photo
        
        // Configurar el dispositivo de entrada
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
            throw CameraError.invalidDevice
        }
        
        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        
        guard session.canAddInput(videoDeviceInput) else {
            throw CameraError.configurationError
        }
        
        session.addInput(videoDeviceInput)
        deviceInput = videoDeviceInput
        
        // Configurar la salida de fotos
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.configurationError
        }
        
        session.addOutput(photoOutput)
        
        // Configurar la capa de previsualización
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        _previewLayer = previewLayer
        
        session.commitConfiguration()
    }
    
    /// Inicia la sesión de la cámara.
    ///
    /// Este método se ejecuta en un hilo en segundo plano para no bloquear la UI.
    func start() {
        guard !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
            }
        }
    }
    
    /// Detiene la sesión de la cámara.
    ///
    /// Este método se ejecuta en un hilo en segundo plano para no bloquear la UI.
    func stop() {
        guard session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
            }
        }
    }
    
    /// Captura una foto usando la cámara.
    ///
    /// - Returns: Una imagen capturada por la cámara
    /// - Throws: `CameraError.captureError` si hay un problema durante la captura
    func capturePhoto() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            
            photoOutput.capturePhoto(with: settings) { [weak self] photoData, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let photoData = photoData,
                      let image = UIImage(data: photoData) else {
                    continuation.resume(throwing: CameraError.captureError)
                    return
                }
                
                continuation.resume(returning: image)
            }
        }
    }
}
