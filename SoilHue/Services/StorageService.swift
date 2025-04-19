import Foundation
import UIKit

/// Servicio para gestionar el almacenamiento de análisis de suelo
@MainActor
class StorageService: ObservableObject {
    /// Error que pueden ocurrir durante las operaciones de almacenamiento
    enum StorageError: LocalizedError {
        case failedToSaveImage
        case failedToSaveAnalysis
        case failedToLoadAnalysis
        case analysisNotFound
        case iCloudNotAvailable
        case invalidDirectory
        
        var errorDescription: String? {
            switch self {
            case .failedToSaveImage:
                return "No se pudo guardar la imagen"
            case .failedToSaveAnalysis:
                return "No se pudo guardar el análisis"
            case .failedToLoadAnalysis:
                return "No se pudo cargar el análisis"
            case .analysisNotFound:
                return "Análisis no encontrado"
            case .iCloudNotAvailable:
                return "iCloud no está disponible"
            case .invalidDirectory:
                return "Directorio de almacenamiento no válido"
            }
        }
    }
    
    /// Ubicación actual de almacenamiento
    @Published private(set) var currentLocation: SaveLocation
    
    /// URL base para almacenamiento local
    private let localBaseURL: URL
    
    /// URL base para almacenamiento en iCloud
    private var iCloudBaseURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Analyses")
    }
    
    /// Inicializador
    init(location: SaveLocation = .local) {
        self.currentLocation = location
        
        // Configurar URL base local
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.localBaseURL = documentsDirectory.appendingPathComponent("Analyses")
        
        // Crear directorios si no existen
        try? FileManager.default.createDirectory(at: localBaseURL, withIntermediateDirectories: true)
        if let iCloudURL = iCloudBaseURL {
            try? FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
        }
    }
    
    /// Cambia la ubicación de almacenamiento
    func changeLocation(_ newLocation: SaveLocation) {
        currentLocation = newLocation
    }
    
    /// Guarda un nuevo análisis
    func saveAnalysis(_ analysis: SoilAnalysis, image: UIImage) async throws {
        // Determinar URL base según la ubicación
        let baseURL = currentLocation == .local ? localBaseURL : (iCloudBaseURL ?? localBaseURL)
        
        // Crear directorio para este análisis
        let analysisDirectory = baseURL.appendingPathComponent(analysis.id.uuidString)
        try FileManager.default.createDirectory(at: analysisDirectory, withIntermediateDirectories: true)
        
        // Guardar la imagen
        let imageURL = analysisDirectory.appendingPathComponent("image.jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.failedToSaveImage
        }
        try imageData.write(to: imageURL)
        
        // Crear y guardar el análisis
        var updatedAnalysis = analysis
        if let imageInfo = try? JSONDecoder().decode(ImageInfo.self, from: JSONEncoder().encode(analysis.imageInfo)) {
            // Actualizar la URL de la imagen al path relativo
            let newImageInfo = ImageInfo(
                imageURL: imageURL,
                selectionArea: imageInfo.selectionArea,
                resolution: imageInfo.resolution
            )
            updatedAnalysis = SoilAnalysis(
                id: analysis.id,
                timestamp: analysis.timestamp,
                colorInfo: analysis.colorInfo,
                imageInfo: newImageInfo,
                calibrationInfo: analysis.calibrationInfo,
                metadata: analysis.metadata
            )
        }
        
        // Guardar los datos del análisis
        let analysisURL = analysisDirectory.appendingPathComponent("analysis.json")
        let analysisData = try JSONEncoder().encode(updatedAnalysis)
        try analysisData.write(to: analysisURL)
        
        // Si estamos en iCloud, forzar la sincronización
        if currentLocation == .iCloud {
            try await syncWithiCloud()
        }
    }
    
    /// Carga todos los análisis almacenados
    func loadAllAnalyses() async throws -> [SoilAnalysis] {
        let baseURL = currentLocation == .local ? localBaseURL : (iCloudBaseURL ?? localBaseURL)
        
        // Obtener contenido del directorio
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )
        
        // Cargar cada análisis
        var analyses: [SoilAnalysis] = []
        for directory in contents {
            let analysisURL = directory.appendingPathComponent("analysis.json")
            if let analysisData = try? Data(contentsOf: analysisURL),
               let analysis = try? JSONDecoder().decode(SoilAnalysis.self, from: analysisData) {
                analyses.append(analysis)
            }
        }
        
        return analyses.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Elimina un análisis
    func deleteAnalysis(_ analysis: SoilAnalysis) async throws {
        let baseURL = currentLocation == .local ? localBaseURL : (iCloudBaseURL ?? localBaseURL)
        let analysisDirectory = baseURL.appendingPathComponent(analysis.id.uuidString)
        
        try FileManager.default.removeItem(at: analysisDirectory)
        
        if currentLocation == .iCloud {
            try await syncWithiCloud()
        }
    }
    
    /// Sincroniza con iCloud
    private func syncWithiCloud() async throws {
        guard currentLocation == .iCloud else { return }
        guard let ubiquityURL = iCloudBaseURL else {
            throw StorageError.iCloudNotAvailable
        }
        
        // Forzar sincronización con iCloud
        let fileCoordinator = NSFileCoordinator()
        var coordinatorError: NSError?
        
        fileCoordinator.coordinate(
            writingItemAt: ubiquityURL,
            options: .forMerging,
            error: &coordinatorError
        ) { url in
            // La sincronización ocurre automáticamente
        }
        
        if let error = coordinatorError {
            throw error
        }
    }
} 