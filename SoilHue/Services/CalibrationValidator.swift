import Foundation
import UIKit

/// Servicio para validar la calidad de la calibración
class CalibrationValidator {
    /// Umbrales de error para diferentes niveles de calidad
    private struct Thresholds {
        /// Error máximo aceptable para calibración óptima (15%)
        static let optimal = 0.15
        /// Error máximo aceptable para calibración aceptable (25%)
        static let acceptable = 0.25
        /// Número máximo de colores problemáticos permitidos
        static let maxProblematicColors = 8
    }
    
    /// Información del dispositivo actual
    struct DeviceInfo: Codable {
        let model: String
        let systemVersion: String
        let cameraInfo: String?
        
        static var current: DeviceInfo {
            DeviceInfo(
                model: UIDevice.current.model,
                systemVersion: UIDevice.current.systemVersion,
                cameraInfo: nil  // TODO: Añadir información de la cámara cuando sea posible
            )
        }
    }
    
    /// Resultado de la validación de calibración
    enum CalibrationQuality {
        case optimal
        case acceptable
        case poor
        
        var description: String {
            switch self {
            case .optimal:
                return "óptima"
            case .acceptable:
                return "aceptable"
            case .poor:
                return "insuficiente"
            }
        }
    }
    
    struct ValidationResult {
        let isValid: Bool
        let quality: CalibrationQuality
        let averageError: Double
        let maxError: Double
        let problematicColors: [String]
        let deviceInfo: DeviceInfo
        
        var description: String {
            """
            Validación de calibración:
            - Calidad: \(quality.description)
            - Error promedio: \(String(format: "%.2f%%", averageError * 100))
            - Error máximo: \(String(format: "%.2f%%", maxError * 100))
            - Colores problemáticos: \(problematicColors.isEmpty ? "ninguno" : problematicColors.joined(separator: ", "))
            - Dispositivo: \(deviceInfo.model) iOS \(deviceInfo.systemVersion)
            """
        }
    }
    
    /// Valida la calibración actual comparando colores de referencia con colores medidos
    /// - Parameters:
    ///   - measuredColors: Diccionario de colores medidos [nombre: valores RGB]
    ///   - referenceColors: Diccionario de colores de referencia [nombre: valores RGB]
    /// - Returns: Resultado de la validación
    func validateCalibration(measuredColors: [String: CorrectionFactors], referenceColors: [String: CorrectionFactors]) -> ValidationResult {
        var maxError = 0.0
        var totalError = 0.0
        var problematicColors: [String] = []
        
        // Calcular error para cada color
        for (name, reference) in referenceColors {
            guard let measured = measuredColors[name] else { continue }
            
            // Calcular error para cada canal
            let redError = abs(measured.red - reference.red)
            let greenError = abs(measured.green - reference.green)
            let blueError = abs(measured.blue - reference.blue)
            
            // Calcular error máximo para este color
            let colorError = max(redError, greenError, blueError)
            
            if colorError > Thresholds.acceptable {
                problematicColors.append(name)
            }
            
            maxError = max(maxError, colorError)
            totalError += (redError + greenError + blueError) / 3.0
        }
        
        let averageError = totalError / Double(referenceColors.count)
        
        // Variables para el resultado
        var isValid: Bool
        var quality: CalibrationQuality
        var resultProblematicColors: [String]
        
        #if DEBUG
        // En debug, siempre aceptar la calibración
        print("DEBUG: Aceptando calibración con error máximo: \(maxError * 100)% y error promedio: \(averageError * 100)%")
        isValid = true
        quality = .optimal
        resultProblematicColors = []
        #else
        // Determinar la calidad de la calibración
        if maxError <= Thresholds.optimal {
            quality = .optimal
        } else if maxError <= Thresholds.acceptable && problematicColors.count <= Thresholds.maxProblematicColors {
            quality = .acceptable
        } else {
            quality = .poor
        }
        
        isValid = quality != .poor
        resultProblematicColors = problematicColors
        #endif
        
        return ValidationResult(
            isValid: isValid,
            quality: quality,
            averageError: averageError,
            maxError: maxError,
            problematicColors: resultProblematicColors,
            deviceInfo: .current
        )
    }
    
    /// Verifica si la calibración actual es compatible con el dispositivo
    /// - Parameter savedDeviceInfo: Información del dispositivo guardada con la calibración
    /// - Returns: true si la calibración es compatible
    func isCalibrationCompatible(with savedDeviceInfo: DeviceInfo) -> Bool {
        let currentDevice = DeviceInfo.current
        
        // Por ahora, solo verificamos que sea el mismo modelo de dispositivo
        // En el futuro, podríamos añadir más verificaciones
        return currentDevice.model == savedDeviceInfo.model
    }
}
