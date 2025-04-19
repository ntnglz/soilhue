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
    @Published var correctionFactors: (red: Double, green: Double, blue: Double) = (1.0, 1.0, 1.0)
    
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
        ColorPatch(name: "dark skin", position: 0, referenceValues: (0.400, 0.350, 0.336)),
        ColorPatch(name: "light skin", position: 1, referenceValues: (0.713, 0.586, 0.524)),
        ColorPatch(name: "blue sky", position: 2, referenceValues: (0.247, 0.251, 0.378)),
        ColorPatch(name: "foliage", position: 3, referenceValues: (0.337, 0.422, 0.286)),
        ColorPatch(name: "blue flower", position: 4, referenceValues: (0.265, 0.240, 0.329)),
        ColorPatch(name: "bluish green", position: 5, referenceValues: (0.261, 0.343, 0.359)),
        
        // Segunda fila - Colores misceláneos
        ColorPatch(name: "orange", position: 6, referenceValues: (0.638, 0.445, 0.164)),
        ColorPatch(name: "purplish blue", position: 7, referenceValues: (0.242, 0.238, 0.475)),
        ColorPatch(name: "moderate red", position: 8, referenceValues: (0.449, 0.127, 0.127)),
        ColorPatch(name: "purple", position: 9, referenceValues: (0.288, 0.187, 0.292)),
        ColorPatch(name: "yellow green", position: 10, referenceValues: (0.491, 0.484, 0.169)),
        ColorPatch(name: "orange yellow", position: 11, referenceValues: (0.656, 0.484, 0.156)),
        
        // Tercera fila - Colores primarios y secundarios
        ColorPatch(name: "blue", position: 12, referenceValues: (0.153, 0.198, 0.558)),
        ColorPatch(name: "green", position: 13, referenceValues: (0.283, 0.484, 0.247)),
        ColorPatch(name: "red", position: 14, referenceValues: (0.558, 0.158, 0.147)),
        ColorPatch(name: "yellow", position: 15, referenceValues: (0.890, 0.798, 0.196)),
        ColorPatch(name: "magenta", position: 16, referenceValues: (0.558, 0.188, 0.372)),
        ColorPatch(name: "cyan", position: 17, referenceValues: (0.168, 0.302, 0.484)),
        
        // Cuarta fila - Escala de grises
        ColorPatch(name: "white", position: 18, referenceValues: (0.950, 0.950, 0.950)),
        ColorPatch(name: "neutral 8", position: 19, referenceValues: (0.773, 0.773, 0.773)),
        ColorPatch(name: "neutral 6.5", position: 20, referenceValues: (0.604, 0.604, 0.604)),
        ColorPatch(name: "neutral 5", position: 21, referenceValues: (0.422, 0.422, 0.422)),
        ColorPatch(name: "neutral 3.5", position: 22, referenceValues: (0.249, 0.249, 0.249)),
        ColorPatch(name: "black", position: 23, referenceValues: (0.104, 0.104, 0.104))
    ]
    
    /// Inicia el proceso de calibración
    func startCalibration() {
        calibrationState = .calibrating
    }
    
    /// Procesa una imagen de calibración y calcula los factores de corrección
    /// - Parameter image: Imagen de la tarjeta de calibración
    func processCalibrationImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            calibrationState = .error("No se pudo procesar la imagen")
            return
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        // Dimensiones de la imagen
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        
        // Asumimos una disposición 4x6 de la tarjeta ColorChecker
        let patchWidth = width / 6
        let patchHeight = height / 4
        
        var redCorrection = 0.0
        var greenCorrection = 0.0
        var blueCorrection = 0.0
        var validPatches = 0
        
        print("Iniciando procesamiento de calibración...")
        print("Dimensiones de la imagen: \(width)x\(height)")
        
        // Procesar cada parche
        for patch in colorCheckerPatches {
            let row = patch.position / 6
            let col = patch.position % 6
            
            let region = CGRect(
                x: CGFloat(col) * patchWidth,
                y: height - (CGFloat(row + 1) * patchHeight), // Invertido porque CoreImage usa coordenadas desde abajo
                width: patchWidth,
                height: patchHeight
            )
            
            // Obtener el color promedio del parche
            let measuredColor = getAverageColor(in: ciImage, region: region, context: context)
            
            print("Procesando parche \(patch.name):")
            print("  Referencia: R=\(patch.referenceValues.red), G=\(patch.referenceValues.green), B=\(patch.referenceValues.blue)")
            print("  Medido: R=\(measuredColor.red), G=\(measuredColor.green), B=\(measuredColor.blue)")
            
            // Calcular factores de corrección para este parche
            if measuredColor.red > 0 && measuredColor.green > 0 && measuredColor.blue > 0 {
                let redFactor = patch.referenceValues.red / measuredColor.red
                let greenFactor = patch.referenceValues.green / measuredColor.green
                let blueFactor = patch.referenceValues.blue / measuredColor.blue
                
                print("  Factores: R=\(redFactor), G=\(greenFactor), B=\(blueFactor)")
                
                redCorrection += redFactor
                greenCorrection += greenFactor
                blueCorrection += blueFactor
                validPatches += 1
            }
        }
        
        // Verificar que tengamos suficientes parches válidos
        guard validPatches > 0 else {
            calibrationState = .error("No se pudieron detectar suficientes parches de color")
            return
        }
        
        print("Total de parches válidos: \(validPatches)")
        
        // Calcular los factores de corrección promedio
        correctionFactors = (
            red: redCorrection / Double(validPatches),
            green: greenCorrection / Double(validPatches),
            blue: blueCorrection / Double(validPatches)
        )
        
        print("Factores de corrección finales:")
        print("R: \(correctionFactors.red)")
        print("G: \(correctionFactors.green)")
        print("B: \(correctionFactors.blue)")
        
        // Guardar los factores de corrección
        saveCalibrationFactors()
        calibrationState = .calibrated
    }
    
    /// Obtiene el color promedio en una región específica de la imagen
    private func getAverageColor(in image: CIImage, region: CGRect, context: CIContext) -> (red: Double, green: Double, blue: Double) {
        // Crear un filtro para recortar la región
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter?.setValue(image, forKey: kCIInputImageKey)
        cropFilter?.setValue(CIVector(cgRect: region), forKey: "inputRectangle")
        
        guard let croppedImage = cropFilter?.outputImage else {
            return (0, 0, 0)
        }
        
        // Obtener el color promedio
        let extentVector = CIVector(x: region.origin.x, y: region.origin.y, z: region.width, w: region.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: croppedImage,
            kCIInputExtentKey: extentVector
        ])
        
        guard let outputImage = filter?.outputImage else {
            return (0, 0, 0)
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
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
