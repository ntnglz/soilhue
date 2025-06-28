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
        case directoryCreationFailed
        case fileOperationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .failedToSaveImage:
                return NSLocalizedString("storage.error.save.image", comment: "Failed to save image error message")
            case .failedToSaveAnalysis:
                return NSLocalizedString("storage.error.save.analysis", comment: "Failed to save analysis error message")
            case .failedToLoadAnalysis:
                return NSLocalizedString("storage.error.load.analysis", comment: "Failed to load analysis error message")
            case .analysisNotFound:
                return NSLocalizedString("storage.error.analysis.not.found", comment: "Analysis not found error message")
            case .iCloudNotAvailable:
                return NSLocalizedString("storage.error.icloud.not.available", comment: "iCloud not available error message")
            case .invalidDirectory:
                return NSLocalizedString("storage.error.invalid.directory", comment: "Invalid storage directory error message")
            case .directoryCreationFailed:
                return NSLocalizedString("storage.error.directory.creation", comment: "Failed to create storage directory error message")
            case .fileOperationFailed(let message):
                return String(format: NSLocalizedString("storage.error.file.operation", comment: "File operation error message"), message)
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
    init(location: SaveLocation = .local) throws {
        self.currentLocation = location
        
        // Configurar URL base local
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.localBaseURL = documentsDirectory.appendingPathComponent("Analyses")
        
        // Crear directorios si no existen
        try createDirectoriesIfNeeded()
    }
    
    /// Crea los directorios necesarios para el almacenamiento
    private func createDirectoriesIfNeeded() throws {
        do {
            try FileManager.default.createDirectory(at: localBaseURL, withIntermediateDirectories: true)
            
            if let iCloudURL = iCloudBaseURL {
                try FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
            }
        } catch {
            throw StorageError.directoryCreationFailed
        }
    }
    
    /// Obtiene la URL base actual según la ubicación de almacenamiento
    private func getCurrentBaseURL() throws -> URL {
        if currentLocation == .iCloud {
            guard let iCloudURL = iCloudBaseURL else {
                throw StorageError.iCloudNotAvailable
            }
            return iCloudURL
        }
        return localBaseURL
    }
    
    /// Verifica si un directorio existe
    private func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    /// Cambia la ubicación de almacenamiento
    func changeLocation(_ newLocation: SaveLocation) throws {
        if newLocation == .iCloud && iCloudBaseURL == nil {
            throw StorageError.iCloudNotAvailable
        }
        currentLocation = newLocation
    }
    
    /// Guarda un nuevo análisis
    func saveAnalysis(_ analysis: SoilAnalysis, image: UIImage) async throws {
        let baseURL = try getCurrentBaseURL()
        let analysisDirectory = baseURL.appendingPathComponent(analysis.id.uuidString)
        
        print("DEBUG: StorageService - Guardando análisis con locationInfo: \(String(describing: analysis.locationInfo))")
        print("DEBUG: StorageService - Intentando guardar análisis en: \(analysisDirectory)")
        
        // Crear directorio para este análisis
        do {
            try FileManager.default.createDirectory(at: analysisDirectory, withIntermediateDirectories: true)
            print("DEBUG: StorageService - Directorio creado correctamente")
        } catch {
            print("DEBUG: StorageService - Error al crear directorio: \(error)")
            throw StorageError.directoryCreationFailed
        }
        
        // Guardar la imagen
        let imageURL = analysisDirectory.appendingPathComponent("image.jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("DEBUG: Error al convertir imagen a JPEG")
            throw StorageError.failedToSaveImage
        }
        
        do {
            try imageData.write(to: imageURL)
            print("DEBUG: Imagen guardada correctamente en: \(imageURL)")
        } catch {
            print("DEBUG: Error al escribir imagen: \(error)")
            throw StorageError.fileOperationFailed("No se pudo escribir la imagen")
        }
        
        // Guardar los datos del análisis
        let analysisURL = analysisDirectory.appendingPathComponent("analysis.json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(analysis)
            try data.write(to: analysisURL)
            print("DEBUG: Análisis JSON guardado correctamente en: \(analysisURL)")
        } catch {
            print("DEBUG: Error al escribir análisis JSON: \(error)")
            throw StorageError.fileOperationFailed("No se pudo escribir el análisis")
        }
        
        // Sincronizar con iCloud si es necesario
        if currentLocation == .iCloud {
            try await syncWithiCloud()
        }
        
        print("DEBUG: Análisis guardado completamente")
    }
    
    /// Carga todos los análisis almacenados
    func loadAllAnalyses() async throws -> [SoilAnalysis] {
        let baseURL = try getCurrentBaseURL()
        
        guard directoryExists(at: baseURL) else {
            print("DEBUG: El directorio base no existe: \(baseURL)")
            return []
        }
        
        print("DEBUG: Cargando análisis desde: \(baseURL)")
        
        // Obtener contenido del directorio
        let fileManager = FileManager.default
        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            )
            print("DEBUG: Encontrados \(contents.count) elementos en el directorio")
        } catch {
            print("DEBUG: Error al leer contenido del directorio: \(error)")
            throw StorageError.fileOperationFailed("No se pudo leer el directorio")
        }
        
        // Cargar cada análisis
        var analyses: [SoilAnalysis] = []
        for directory in contents {
            print("DEBUG: Procesando directorio: \(directory)")
            let analysisURL = directory.appendingPathComponent("analysis.json")
            do {
                let analysisData = try Data(contentsOf: analysisURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let analysis = try decoder.decode(SoilAnalysis.self, from: analysisData)
                analyses.append(analysis)
                print("DEBUG: Análisis cargado correctamente: \(analysis.id)")
            } catch {
                print("DEBUG: Error al cargar análisis en \(analysisURL): \(error)")
                // Ignorar análisis que no se pueden cargar
                continue
            }
        }
        
        let sortedAnalyses = analyses.sorted { $0.timestamp > $1.timestamp }
        print("DEBUG: Total de análisis cargados: \(sortedAnalyses.count)")
        return sortedAnalyses
    }
    
    /// Elimina un análisis
    func deleteAnalysis(_ analysis: SoilAnalysis) async throws {
        let baseURL = try getCurrentBaseURL()
        let analysisDirectory = baseURL.appendingPathComponent(analysis.id.uuidString)
        
        guard directoryExists(at: analysisDirectory) else {
            throw StorageError.analysisNotFound
        }
        
        do {
            try FileManager.default.removeItem(at: analysisDirectory)
        } catch {
            throw StorageError.fileOperationFailed("No se pudo eliminar el análisis")
        }
        
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
            throw StorageError.fileOperationFailed(String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error)))
        }
    }
} 
