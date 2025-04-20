//
//  SoilSampleViewModel.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//


import SwiftUI
import CoreLocation

/// Errores que pueden ocurrir durante el manejo de muestras de suelo
enum SampleError: LocalizedError {
    /// No hay una muestra seleccionada
    case noSampleSelected
    /// Error al analizar la muestra
    case analysisError
    /// Error al guardar la muestra
    case saveError
    /// Error al cargar la muestra
    case loadError
    
    var errorDescription: String? {
        switch self {
        case .noSampleSelected:
            return "No hay una muestra seleccionada"
        case .analysisError:
            return "Error al analizar la muestra"
        case .saveError:
            return "Error al guardar la muestra"
        case .loadError:
            return "Error al cargar la muestra"
        }
    }
}

/// ViewModel que gestiona la lógica de negocio relacionada con las muestras de suelo.
///
/// Este ViewModel mantiene una colección de muestras de suelo y proporciona métodos
/// para añadir nuevas muestras y analizar las existentes. Está diseñado para ser usado
/// con SwiftUI y maneja automáticamente las actualizaciones de la UI cuando cambian los datos.
@MainActor
class SoilSampleViewModel: ObservableObject {
    /// Colección de muestras de suelo capturadas.
    @Published var samples: [SoilSample] = []
    
    /// Muestra de suelo actualmente seleccionada o en proceso de análisis.
    @Published var currentSample: SoilSample? {
        didSet {
            print("DEBUG: SoilSampleViewModel - currentSample actualizado")
            if let locationInfo = currentSample?.location {
                print("DEBUG: SoilSampleViewModel - Ubicación disponible: \(locationInfo.coordinate)")
            } else {
                print("DEBUG: SoilSampleViewModel - No hay ubicación disponible")
            }
        }
    }
    
    /// Resultado del análisis actual
    @Published var analysisResult: SoilAnalysisResult?
    
    /// Servicio para analizar el color de las imágenes.
    private let colorAnalysisService = ColorAnalysisService()
    
    /// Servicio para almacenar los análisis
    private let storageService: StorageService
    
    /// Servicio de calibración
    private let calibrationService = CalibrationService()
    
    init() {
        do {
            self.storageService = try StorageService()
        } catch {
            fatalError("Error inicializando StorageService: \(error.localizedDescription)")
        }
    }
    
    /// Añade una nueva muestra de suelo a la colección.
    ///
    /// - Parameters:
    ///   - image: Imagen capturada de la muestra de suelo.
    ///   - location: Ubicación donde se capturó la muestra (opcional).
    func addSample(image: UIImage, location: CLLocation?) {
        print("DEBUG: SoilSampleViewModel - Añadiendo nueva muestra")
        if let location = location {
            print("DEBUG: SoilSampleViewModel - Con ubicación: \(location.coordinate)")
        }
        currentSample = SoilSample(
            image: image,
            location: location
        )
    }
    
    /// Analiza una muestra de suelo utilizando el servicio de análisis de color.
    ///
    /// - Parameter sample: La muestra de suelo a analizar.
    /// - Returns: Un objeto `SoilAnalysisResult` que contiene el color Munsell y la clasificación del suelo.
    func analyzeSample(_ sample: SoilSample) async throws -> SoilAnalysisResult {
        // Analizar la imagen para obtener el color dominante y la clasificación
        let analysis = try await colorAnalysisService.analyzeImage(sample.image)
        
        // Crear el resultado del análisis
        let result = SoilAnalysisResult(
            munsellColor: analysis.munsellNotation,
            soilClassification: analysis.soilClassification,
            soilDescription: analysis.soilDescription
        )
        
        // Actualizar la muestra con los resultados
        if let index = samples.firstIndex(where: { $0.id == sample.id }) {
            samples[index].munsellColor = result.munsellColor
            samples[index].soilClassification = result.soilClassification
            samples[index].soilDescription = result.soilDescription
            currentSample = samples[index]
        }
        
        // Actualizar el resultado del análisis
        analysisResult = result
        
        return result
    }
    
