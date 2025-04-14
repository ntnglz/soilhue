import Foundation
import SwiftUI
import CoreImage

/// Servicio que maneja la calibración de la cámara para el análisis de color del suelo.
///
/// Este servicio proporciona funcionalidades para:
/// - Calibrar la cámara usando una tarjeta de referencia de color
/// - Ajustar los valores de color para compensar las condiciones de iluminación
/// - Almacenar y cargar los parámetros de calibración
class CalibrationService: ObservableObject {
    /// Estado de la calibración
    enum CalibrationState : Equatable {
        /// No calibrado
        case notCalibrated
        /// Calibración en progreso
        case calibrating
        /// Calibrado correctamente
        case calibrated
        /// Error en la calibración
        case error(String)
    }
    
    /// Estado actual de la calibración
    @Published var calibrationState: CalibrationState = .notCalibrated
    
    /// Factores de corrección para cada canal de color
    @Published var correctionFactors: (red: Double, green: Double, blue: Double) = (1.0, 1.0, 1.0)
    
    /// Valores de referencia para la tarjeta de calibración
    private let referenceValues: [String: (red: Double, green: Double, blue: Double)] = [
        "white": (0.95, 0.95, 0.95),
        "gray": (0.5, 0.5, 0.5),
        "black": (0.1, 0.1, 0.1),
        "red": (0.8, 0.2, 0.2),
        "green": (0.2, 0.8, 0.2),
        "blue": (0.2, 0.2, 0.8)
    ]
    
    /// Inicia el proceso de calibración
    func startCalibration() {
        calibrationState = .calibrating
    }
    
    /// Procesa una imagen de calibración y calcula los factores de corrección
    /// - Parameter image: Imagen de la tarjeta de calibración
    func processCalibrationImage(_ image: UIImage) {
        // Extraer los valores de color de la imagen
        guard let cgImage = image.cgImage else {
            calibrationState = .error("No se pudo procesar la imagen de calibración")
            return
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        // Dividir la imagen en secciones para cada color de referencia
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        
        // Calcular los factores de corrección para cada canal
        var redFactor = 1.0
        var greenFactor = 1.0
        var blueFactor = 1.0
        
        // Procesar cada color de referencia
        for (colorName, referenceValue) in referenceValues {
            // Calcular la región de la imagen para este color
            // (Simplificado para este ejemplo)
            let region = CGRect(x: 0, y: 0, width: width/6, height: height)
            
            // Obtener el color promedio en esta región
            let colorAtRegion = getAverageColor(in: ciImage, region: region, context: context)
            
            // Calcular el factor de corrección para este color
            let redRatio = referenceValue.red / colorAtRegion.red
            let greenRatio = referenceValue.green / colorAtRegion.green
            let blueRatio = referenceValue.blue / colorAtRegion.blue
            
            // Actualizar los factores de corrección (promedio de todos los colores)
            redFactor = (redFactor + redRatio) / 2
            greenFactor = (greenFactor + greenRatio) / 2
            blueFactor = (blueFactor + blueRatio) / 2
        }
        
        // Actualizar los factores de corrección
        correctionFactors = (redFactor, greenFactor, blueFactor)
        
        // Guardar los factores de corrección
        saveCalibrationFactors()
        
        // Actualizar el estado de calibración
        calibrationState = .calibrated
    }
    
    /// Obtiene el color promedio en una región específica de la imagen
    private func getAverageColor(in image: CIImage, region: CGRect, context: CIContext) -> (red: Double, green: Double, blue: Double) {
        // Crear un filtro para recortar la región
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter?.setValue(image, forKey: kCIInputImageKey)
        cropFilter?.setValue(CIVector(cgRect: region), forKey: "inputRectangle")
        
        guard let outputImage = cropFilter?.outputImage else {
            return (0, 0, 0)
        }
        
        // Obtener el color promedio
        let extentVector = CIVector(x: 0, y: 0, z: region.width, w: region.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: outputImage,
            kCIInputExtentKey: extentVector
        ])
        
        guard let outputImage2 = filter?.outputImage else {
            return (0, 0, 0)
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage2, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        return (
            Double(bitmap[0]) / 255.0,
            Double(bitmap[1]) / 255.0,
            Double(bitmap[2]) / 255.0
        )
    }
    
    /// Aplica los factores de corrección a un color RGB
    /// - Parameters:
    ///   - red: Componente rojo (0-1)
    ///   - green: Componente verde (0-1)
    ///   - blue: Componente azul (0-1)
    /// - Returns: Color RGB corregido
    func applyCalibration(red: Double, green: Double, blue: Double) -> (red: Double, green: Double, blue: Double) {
        return (
            min(max(red * correctionFactors.red, 0), 1),
            min(max(green * correctionFactors.green, 0), 1),
            min(max(blue * correctionFactors.blue, 0), 1)
        )
    }
    
    /// Guarda los factores de corrección en UserDefaults
    private func saveCalibrationFactors() {
        let defaults = UserDefaults.standard
        defaults.set(correctionFactors.red, forKey: "calibrationRedFactor")
        defaults.set(correctionFactors.green, forKey: "calibrationGreenFactor")
        defaults.set(correctionFactors.blue, forKey: "calibrationBlueFactor")
        defaults.set(true, forKey: "isCalibrated")
    }
    
    /// Carga los factores de corrección desde UserDefaults
    func loadCalibrationFactors() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "isCalibrated") {
            correctionFactors = (
                defaults.double(forKey: "calibrationRedFactor"),
                defaults.double(forKey: "calibrationGreenFactor"),
                defaults.double(forKey: "calibrationBlueFactor")
            )
            calibrationState = .calibrated
        } else {
            calibrationState = .notCalibrated
        }
    }
    
    /// Reinicia la calibración
    func resetCalibration() {
        correctionFactors = (1.0, 1.0, 1.0)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "calibrationRedFactor")
        defaults.removeObject(forKey: "calibrationGreenFactor")
        defaults.removeObject(forKey: "calibrationBlueFactor")
        defaults.removeObject(forKey: "isCalibrated")
        calibrationState = .notCalibrated
    }
} 
