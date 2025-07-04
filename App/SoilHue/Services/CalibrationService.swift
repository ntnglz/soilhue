import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// Servicio que maneja la calibración de la cámara para el análisis de color del suelo.
///
/// Este servicio proporciona funcionalidades para:
/// - Calibrar la cámara usando una tarjeta de referencia de color
/// - Ajustar los valores de color para compensar las condiciones de iluminación
/// - Almacenar y cargar los parámetros de calibración
class CalibrationService: ObservableObject {
    /// Estado de la calibración
    enum CalibrationState: Equatable {
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
    @Published var correctionFactors: CorrectionFactors = CorrectionFactors(red: 1.0, green: 1.0, blue: 1.0)
    
    /// Fecha de la última calibración
    @Published var lastCalibrationDate: Date?
    
    /// Indica si la cámara está calibrada
    var isCalibrated: Bool {
        if case .calibrated = calibrationState {
            return true
        }
        return false
    }
    
    /// Lista de observadores del servicio
    private var observers: [(CalibrationService) -> Void] = []
    
    /// Añade un observador al servicio
    /// - Parameter observer: Closure que será llamado cuando haya cambios en el servicio
    func addObserver(_ observer: @escaping (CalibrationService) -> Void) {
        observers.append(observer)
        observer(self) // Notificar estado inicial
    }
    
    /// Notifica a todos los observadores de cambios en el servicio
    private func notifyObservers() {
        observers.forEach { observer in
            observer(self)
        }
    }
    
    /// Carga los factores de corrección desde UserDefaults
    func loadCalibrationFactors() {
        print("Debug - Cargando factores de calibración")
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "isCalibrated") {
            correctionFactors = CorrectionFactors(
                red: defaults.double(forKey: "calibrationRedFactor"),
                green: defaults.double(forKey: "calibrationGreenFactor"),
                blue: defaults.double(forKey: "calibrationBlueFactor")
            )
            lastCalibrationDate = defaults.object(forKey: "lastCalibrationDate") as? Date
            calibrationState = .calibrated
            print("Debug - Calibración cargada: Factores R=\(correctionFactors.red), G=\(correctionFactors.green), B=\(correctionFactors.blue)")
        } else {
            calibrationState = .notCalibrated
            lastCalibrationDate = nil
            print("Debug - No hay calibración guardada")
        }
        notifyObservers()
    }
    
    init() {
        loadCalibrationFactors()
    }
    
    /// Estructura que representa un parche de color en la tarjeta de calibración
    struct ColorPatch {
        let name: String
        let position: Int
        let referenceValues: (red: Double, green: Double, blue: Double)
    }
    