    /// Analiza una región específica de una muestra de suelo.
    ///
    /// - Parameters:
    ///   - sample: La muestra de suelo a analizar.
    ///   - region: La región rectangular a analizar (en coordenadas normalizadas 0-1).
    /// - Returns: Un objeto `SoilAnalysisResult` que contiene el color Munsell y la clasificación del suelo.
    func analyzeSampleRegion(_ sample: SoilSample, region: CGRect) async throws -> SoilAnalysisResult {
        // Analizar la región específica de la imagen
        let analysis = try await colorAnalysisService.analyzeImage(sample.image, region: region)
        
        // Crear el resultado del análisis
        let result = SoilAnalysisResult(
            munsellColor: analysis.munsellNotation,
            soilClassification: analysis.soilClassification,
            soilDescription: analysis.soilDescription
        )
        
        // Actualizar la muestra con los resultados
        if let index = samples.firstIndex(where: { $0.id == sample.id }) {
            samples[index].munsellColor = result.munsellColor
            samples[index].soilClassification = result.soilClassification
            samples[index].soilDescription = result.soilDescription
            currentSample = samples[index]
        }
        
        // Actualizar el resultado del análisis
        analysisResult = result
        
        return result
    }
    
    /// Analiza un área poligonal de una muestra de suelo.
    ///
    /// - Parameters:
    ///   - sample: La muestra de suelo a analizar.
    ///   - polygonPoints: Array de puntos que definen el polígono a analizar (en coordenadas normalizadas 0-1).
    /// - Returns: Un objeto `SoilAnalysisResult` que contiene el color Munsell y la clasificación del suelo.
    func analyzeSamplePolygon(_ sample: SoilSample, polygonPoints: [CGPoint]) async throws -> SoilAnalysisResult {
        // Analizar el área poligonal de la imagen
        let analysis = try await colorAnalysisService.analyzeImage(sample.image, polygonPoints: polygonPoints)
        
        // Crear el resultado del análisis
        let result = SoilAnalysisResult(
            munsellColor: analysis.munsellNotation,
            soilClassification: analysis.soilClassification,
            soilDescription: analysis.soilDescription
        )
        
        // Actualizar la muestra con los resultados
        if let index = samples.firstIndex(where: { $0.id == sample.id }) {
            samples[index].munsellColor = result.munsellColor
            samples[index].soilClassification = result.soilClassification
            samples[index].soilDescription = result.soilDescription
            currentSample = samples[index]
        }
        
        // Actualizar el resultado del análisis
        analysisResult = result
        
        return result
    }
    
    /// Guarda una muestra de suelo con notas y etiquetas.
    ///
    /// - Parameters:
    ///   - notes: Notas adicionales sobre la muestra.
    ///   - tags: Etiquetas para categorizar la muestra.
    func saveSample(notes: String, tags: [String]) async throws {
        guard let sample = currentSample else {
            throw SampleError.noSampleSelected
        }
        
        print("DEBUG: SoilSampleViewModel - Guardando muestra con localización: \(String(describing: sample.location))")
        
        let analysis = SoilAnalysis(
            id: UUID(),
            timestamp: Date(),
            imageData: sample.image.jpegData(compressionQuality: 0.8) ?? Data(),
            notes: notes,
            tags: tags,
            locationInfo: sample.location,
            munsellColor: sample.munsellColor,
            soilClassification: sample.soilClassification,
            soilDescription: sample.soilDescription,
            calibrationInfo: CalibrationInfo(
                wasCalibrated: colorAnalysisService.isCalibrated,
                correctionFactors: colorAnalysisService.correctionFactors,
                lastCalibrationDate: calibrationService.lastCalibrationDate ?? Date()
            ),
            environmentalConditions: EnvironmentalConditions(
                temperature: nil,
                humidity: nil,
                lightConditions: nil,
                weatherConditions: nil
            )
        )
        
        print("DEBUG: SoilSampleViewModel - Análisis creado con locationInfo: \(String(describing: analysis.locationInfo))")
        try await storageService.saveAnalysis(analysis, image: sample.image)
    }
    
}

/// Estructura que representa el resultado del análisis de una muestra de suelo.
struct SoilAnalysisResult {
    /// Color Munsell identificado.
    let munsellColor: String
    
    /// Clasificación del suelo basada en el color Munsell.
    let soilClassification: String
    
    /// Descripción detallada del tipo de suelo.
    let soilDescription: String
}
