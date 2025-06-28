import Foundation

/// Estructura para los factores de corrección de color
public struct CorrectionFactors: Codable {
    let red: Double
    let green: Double
    let blue: Double
    
    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

