//
//  CameraService.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import SwiftUI
import AVFoundation
import UIKit

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
class CameraService: NSObject, ObservableObject {
    /// Errores específicos que pueden ocurrir durante la operación de la cámara.
    enum CameraError: LocalizedError {
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
        /// La resolución seleccionada no está soportada por este dispositivo.
        case resolutionNotSupported
        /// No se pudo configurar la resolución deseada.
        case invalidResolution
        /// No hay permiso para acceder a la cámara.
        case noPermission
        /// Error al configurar la cámara.
        case setupFailed
        
        var errorDescription: String? {
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
            case .resolutionNotSupported:
                return "La resolución seleccionada no está soportada por este dispositivo."
            case .invalidResolution:
                return "No se pudo configurar la resolución deseada."
            case .noPermission:
                return "No hay permiso para acceder a la cámara."
            case .setupFailed:
                return "Error al configurar la cámara."
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
    
    /// Configura la resolución de la cámara según los ajustes
    private func configureResolution(_ resolution: CameraResolution) throws {
        guard (deviceInput?.device) != nil else {
            throw CameraError.invalidDevice
        }
        
        let preset: AVCaptureSession.Preset
        switch resolution {
        case .low:
            preset = .vga640x480
        case .medium:
            preset = .hd1280x720
        case .high:
            preset = .hd1920x1080
        default:
            throw CameraError.resolutionNotSupported
        }
        
        guard session.canSetSessionPreset(preset) else {
            throw CameraError.resolutionNotSupported
        }
        
        session.sessionPreset = preset
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
    
    /// Configura la sesión de la cámara con los ajustes especificados
    ///
    /// Este método:
    /// 1. Verifica los permisos
    /// 2. Configura el dispositivo de entrada (cámara trasera)
    /// 3. Configura la salida de fotos
    /// 4. Configura la capa de previsualización
    ///
    /// - Throws: `CameraError` si hay algún problema durante la configuración
    func setup(resolution: CameraResolution) async throws {
        // Verificar permisos primero
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                throw CameraError.noPermission
            }
        } else if status != .authorized {
            throw CameraError.noPermission
        }
        
        // Configurar la sesión
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Limpiar configuración previa
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Configurar dispositivo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.invalidDevice
        }
        self.deviceInput = try? AVCaptureDeviceInput(device: device)
        guard session.canAddInput(self.deviceInput!) else {
            throw CameraError.setupFailed
        }
        session.addInput(self.deviceInput!)
        
        // Configurar salida
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.setupFailed
        }
        session.addOutput(photoOutput)
        
        // Configurar resolución
        do {
            try configureResolution(resolution)
        } catch {
            print("Error al configurar resolución \(resolution): \(error). Usando calidad .photo")
            session.sessionPreset = .photo
        }
        
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
    }
    
    /// Inicia la sesión de la cámara.
    ///
    /// Este método se ejecuta en un hilo en segundo plano para evitar
    /// problemas de rendimiento en la UI.
    func start() {
        guard !session.isRunning else { return }
        Task.detached {
            await MainActor.run {
                // Notificar que vamos a iniciar
                self.isRunning = true
            }
            // Ejecutar startRunning en el hilo en segundo plano
            await self.session.startRunning()
        }
    }
    
    /// Detiene la sesión de la cámara.
    ///
    /// Este método se ejecuta en un hilo en segundo plano para evitar
    /// problemas de rendimiento en la UI.
    func stop() {
        guard session.isRunning else { return }
        Task.detached {
            // Ejecutar stopRunning en el hilo en segundo plano
            await       self.session.stopRunning()
            await MainActor.run {
                // Notificar que hemos detenido
                self.isRunning = false
            }
        }
    }
    
    /// Clase auxiliar para manejar la captura de fotos.
    private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
        private let completion: (Result<UIImage, CameraError>) -> Void
        
        init(completion: @escaping (Result<UIImage, CameraError>) -> Void) {
            self.completion = completion
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if  error != nil {
                completion(.failure(.captureError))
                return
            }
            
            guard let data = photo.fileDataRepresentation(),
                  let image = UIImage(data: data) else {
                completion(.failure(.captureError))
                return
            }
            
            completion(.success(image))
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
            
            let delegate = PhotoCaptureDelegate { result in
                switch result {
                case .success(let image):
                    continuation.resume(returning: image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // Retener el delegate hasta que se complete la captura
            objc_setAssociatedObject(photoOutput, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}
