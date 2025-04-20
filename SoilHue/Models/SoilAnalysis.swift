import Foundation
import CoreLocation
import UIKit

/// Modelo que representa un análisis completo de suelo
struct SoilAnalysis: Identifiable, Codable {
    /// Identificador único del análisis
    let id: UUID
    
    /// Fecha y hora del análisis
    let timestamp: Date
    
    /// Datos de la imagen analizada
    let imageData: Data
    
    /// Notas del usuario
    let notes: String
    
    /// Etiquetas definidas por el usuario
    let tags: [String]
    
    /// Información de ubicación
    let locationInfo: CLLocation?
    
    /// Información del color y clasificación
    var munsellColor: String?
    var soilClassification: String?
    var soilDescription: String?
    
    /// Información de calibración
    var calibrationInfo: CalibrationInfo?
    
    /// Condiciones ambientales
    var environmentalConditions: EnvironmentalConditions?
    
    /// Inicializador por defecto
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        imageData: Data,
        notes: String,
        tags: [String],
        locationInfo: CLLocation?,
        munsellColor: String?,
        soilClassification: String?,
        soilDescription: String?,
        calibrationInfo: CalibrationInfo?,
        environmentalConditions: EnvironmentalConditions?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.imageData = imageData
        self.notes = notes
        self.tags = tags
        self.locationInfo = locationInfo
        self.munsellColor = munsellColor
        self.soilClassification = soilClassification
        self.soilDescription = soilDescription
        self.calibrationInfo = calibrationInfo
        self.environmentalConditions = environmentalConditions
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, imageData, notes, tags
        case locationData = "locationInfo"
        case munsellColor, soilClassification, soilDescription
        case calibrationInfo, environmentalConditions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        imageData = try container.decode(Data.self, forKey: .imageData)
        notes = try container.decode(String.self, forKey: .notes)
        tags = try container.decode([String].self, forKey: .tags)
        
        // Decode location if present
        if let locationData = try container.decodeIfPresent(LocationData.self, forKey: .locationData) {
            print("DEBUG: Decodificando localización - lat: \(locationData.latitude), lon: \(locationData.longitude)")
            locationInfo = CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: locationData.latitude,
                    longitude: locationData.longitude
                ),
                altitude: locationData.altitude,
                horizontalAccuracy: locationData.horizontalAccuracy,
                verticalAccuracy: locationData.verticalAccuracy,
                timestamp: locationData.timestamp
            )
        } else {
            locationInfo = nil
            print("DEBUG: No se encontró información de localización en el JSON")
        }
        
        munsellColor = try container.decodeIfPresent(String.self, forKey: .munsellColor)
        soilClassification = try container.decodeIfPresent(String.self, forKey: .soilClassification)
        soilDescription = try container.decodeIfPresent(String.self, forKey: .soilDescription)
        calibrationInfo = try container.decodeIfPresent(CalibrationInfo.self, forKey: .calibrationInfo)
        environmentalConditions = try container.decodeIfPresent(EnvironmentalConditions.self, forKey: .environmentalConditions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(imageData, forKey: .imageData)
        try container.encode(notes, forKey: .notes)
        try container.encode(tags, forKey: .tags)
        
        // Encode location if present
        if let location = locationInfo {
            print("DEBUG: Codificando localización - lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude)")
            let locationData = LocationData(from: location)
            try container.encode(locationData, forKey: .locationData)
        } else {
            print("DEBUG: No hay localización para codificar")
        }
        
        try container.encodeIfPresent(munsellColor, forKey: .munsellColor)
        try container.encodeIfPresent(soilClassification, forKey: .soilClassification)
        try container.encodeIfPresent(soilDescription, forKey: .soilDescription)
        try container.encodeIfPresent(calibrationInfo, forKey: .calibrationInfo)
        try container.encodeIfPresent(environmentalConditions, forKey: .environmentalConditions)
    }
}

// MARK: - Location Data Structure
struct LocationData: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let altitude: CLLocationDistance
    let horizontalAccuracy: CLLocationAccuracy
    let verticalAccuracy: CLLocationAccuracy
    let timestamp: Date
    
    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.timestamp = location.timestamp
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
    let temperature: Double?
    let humidity: Double?
    let lightConditions: String?
    let weatherConditions: String?
}

extension SoilAnalysis {
    static var preview: SoilAnalysis {
        SoilAnalysis(
            id: UUID(),
            timestamp: Date(),
            imageData: Data(),
            notes: "Sample soil analysis",
            tags: ["clay", "organic"],
            locationInfo: nil,
            munsellColor: "10YR 4/6",
            soilClassification: "Clay Loam",
            soilDescription: "Dark brown clay loam with good organic content",
            calibrationInfo: CalibrationInfo(
                wasCalibrated: true,
                correctionFactors: CorrectionFactors(red: 1.0, green: 1.0, blue: 1.0),
                lastCalibrationDate: Date()
            ),
            environmentalConditions: EnvironmentalConditions(
                temperature: 25.0,
                humidity: 65.0,
                lightConditions: "Bright daylight",
                weatherConditions: "Clear sky"
            )
        )
    }
} 
