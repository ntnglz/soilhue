import Foundation
import SwiftUI

/// Servicio que proporciona funcionalidades para la clasificación de suelos según el sistema Munsell.
///
/// Este servicio:
/// - Convierte colores RGB a notación Munsell
/// - Proporciona información sobre la clasificación del suelo basada en el color Munsell
/// - Ofrece una interfaz para obtener el color Munsell más cercano a un color RGB dado
class MunsellClassificationService: ObservableObject {
    /// Estructura que representa un color Munsell con su clasificación de suelo.
    struct MunsellColor {
        /// Notación Munsell (ej. "10YR 6/4")
        let notation: String
        
        /// Nombre común del color (ej. "Yellowish Brown")
        let name: String
        
        /// Clasificación del suelo según el color
        let soilClassification: String
        
        /// Descripción del tipo de suelo
        let soilDescription: String
        
        /// Color RGB correspondiente
        let rgbColor: Color
    }
    
    /// Colores Munsell comunes para suelos con sus clasificaciones.
    let munsellColors: [MunsellColor] = [
        // Suelos oscuros (materia orgánica)
        MunsellColor(
            notation: "10YR 2/1",
            name: "Black",
            soilClassification: "Suelo orgánico",
            soilDescription: "Suelo con alto contenido en materia orgánica, típico de horizontes A o suelos de turba.",
            rgbColor: Color(red: 0.1, green: 0.1, blue: 0.1)
        ),
        MunsellColor(
            notation: "10YR 3/1",
            name: "Very Dark Gray",
            soilClassification: "Suelo orgánico",
            soilDescription: "Suelo con alto contenido en materia orgánica, típico de horizontes A.",
            rgbColor: Color(red: 0.2, green: 0.2, blue: 0.2)
        ),
        
        // Suelos marrones (materia orgánica y minerales)
        MunsellColor(
            notation: "10YR 3/2",
            name: "Very Dark Brown",
            soilClassification: "Suelo orgánico-mineral",
            soilDescription: "Suelo con contenido moderado-alto en materia orgánica, típico de horizontes A.",
            rgbColor: Color(red: 0.25, green: 0.2, blue: 0.15)
        ),
        MunsellColor(
            notation: "10YR 4/2",
            name: "Dark Brown",
            soilClassification: "Suelo orgánico-mineral",
            soilDescription: "Suelo con contenido moderado en materia orgánica, típico de horizontes A.",
            rgbColor: Color(red: 0.35, green: 0.3, blue: 0.25)
        ),
        MunsellColor(
            notation: "10YR 4/3",
            name: "Brown",
            soilClassification: "Suelo orgánico-mineral",
            soilDescription: "Suelo con contenido moderado en materia orgánica, típico de horizontes A.",
            rgbColor: Color(red: 0.4, green: 0.35, blue: 0.3)
        ),
        
        // Suelos marrones claros (minerales con algo de materia orgánica)
        MunsellColor(
            notation: "10YR 5/3",
            name: "Light Brown",
            soilClassification: "Suelo mineral",
            soilDescription: "Suelo con bajo contenido en materia orgánica, típico de horizontes B o C.",
            rgbColor: Color(red: 0.5, green: 0.45, blue: 0.4)
        ),
        MunsellColor(
            notation: "10YR 5/4",
            name: "Yellowish Brown",
            soilClassification: "Suelo mineral",
            soilDescription: "Suelo con bajo contenido en materia orgánica, típico de horizontes B o C.",
            rgbColor: Color(red: 0.55, green: 0.5, blue: 0.45)
        ),
        
        // Suelos rojizos (óxidos de hierro)
        MunsellColor(
            notation: "5YR 4/6",
            name: "Reddish Brown",
            soilClassification: "Suelo con óxidos de hierro",
            soilDescription: "Suelo con alto contenido en óxidos de hierro, típico de suelos tropicales o suelos muy meteorizados.",
            rgbColor: Color(red: 0.6, green: 0.3, blue: 0.2)
        ),
        MunsellColor(
            notation: "5YR 5/6",
            name: "Red",
            soilClassification: "Suelo con óxidos de hierro",
            soilDescription: "Suelo con alto contenido en óxidos de hierro, típico de suelos tropicales o suelos muy meteorizados.",
            rgbColor: Color(red: 0.7, green: 0.4, blue: 0.3)
        ),
        
        // Suelos amarillentos (minerales arcillosos)
        MunsellColor(
            notation: "2.5Y 6/4",
            name: "Light Yellowish Brown",
            soilClassification: "Suelo arcilloso",
            soilDescription: "Suelo con alto contenido en minerales arcillosos, típico de suelos aluviales o suelos de llanura.",
            rgbColor: Color(red: 0.7, green: 0.65, blue: 0.5)
        ),
        MunsellColor(
            notation: "2.5Y 7/4",
            name: "Pale Yellow",
            soilClassification: "Suelo arcilloso",
            soilDescription: "Suelo con alto contenido en minerales arcillosos, típico de suelos aluviales o suelos de llanura.",
            rgbColor: Color(red: 0.8, green: 0.75, blue: 0.6)
        ),
        
        // Suelos grises (reducción)
        MunsellColor(
            notation: "5Y 5/1",
            name: "Gray",
            soilClassification: "Suelo con reducción",
            soilDescription: "Suelo con signos de reducción, típico de suelos con drenaje deficiente o suelos hidromórficos.",
            rgbColor: Color(red: 0.5, green: 0.5, blue: 0.5)
        ),
        MunsellColor(
            notation: "5Y 6/1",
            name: "Light Gray",
            soilClassification: "Suelo con reducción",
            soilDescription: "Suelo con signos de reducción, típico de suelos con drenaje deficiente o suelos hidromórficos.",
            rgbColor: Color(red: 0.6, green: 0.6, blue: 0.6)
        ),
        
        // Suelos blancos (carbonatos)
        MunsellColor(
            notation: "10YR 8/1",
            name: "White",
            soilClassification: "Suelo con carbonatos",
            soilDescription: "Suelo con alto contenido en carbonatos, típico de suelos calcáreos o suelos con acumulación de sales.",
            rgbColor: Color(red: 0.9, green: 0.9, blue: 0.9)
        ),
        MunsellColor(
            notation: "10YR 7/1",
            name: "Light Gray",
            soilClassification: "Suelo con carbonatos",
            soilDescription: "Suelo con contenido en carbonatos, típico de suelos calcáreos o suelos con acumulación de sales.",
            rgbColor: Color(red: 0.8, green: 0.8, blue: 0.8)
        )
    ]
    