    /// Valores de referencia para la tarjeta X-Rite ColorChecker Classic
    /// Estos son los valores sRGB estandarizados para cada parche
    private let colorCheckerPatches: [ColorPatch] = [
        // Primera fila - Colores naturales
        ColorPatch(name: NSLocalizedString("calibration.patch.dark.skin", comment: "Dark skin patch name"), position: 0, referenceValues: (0.400, 0.350, 0.336)),
        ColorPatch(name: NSLocalizedString("calibration.patch.light.skin", comment: "Light skin patch name"), position: 1, referenceValues: (0.713, 0.586, 0.524)),
        ColorPatch(name: NSLocalizedString("calibration.patch.blue.sky", comment: "Blue sky patch name"), position: 2, referenceValues: (0.247, 0.251, 0.378)),
        ColorPatch(name: NSLocalizedString("calibration.patch.foliage", comment: "Foliage patch name"), position: 3, referenceValues: (0.337, 0.422, 0.286)),
        ColorPatch(name: NSLocalizedString("calibration.patch.blue.flower", comment: "Blue flower patch name"), position: 4, referenceValues: (0.265, 0.240, 0.329)),
        ColorPatch(name: NSLocalizedString("calibration.patch.bluish.green", comment: "Bluish green patch name"), position: 5, referenceValues: (0.261, 0.343, 0.359)),
        
        // Segunda fila - Colores misceláneos
        ColorPatch(name: NSLocalizedString("calibration.patch.orange", comment: "Orange patch name"), position: 6, referenceValues: (0.638, 0.445, 0.164)),
        ColorPatch(name: NSLocalizedString("calibration.patch.purplish.blue", comment: "Purplish blue patch name"), position: 7, referenceValues: (0.242, 0.238, 0.475)),
        ColorPatch(name: NSLocalizedString("calibration.patch.moderate.red", comment: "Moderate red patch name"), position: 8, referenceValues: (0.449, 0.127, 0.127)),
        ColorPatch(name: NSLocalizedString("calibration.patch.purple", comment: "Purple patch name"), position: 9, referenceValues: (0.288, 0.187, 0.292)),
        ColorPatch(name: NSLocalizedString("calibration.patch.yellow.green", comment: "Yellow green patch name"), position: 10, referenceValues: (0.491, 0.484, 0.169)),
        ColorPatch(name: NSLocalizedString("calibration.patch.orange.yellow", comment: "Orange yellow patch name"), position: 11, referenceValues: (0.656, 0.484, 0.156)),
        
        // Tercera fila - Colores primarios y secundarios
        ColorPatch(name: NSLocalizedString("calibration.patch.blue", comment: "Blue patch name"), position: 12, referenceValues: (0.153, 0.198, 0.558)),
        ColorPatch(name: NSLocalizedString("calibration.patch.green", comment: "Green patch name"), position: 13, referenceValues: (0.283, 0.484, 0.247)),
        ColorPatch(name: NSLocalizedString("calibration.patch.red", comment: "Red patch name"), position: 14, referenceValues: (0.558, 0.158, 0.147)),
        ColorPatch(name: NSLocalizedString("calibration.patch.yellow", comment: "Yellow patch name"), position: 15, referenceValues: (0.890, 0.798, 0.196)),
        ColorPatch(name: NSLocalizedString("calibration.patch.magenta", comment: "Magenta patch name"), position: 16, referenceValues: (0.558, 0.188, 0.372)),
        ColorPatch(name: NSLocalizedString("calibration.patch.cyan", comment: "Cyan patch name"), position: 17, referenceValues: (0.168, 0.302, 0.484)),
        
        // Cuarta fila - Escala de grises
        ColorPatch(name: NSLocalizedString("calibration.patch.white", comment: "White patch name"), position: 18, referenceValues: (0.950, 0.950, 0.950)),
        ColorPatch(name: NSLocalizedString("calibration.patch.neutral.8", comment: "Neutral 8 patch name"), position: 19, referenceValues: (0.773, 0.773, 0.773)),
        ColorPatch(name: NSLocalizedString("calibration.patch.neutral.6.5", comment: "Neutral 6.5 patch name"), position: 20, referenceValues: (0.604, 0.604, 0.604)),
        ColorPatch(name: NSLocalizedString("calibration.patch.neutral.5", comment: "Neutral 5 patch name"), position: 21, referenceValues: (0.422, 0.422, 0.422)),
        ColorPatch(name: NSLocalizedString("calibration.patch.neutral.3.5", comment: "Neutral 3.5 patch name"), position: 22, referenceValues: (0.249, 0.249, 0.249)),
        ColorPatch(name: NSLocalizedString("calibration.patch.black", comment: "Black patch name"), position: 23, referenceValues: (0.104, 0.104, 0.104))
    ]
    
    /// Inicia el proceso de calibración
    func startCalibration() {
        calibrationState = .calibrating
    }
    
    /// Procesa una imagen de calibración y calcula los factores de corrección
    /// - Parameter image: Imagen de la tarjeta de calibración
    func processCalibrationImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            calibrationState = .error(NSLocalizedString("calibration.error.image.processing", comment: "Error processing calibration image"))
            return
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        // Dimensiones de la imagen
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        
        print("Debug - Dimensiones de la imagen: \(width)x\(height)")
        
