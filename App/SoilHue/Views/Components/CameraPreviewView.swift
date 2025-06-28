import SwiftUI
import AVFoundation

/// Vista que muestra la previsualización de la cámara en tiempo real.
///
/// Esta vista utiliza `UIViewRepresentable` para mostrar la capa de previsualización
/// de AVFoundation en SwiftUI. Se integra con `CameraService` para mostrar
/// la vista previa de la cámara y capturar fotos.
struct CameraPreviewView: UIViewRepresentable {
    /// El servicio de cámara que proporciona la previsualización.
    let cameraService: CameraService
    
    /// Tipo de contenido de video para la previsualización.
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    
    /// Color de fondo de la vista.
    var backgroundColor: UIColor = .black
    
    /// Crea la vista de UIKit que mostrará la previsualización.
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.backgroundColor = backgroundColor
        
        let previewLayer = cameraService.previewLayer
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = videoGravity
        
        // Asegurarse de que la capa de previsualización está en el hilo principal
        DispatchQueue.main.async {
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    /// Actualiza la vista cuando cambian las propiedades.
    func updateUIView(_ uiView: UIView, context: Context) {
        // Asegurarse de que la actualización se realiza en el hilo principal
        DispatchQueue.main.async {
            cameraService.previewLayer.frame = uiView.bounds
            cameraService.previewLayer.videoGravity = videoGravity
        }
    }
}

// MARK: - Extensiones de conveniencia

extension CameraPreviewView {
    /// Crea una vista de previsualización con configuración predeterminada.
    /// - Parameter cameraService: El servicio de cámara que proporciona la previsualización.
    static func standard(cameraService: CameraService) -> CameraPreviewView {
        CameraPreviewView(cameraService: cameraService)
    }
    
    /// Crea una vista de previsualización optimizada para captura de muestras de suelo.
    /// - Parameter cameraService: El servicio de cámara que proporciona la previsualización.
    static func soilSample(cameraService: CameraService) -> CameraPreviewView {
        CameraPreviewView(
            cameraService: cameraService,
            videoGravity: .resizeAspect,
            backgroundColor: .black
        )
    }
}

#Preview {
    CameraPreviewView(cameraService: CameraService())
} 