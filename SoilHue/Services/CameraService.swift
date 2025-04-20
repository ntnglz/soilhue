//
//  CameraService.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import SwiftUI
import AVFoundation
import UIKit
import CoreLocation

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
    
    /// Continuación para el stream de previsualización
    private var streamContinuation: AsyncStream<UIImage>.Continuation?
    
    /// Sesión de captura de AVFoundation.
    private let session = AVCaptureSession()
    
    /// Salida de video para la previsualización
    private let videoOutput = AVCaptureVideoDataOutput()
    
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
        }
        
        guard session.canSetSessionPreset(preset) else {
            throw CameraError.resolutionNotSupported
        }
        
        session.sessionPreset = preset
    }
    
    /// Verifica y solicita los permisos de acceso a la cámara.
    ///
    /// - Returns: `true` si se concedieron los permisos, `false` en caso contrario.
    func checkPermissions() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                throw CameraError.permissionDenied
            }
        case .denied, .restricted:
            throw CameraError.permissionDenied
        @unknown default:
            throw CameraError.permissionDenied
        }
    }
    
    /// Configura la sesión de la cámara con los ajustes especificados
    ///
    /// Este método:
    /// 1. Verifica los permisos
    /// 2. Configura el dispositivo de entrada (cámara trasera)
    /// 3. Configura la salida de fotos
    /// 4. Configura la salida de video para previsualización
    /// 5. Configura la resolución y orientación
    ///
    /// - Parameter resolution: La resolución deseada para la cámara
    /// - Throws: `CameraError` si hay algún problema durante la configuración
    func setup(resolution: CameraResolution) async throws {
        // Verificar permisos primero
        try await checkPermissions()
        
        // Configurar entrada
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.invalidDevice
        }
        
        deviceInput = try AVCaptureDeviceInput(device: device)
        
        guard session.canAddInput(deviceInput!) else {
            throw CameraError.setupFailed
        }
        session.addInput(deviceInput!)
        
        // Configurar salida de fotos
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.setupFailed
        }
        session.addOutput(photoOutput)
        
        // Configurar salida de video para preview
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoPreviewQueue"))
        guard session.canAddOutput(videoOutput) else {
            throw CameraError.setupFailed
        }
        session.addOutput(videoOutput)
        
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
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
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
        
        if let connection = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
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
    
    /// Inicia la sesión de la cámara y devuelve un stream de previsualización
    func startSession() async throws -> AsyncStream<UIImage> {
        guard !session.isRunning else {
            throw CameraError.sessionNotRunning
        }
        
        let stream = AsyncStream<UIImage> { continuation in
            self.streamContinuation = continuation
        }
        
        Task.detached {
            await MainActor.run {
                self.isRunning = true
            }
            await self.session.startRunning()
        }
        
        return stream
    }
    
    /// Detiene la sesión de la cámara
    func stopSession() {
        guard session.isRunning else { return }
        Task.detached {
            await self.session.stopRunning()
            await MainActor.run {
                self.isRunning = false
                self.streamContinuation?.finish()
                self.streamContinuation = nil
            }
        }
    }
    
    // MARK: - Photo Capture Delegate
    private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
        private let completion: (Result<UIImage, CameraError>) -> Void
        
        init(completion: @escaping (Result<UIImage, CameraError>) -> Void) {
            self.completion = completion
            super.init()
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if error != nil {
                print("Error al capturar foto: \(error?.localizedDescription ?? "Error desconocido")")
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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        
        Task { @MainActor in
            self.streamContinuation?.yield(image)
        }
    }
}

// MARK: - Photo Capture
extension CameraService {
    /// Captura una foto con los ajustes especificados
    ///
    /// - Parameters:
    ///   - location: Ubicación opcional para incluir en los metadatos de la foto
    /// - Returns: La imagen capturada
    /// - Throws: `CameraError` si hay algún problema durante la captura
    func capturePhoto(location: CLLocation? = nil) async throws -> UIImage {
        guard session.isRunning else {
            throw CameraError.sessionNotRunning
        }
        
        let settings = AVCapturePhotoSettings()
        if let location = location {
            settings.metadata = [
                kCGImagePropertyGPSDictionary as String: [
                    kCGImagePropertyGPSLatitude as String: abs(location.coordinate.latitude),
                    kCGImagePropertyGPSLatitudeRef as String: location.coordinate.latitude >= 0 ? "N" : "S",
                    kCGImagePropertyGPSLongitude as String: abs(location.coordinate.longitude),
                    kCGImagePropertyGPSLongitudeRef as String: location.coordinate.longitude >= 0 ? "E" : "W",
                    kCGImagePropertyGPSAltitude as String: location.altitude,
                    kCGImagePropertyGPSTimeStamp as String: ISO8601DateFormatter().string(from: location.timestamp)
                ]
            ]
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate { result in
                switch result {
                case .success(let image):
                    continuation.resume(returning: image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            // Retener el delegate hasta que se complete la captura
            objc_setAssociatedObject(photoOutput, "PhotoCaptureDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}
