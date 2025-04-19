import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// Errores que pueden ocurrir durante el análisis de color
enum CalibrationError: LocalizedError {
    /// La cámara no está calibrada
    case notCalibrated
    
    var errorDescription: String? {
        switch self {
        case .notCalibrated:
            return "La cámara no está calibrada. Por favor, realice la calibración antes de analizar imágenes."
        }
    }
}

/// Servicio que analiza el color de una imagen o región específica.
///
/// Este servicio proporciona funcionalidades para:
/// - Extraer el color dominante de una imagen
/// - Analizar una región específica de una imagen
/// - Analizar un área poligonal de una imagen
/// - Convertir el color extraído a notación Munsell
/// - Proporcionar clasificación del suelo basada en el color
class ColorAnalysisService: ObservableObject {
    /// Indica si la cámara está calibrada
    @Published var isCalibrated: Bool = false
    
    /// Factores de corrección actuales para ajustar los valores RGB
    /// Estos factores se actualizan automáticamente cuando cambia la calibración
    @Published var correctionFactors = CorrectionFactors(red: 1.0, green: 1.0, blue: 1.0)
    
    /// Error de calibración actual, si existe
    @Published var calibrationError: Error?
    
    /// Contexto de CoreImage para procesamiento de imágenes.
    private let context = CIContext()
    
    /// Servicio de clasificación Munsell.
    private let munsellService = MunsellClassificationService()
    
    /// Servicio de calibración para ajustar los valores de color
    private let calibrationService = CalibrationService()
    
    init() {
        // Observar cambios en el servicio de calibración
        calibrationService.addObserver { [weak self] service in
            Task { @MainActor in
                self?.isCalibrated = service.isCalibrated
                self?.correctionFactors = service.correctionFactors
                self?.calibrationError = nil
            }
        }
        
        // Cargar el estado de calibración inicial
        Task { @MainActor in
                calibrationService.loadCalibrationFactors()
                isCalibrated = calibrationService.isCalibrated
                correctionFactors = calibrationService.correctionFactors
        }
    }
    
    /// Analiza una imagen y devuelve la clasificación Munsell y la descripción del suelo.
    /// - Parameters:
    ///   - image: Imagen a analizar
    ///   - region: Región rectangular a analizar (opcional)
    ///   - polygonPoints: Puntos del polígono a analizar (opcional)
    /// - Returns: Tupla con la notación Munsell, clasificación del suelo y descripción
    /// - Throws: CalibrationError si la cámara no está calibrada
    func analyzeImage(_ image: UIImage, region: CGRect? = nil, polygonPoints: [CGPoint]? = nil) async throws -> (munsellNotation: String, soilClassification: String, soilDescription: String) {
        // Verificar el estado de calibración
        guard isCalibrated else {
            throw CalibrationError.notCalibrated
        }
        
        // Obtener el color promedio de la región seleccionada
        let (red, green, blue) = await extractDominantColor(from: image, region: region, polygonPoints: polygonPoints)
        
        // Aplicar factores de calibración
        let calibratedColor = calibrationService.applyCalibration(red: red, green: green, blue: blue)
        
        // Obtener la clasificación Munsell
        let munsellNotation = munsellService.rgbToMunsellNotation(
            red: calibratedColor.red,
            green: calibratedColor.green,
            blue: calibratedColor.blue
        )
        
        // Obtener la clasificación del suelo
        let (classification, description) = munsellService.getSoilClassification(
            red: calibratedColor.red,
            green: calibratedColor.green,
            blue: calibratedColor.blue
        )
        
        return (munsellNotation, classification, description)
    }
    