        // Asumimos una disposición 4x6 de la tarjeta ColorChecker
        let patchWidth = width / 6
        let patchHeight = height / 4
        
        var redCorrection = 0.0
        var greenCorrection = 0.0
        var blueCorrection = 0.0
        var validPatches = 0
        var totalPatches = 0
        
        print(NSLocalizedString("calibration.log.start", comment: "Starting calibration processing"))
        print(String(format: NSLocalizedString("calibration.log.dimensions", comment: "Image dimensions log"), width, height))
        
        // Procesar cada parche
        for patch in colorCheckerPatches {
            totalPatches += 1
            let row = patch.position / 6
            let col = patch.position % 6
            
            // Calcular las coordenadas del parche
            let margin = min(patchWidth, patchHeight) * 0.2 // 20% de margen
            let x = CGFloat(col) * patchWidth + margin
            let y = CGFloat(row) * patchHeight + margin
            
            let region = CGRect(
                x: x,
                y: y,
                width: patchWidth - (margin * 2),
                height: patchHeight - (margin * 2)
            )
            
            print("Debug - Procesando parche \(patch.name) en región: \(region)")
            
            // Obtener el color promedio del parche
            let measuredColor = getAverageColor(in: ciImage, region: region, context: context)
            
            print(String(format: NSLocalizedString("calibration.log.patch", comment: "Processing patch log"), patch.name))
            print(String(format: NSLocalizedString("calibration.log.reference", comment: "Reference values log"), patch.referenceValues.red, patch.referenceValues.green, patch.referenceValues.blue))
            print(String(format: NSLocalizedString("calibration.log.measured", comment: "Measured values log"), measuredColor.red, measuredColor.green, measuredColor.blue))
            
            // Calcular factores de corrección para este parche si los valores son válidos
            if measuredColor.red > 0.05 && measuredColor.green > 0.05 && measuredColor.blue > 0.05 &&
               measuredColor.red < 0.95 && measuredColor.green < 0.95 && measuredColor.blue < 0.95 {
                let redFactor = patch.referenceValues.red / measuredColor.red
                let greenFactor = patch.referenceValues.green / measuredColor.green
                let blueFactor = patch.referenceValues.blue / measuredColor.blue
                
                // Verificar que los factores estén dentro de rangos razonables
                if redFactor > 0.1 && redFactor < 10.0 &&
                   greenFactor > 0.1 && greenFactor < 10.0 &&
                   blueFactor > 0.1 && blueFactor < 10.0 {
                    print(String(format: NSLocalizedString("calibration.log.factors", comment: "Correction factors log"), redFactor, greenFactor, blueFactor))
                    
                    redCorrection += redFactor
                    greenCorrection += greenFactor
                    blueCorrection += blueFactor
                    validPatches += 1
                }
            }
        }
        
        print("Total patches processed: \(totalPatches)")
        print("Valid patches found: \(validPatches)")
        
        // Verificar que tengamos suficientes parches válidos (al menos 25% de los parches)
        let minimumValidPatches = Int(Double(totalPatches) * 0.25)
        guard validPatches >= minimumValidPatches else {
            calibrationState = .error(NSLocalizedString("calibration.error.insufficient.patches", comment: "Error insufficient color patches"))
            return
        }
        
        print(String(format: NSLocalizedString("calibration.log.valid.patches", comment: "Valid patches count log"), validPatches))
        
        // Calcular los factores de corrección promedio
        correctionFactors = CorrectionFactors(
            red: redCorrection / Double(validPatches),
            green: greenCorrection / Double(validPatches),
            blue: blueCorrection / Double(validPatches)
        )
        
        // Guardar los factores de corrección
        saveCalibrationFactors()
        
