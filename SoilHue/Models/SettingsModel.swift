import Foundation

/// Modelo para gestionar los ajustes de la aplicación
class SettingsModel: ObservableObject {
    /// Claves para UserDefaults
    private enum Keys {
        static let cameraResolution = "cameraResolution"
        static let saveLocation = "saveLocation"
        static let autoCalibration = "autoCalibration"
        static let darkMode = "darkMode"
        static let exportFormat = "exportFormat"
    }
    
    /// Resolución de la cámara
    @Published var cameraResolution: CameraResolution {
        didSet {
            UserDefaults.standard.set(cameraResolution.rawValue, forKey: Keys.cameraResolution)
        }
    }
    
    /// Ubicación de guardado de las muestras
    @Published var saveLocation: SaveLocation {
        didSet {
            UserDefaults.standard.set(saveLocation.rawValue, forKey: Keys.saveLocation)
        }
    }
    
    /// Calibración automática al iniciar
    @Published var autoCalibration: Bool {
        didSet {
            UserDefaults.standard.set(autoCalibration, forKey: Keys.autoCalibration)
        }
    }
    
    /// Modo oscuro
    @Published var darkMode: DarkMode {
        didSet {
            UserDefaults.standard.set(darkMode.rawValue, forKey: Keys.darkMode)
        }
    }
    
    /// Formato de exportación
    @Published var exportFormat: ExportFormat {
        didSet {
            UserDefaults.standard.set(exportFormat.rawValue, forKey: Keys.exportFormat)
        }
    }
    
    init() {
        // Inicializar con valores guardados o por defecto
        self.cameraResolution = CameraResolution(rawValue: 
            UserDefaults.standard.integer(forKey: Keys.cameraResolution)) ?? .high
        self.saveLocation = SaveLocation(rawValue:
            UserDefaults.standard.integer(forKey: Keys.saveLocation)) ?? .local
        self.autoCalibration = UserDefaults.standard.bool(forKey: Keys.autoCalibration)
        self.darkMode = DarkMode(rawValue:
            UserDefaults.standard.integer(forKey: Keys.darkMode)) ?? .system
        self.exportFormat = ExportFormat(rawValue:
            UserDefaults.standard.integer(forKey: Keys.exportFormat)) ?? .csv
    }
    
    /// Restaura los ajustes a valores por defecto
    func resetToDefaults() {
        cameraResolution = .high
        saveLocation = .local
        autoCalibration = false
        darkMode = .system
        exportFormat = .csv
    }
}

/// Resolución de la cámara
enum CameraResolution: Int, CaseIterable, Identifiable, Codable {
    case low = 0
    case medium = 1
    case high = 2
    
    var id: Int { rawValue }
    
    var description: String {
        switch self {
        case .low: return "Baja (720p)"
        case .medium: return "Media (1080p)"
        case .high: return "Alta (4K)"
        }
    }
}

/// Ubicación de guardado
enum SaveLocation: Int, CaseIterable, Identifiable {
    case local = 0
    case iCloud = 1
    
    var id: Int { rawValue }
    
    var description: String {
        switch self {
        case .local: return "Almacenamiento Local"
        case .iCloud: return "iCloud"
        }
    }
}

/// Modo oscuro
enum DarkMode: Int, CaseIterable, Identifiable {
    case light = 0
    case dark = 1
    case system = 2
    
    var id: Int { rawValue }
    
    var description: String {
        switch self {
        case .light: return "Claro"
        case .dark: return "Oscuro"
        case .system: return "Sistema"
        }
    }
}

/// Formato de exportación
enum ExportFormat: Int, CaseIterable, Identifiable {
    case csv = 0
    case json = 1
    case excel = 2
    
    var id: Int { rawValue }
    
    var description: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .excel: return "Excel"
        }
    }
} 
