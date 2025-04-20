import Foundation
import CoreLocation
import UIKit

/// Modelo que representa un análisis completo de suelo
struct SoilAnalysis: Identifiable, Codable {
    /// Identificador único del análisis
    let id: UUID
    
    /// Fecha y hora del análisis
    let timestamp: Date
    
    /// Información del color y clasificación
    let colorInfo: ColorInfo
    
    /// Información de la imagen
    let imageInfo: ImageInfo
    
    /// Información de calibración
    let calibrationInfo: CalibrationInfo
    
    /// Metadatos adicionales
    let metadata: AnalysisMetadata
    
    /// Inicializador por defecto
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        colorInfo: ColorInfo,
        imageInfo: ImageInfo,
        calibrationInfo: CalibrationInfo,
        metadata: AnalysisMetadata
    ) {
        self.id = id
        self.timestamp = timestamp
        self.colorInfo = colorInfo
        self.imageInfo = imageInfo
        self.calibrationInfo = calibrationInfo
        self.metadata = metadata
    }
}

// MARK: - Estructuras de Soporte

/// Información del color y clasificación del suelo
struct ColorInfo: Codable {
    /// Notación Munsell identificada
    let munsellNotation: String
    
    /// Clasificación del suelo
    let soilClassification: String
    
    /// Descripción detallada del suelo
    let soilDescription: String
    
    /// Valores RGB corregidos
    let correctedRGB: RGBValues
}

/// Información de la imagen analizada
struct ImageInfo: Codable {
    /// URL de la imagen original
    let imageURL: URL
    
    /// Área seleccionada para el análisis (coordenadas normalizadas)
    let selectionArea: SelectionArea
    
    /// Resolución de la imagen
    let resolution: ImageResolution
}

/// Información de calibración
struct CalibrationInfo: Codable {
    /// Estado de la calibración
    let wasCalibrated: Bool
    
    /// Factores de corrección utilizados
    let correctionFactors: CorrectionFactors
    
    /// Fecha de la última calibración
    let lastCalibrationDate: Date
}

/// Metadatos adicionales del análisis
struct AnalysisMetadata: Codable {
    /// Localización donde se tomó la muestra
    let location: LocationInfo?
    
    /// Notas del usuario
    let notes: String?
    
    /// Etiquetas definidas por el usuario
    let tags: [String]
    
    /// Condiciones ambientales
    let environmentalConditions: EnvironmentalConditions?
}

// MARK: - Estructuras Auxiliares

/// Valores RGB
struct RGBValues: Codable {
    let red: Double
    let green: Double
    let blue: Double
}

/// Área seleccionada para análisis
struct SelectionArea: Codable {
    /// Tipo de selección (rectángulo o polígono)
    let type: SelectionType
    
    /// Coordenadas normalizadas (0-1) del área seleccionada
    let coordinates: SelectionCoordinates
    
    enum SelectionType: String, Codable {
        case rectangle
        case polygon
    }
}

/// Coordenadas de selección
enum SelectionCoordinates: Codable {
    case rectangle(CGRect)
    case polygon([CGPoint])
    
    private enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .rectangle(let rect):
            try container.encode("rectangle", forKey: .type)
            try container.encode([rect.origin.x, rect.origin.y, rect.width, rect.height], forKey: .coordinates)
        case .polygon(let points):
            try container.encode("polygon", forKey: .type)
            try container.encode(points.map { [$0.x, $0.y] }, forKey: .coordinates)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "rectangle":
            let coords = try container.decode([CGFloat].self, forKey: .coordinates)
            self = .rectangle(CGRect(x: coords[0], y: coords[1], width: coords[2], height: coords[3]))
        case "polygon":
            let coords = try container.decode([[CGFloat]].self, forKey: .coordinates)
            self = .polygon(coords.map { CGPoint(x: $0[0], y: $0[1]) })
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid selection type")
        }
    }
}

/// Resolución de la imagen
struct ImageResolution: Codable {
    let width: Int
    let height: Int
    let quality: CameraResolution
}

/// Condiciones ambientales durante el análisis
struct EnvironmentalConditions: Codable {
    let lightingCondition: LightingCondition
    let weatherCondition: WeatherCondition?
    
    enum LightingCondition: String, Codable {
        case sunlight
        case shade
        case artificial
        case unknown
    }
    
    enum WeatherCondition: String, Codable {
        case clear
        case cloudy
        case rainy
        case unknown
    }
} 