        // Actualizar el estado
        calibrationState = .calibrated
        lastCalibrationDate = Date()
        notifyObservers()
    }
    
    /// Guarda los factores de corrección en UserDefaults
    private func saveCalibrationFactors() {
        print("Debug - Guardando factores de calibración")
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "isCalibrated")
        defaults.set(correctionFactors.red, forKey: "calibrationRedFactor")
        defaults.set(correctionFactors.green, forKey: "calibrationGreenFactor")
        defaults.set(correctionFactors.blue, forKey: "calibrationBlueFactor")
        defaults.set(lastCalibrationDate, forKey: "lastCalibrationDate")
        defaults.synchronize()
        print("Debug - Calibración guardada: Factores R=\(correctionFactors.red), G=\(correctionFactors.green), B=\(correctionFactors.blue)")
    }
    
    /// Obtiene el color promedio de una región de la imagen
    /// - Parameters:
    ///   - image: Imagen de la que obtener el color
    ///   - region: Región de la imagen a analizar
    ///   - context: Contexto de CoreImage
    /// - Returns: Color promedio en formato RGB
    private func getAverageColor(in image: CIImage, region: CGRect, context: CIContext) -> (red: Double, green: Double, blue: Double) {
        // Crear un filtro para recortar la región
        let croppedImage = image.cropped(to: region)
        
        // Usar CIAreaAverage para obtener el color promedio
        let filter = CIFilter.areaAverage()
        filter.inputImage = croppedImage
        filter.extent = croppedImage.extent
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("Error: No se pudo crear la imagen de salida")
            return (0, 0, 0)
        }
        
        let dataProvider = cgImage.dataProvider
        guard let data = dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            print("Error: No se pudieron obtener los datos de la imagen")
            return (0, 0, 0)
        }
        
        let red = Double(bytes[0]) / 255.0
        let green = Double(bytes[1]) / 255.0
        let blue = Double(bytes[2]) / 255.0
        
        print("Debug - Color promedio obtenido: R=\(red), G=\(green), B=\(blue)")
        
        return (red, green, blue)
    }
    
    /// Aplica los factores de corrección a una imagen
    /// - Parameter image: Imagen a corregir
    /// - Returns: Imagen corregida
    func applyCorrection(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        // Crear un filtro de matriz de color para aplicar los factores de corrección
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = ciImage
        colorMatrix.rVector = CIVector(x: CGFloat(correctionFactors.red), y: 0, z: 0, w: 0)
        colorMatrix.gVector = CIVector(x: 0, y: CGFloat(correctionFactors.green), z: 0, w: 0)
        colorMatrix.bVector = CIVector(x: 0, y: 0, z: CGFloat(correctionFactors.blue), w: 0)
        colorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        
        guard let outputImage = colorMatrix.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Aplica los factores de corrección a un color RGB
    /// - Parameters:
    ///   - red: Componente rojo (0-1)
    ///   - green: Componente verde (0-1)
    ///   - blue: Componente azul (0-1)
    /// - Returns: Color RGB corregido
    func applyCalibration(red: Double, green: Double, blue: Double) -> (red: Double, green: Double, blue: Double) {
        #if DEBUG
        // En modo DEBUG (simulador), usar factores de corrección por defecto si no está calibrado
        if !isCalibrated {
            print("Debug - Modo DEBUG: Usando factores de corrección por defecto")
            return (red, green, blue)
        }
        #else
        // En modo RELEASE, requerir calibración
        guard isCalibrated else {
            return (red, green, blue)
        }
        #endif
        
        let correctedRed = min(1.0, max(0.0, red * correctionFactors.red))
        let correctedGreen = min(1.0, max(0.0, green * correctionFactors.green))
        let correctedBlue = min(1.0, max(0.0, blue * correctionFactors.blue))
        
        return (correctedRed, correctedGreen, correctedBlue)
    }
} 