    /// Encuentra el color Munsell más cercano a un color RGB dado.
    ///
    /// - Parameters:
    ///   - red: Componente rojo del color RGB (0-1)
    ///   - green: Componente verde del color RGB (0-1)
    ///   - blue: Componente azul del color RGB (0-1)
    /// - Returns: El color Munsell más cercano
    func findClosestMunsellColor(red: Double, green: Double, blue: Double) -> MunsellColor {
        let targetColor = Color(red: red, green: green, blue: blue)
        
        // Encontrar el color más cercano usando la distancia euclidiana en el espacio RGB
        var closestColor = munsellColors[0]
        var minDistance = Double.infinity
        
        for color in munsellColors {
            let distance = colorDistance(color1: targetColor, color2: color.rgbColor)
            if distance < minDistance {
                minDistance = distance
                closestColor = color
            }
        }
        
        return closestColor
    }
    
    /// Calcula la distancia entre dos colores en el espacio RGB.
    ///
    /// - Parameters:
    ///   - color1: Primer color
    ///   - color2: Segundo color
    /// - Returns: Distancia euclidiana entre los colores
    private func colorDistance(color1: Color, color2: Color) -> Double {
        // Extraer componentes RGB
        let components1 = color1.cgColor?.components ?? [0, 0, 0, 1]
        let components2 = color2.cgColor?.components ?? [0, 0, 0, 1]
        
        // Calcular distancia euclidiana
        let rDiff = components1[0] - components2[0]
        let gDiff = components1[1] - components2[1]
        let bDiff = components1[2] - components2[2]
        
        return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff)
    }
    
    /// Convierte un color RGB a notación Munsell aproximada.
    ///
    /// - Parameters:
    ///   - red: Componente rojo del color RGB (0-1)
    ///   - green: Componente verde del color RGB (0-1)
    ///   - blue: Componente azul del color RGB (0-1)
    /// - Returns: Notación Munsell aproximada
    func rgbToMunsellNotation(red: Double, green: Double, blue: Double) -> String {
        let closestColor = findClosestMunsellColor(red: red, green: green, blue: blue)
        return closestColor.notation
    }
    
    /// Obtiene la clasificación del suelo basada en un color RGB.
    ///
    /// - Parameters:
    ///   - red: Componente rojo del color RGB (0-1)
    ///   - green: Componente verde del color RGB (0-1)
    ///   - blue: Componente azul del color RGB (0-1)
    /// - Returns: Clasificación del suelo
    func getSoilClassification(red: Double, green: Double, blue: Double) -> (classification: String, description: String) {
        let closestColor = findClosestMunsellColor(red: red, green: green, blue: blue)
        return (closestColor.soilClassification, closestColor.soilDescription)
    }
} 