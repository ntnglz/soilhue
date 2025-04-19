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
        /// La sesión de la cámara no está activa.
        case sessionNotRunning
        
        var localizedDescription: String {
            switch self {
            case .permissionDenied:
                return "No hay acceso a la cámara. Por favor, verifica los permisos en Ajustes."
            case .captureError:
                return "Error al capturar la foto."
            case .invalidDevice:
                return "No se pudo acceder a la cámara del dispositivo."
            case .configurationError:
                return "Error al configurar la cámara."
            case .sessionNotRunning:
                return "La sesión de la cámara no está activa."
            }
        }
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
    var previewLayer: AVCaptureVideoPreviewLayer {
        if _previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            _previewLayer = layer
        }
        return _previewLayer!
    }
    
    /// Verifica y solicita los permisos de acceso a la cámara.
    ///
    /// - Returns: `true` si se concedieron los permisos, `false` en caso contrario.
    func checkPermissions() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            error = .permissionDenied
            return false
        @unknown default:
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
        
        // Asegurarse de que la sesión no está corriendo
        if session.isRunning {
            session.stopRunning()
        }
        
        // Limpiar configuración previa
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Configurar calidad
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // Configurar entrada
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
            throw CameraError.invalidDevice
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            guard session.canAddInput(videoDeviceInput) else {
                throw CameraError.configurationError
            }
            session.addInput(videoDeviceInput)
            deviceInput = videoDeviceInput
        } catch {
            throw CameraError.configurationError
        }
        
        // Configurar salida
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.configurationError
        }
        session.addOutput(photoOutput)
        
        // Configurar orientación
        if let connection = photoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(0) {
                    connection.videoRotationAngle = 0
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }
        
        session.commitConfiguration()
    }
    
    /// Inicia la sesión de la cámara.
    ///
    /// Este método se ejecuta en un hilo en segundo plano para evitar
    /// problemas de rendimiento en la UI.
    func start() {
        guard !session.isRunning else { return }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.session.startRunning()
            await MainActor.run { [weak self] in
                self?.isRunning = true
            }
        }
    }
    
    /// Detiene la sesión de la cámara.
    ///
    /// Este método se ejecuta en un hilo en segundo plano para evitar
    /// problemas de rendimiento en la UI.
    func stop() {
        guard session.isRunning else { return }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.session.stopRunning()
            await MainActor.run { [weak self] in
                self?.isRunning = false
            }
        }
    }
    
    /// Clase auxiliar para manejar la captura de fotos.
    private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
        private let onCapture: (UIImage) -> Void
        private let onError: (Error) -> Void
        
        init(onCapture: @escaping (UIImage) -> Void, onError: @escaping (Error) -> Void) {
            self.onCapture = onCapture
            self.onError = onError
            super.init()
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            // Limpiar el delegate asociado
            objc_setAssociatedObject(output, "delegate", nil, .OBJC_ASSOCIATION_RETAIN)
            
            if let error = error {
                onError(error)
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                onError(CameraError.captureError)
                return
            }
            
            onCapture(image)
        }
    }
    
    /// Captura una foto usando la cámara.
    ///
    /// - Returns: Una imagen capturada por la cámara
    /// - Throws: `CameraError.captureError` si hay un problema durante la captura
    func capturePhoto() async throws -> UIImage {
        guard session.isRunning else {
            throw CameraError.sessionNotRunning
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            
            let delegate = PhotoCaptureDelegate { image in
                continuation.resume(returning: image)
            } onError: { error in
                continuation.resume(throwing: error)
            }
            
            // Retener el delegate hasta que se complete la captura
            objc_setAssociatedObject(photoOutput, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}