    /// Extrae el color dominante de una imagen.
    ///
    /// - Parameters:
    ///   - image: La imagen de la que extraer el color
    ///   - region: Opcional. La región rectangular a analizar (en coordenadas normalizadas 0-1)
    ///   - polygonPoints: Opcional. Puntos que definen un polígono a analizar (en coordenadas normalizadas 0-1)
    /// - Returns: Una tupla con los componentes RGB del color dominante (valores entre 0 y 1)
    private func extractDominantColor(from image: UIImage, region: CGRect? = nil, polygonPoints: [CGPoint]? = nil) async -> (red: Double, green: Double, blue: Double) {
        guard let cgImage = image.cgImage else {
            return (0, 0, 0)
        }
        
        // Obtener las dimensiones de la imagen
        let width = cgImage.width
        let height = cgImage.height
        
        // Calcular los límites de píxeles a analizar
        var startX = 0
        var startY = 0
        var endX = width
        var endY = height
        
        // Si se proporciona una región, calcular los límites
        if let region = region {
            startX = Int(region.origin.x * CGFloat(width))
            startY = Int(region.origin.y * CGFloat(height))
            endX = Int((region.origin.x + region.size.width) * CGFloat(width))
            endY = Int((region.origin.y + region.size.height) * CGFloat(height))
            
            // Asegurarse de que la región sea válida
            startX = max(0, min(startX, width))
            startY = max(0, min(startY, height))
            endX = max(0, min(endX, width))
            endY = max(0, min(endY, height))
            
            // Si la región es demasiado pequeña, analizar toda la imagen
            if endX - startX < 10 || endY - startY < 10 {
                startX = 0
                startY = 0
                endX = width
                endY = height
            }
        }
        
        // Crear un contexto de color para acceder a los datos de píxeles
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (0, 0, 0)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Variables para acumular los valores RGB
        var totalRed: Double = 0
        var totalGreen: Double = 0
        var totalBlue: Double = 0
        var pixelCount = 0
        
        // Procesar los píxeles dentro de la región especificada
        for y in startY..<endY {
            for x in startX..<endX {
                // Si se proporcionan puntos de polígono, verificar si el píxel está dentro del polígono
                if let points = polygonPoints, !points.isEmpty {
                    // Convertir coordenadas de píxel a coordenadas normalizadas (0-1)
                    let normalizedX = Double(x) / Double(width)
                    let normalizedY = Double(y) / Double(height)
                    
                    // Verificar si el píxel está dentro del polígono
                    if !isPointInPolygon(point: CGPoint(x: normalizedX, y: normalizedY), polygon: points) {
                        continue
                    }
                }
                
                let byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                
                let red = Double(rawData[byteIndex]) / 255.0
                let green = Double(rawData[byteIndex + 1]) / 255.0
                let blue = Double(rawData[byteIndex + 2]) / 255.0
                
                // Ignorar píxeles completamente negros o blancos (posiblemente transparentes)
                if (red < 0.1 && green < 0.1 && blue < 0.1) || (red > 0.9 && green > 0.9 && blue > 0.9) {
                    continue
                }
                
                totalRed += red
                totalGreen += green
                totalBlue += blue
                pixelCount += 1
            }
        }
        
        // Si no se encontraron píxeles válidos, analizar toda la imagen
        if pixelCount == 0 {
            return await extractDominantColor(from: image)
        }
        
        // Calcular el promedio
        let avgRed = totalRed / Double(pixelCount)
        let avgGreen = totalGreen / Double(pixelCount)
        let avgBlue = totalBlue / Double(pixelCount)
        
        return (avgRed, avgGreen, avgBlue)
    }
    
    /// Verifica si un punto está dentro de un polígono usando el algoritmo "ray casting".
    ///
    /// - Parameters:
    ///   - point: El punto a verificar
    ///   - polygon: Array de puntos que definen el polígono
    /// - Returns: `true` si el punto está dentro del polígono, `false` en caso contrario
    private func isPointInPolygon(point: CGPoint, polygon: [CGPoint]) -> Bool {
        var inside = false
        var j = polygon.count - 1
        
        for i in 0..<polygon.count {
            if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) &&
                (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / (polygon[j].y - polygon[i].y) + polygon[i].x) {
                inside = !inside
            }
            j = i
        }
        
        return inside
    }
} 
