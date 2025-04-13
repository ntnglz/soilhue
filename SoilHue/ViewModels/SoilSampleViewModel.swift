//
//  SoilSampleViewModel.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//


import SwiftUI
import CoreLocation

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
    @Published var currentSample: SoilSample?
    
    /// Añade una nueva muestra de suelo a la colección.
    ///
    /// - Parameter image: Imagen capturada de la muestra de suelo.
    func addSample(image: UIImage) {
        let sample = SoilSample(image: image)
        samples.append(sample)
        currentSample = sample
    }
    
    /// Analiza una muestra de suelo para determinar su color Munsell.
    ///
    /// Este método es un placeholder que será implementado con la lógica
    /// de análisis de color usando la tabla Munsell.
    ///
    /// - Parameter sample: Muestra de suelo a analizar.
    func analyzeSample(_ sample: SoilSample) {
        // Aquí implementaremos el análisis del color
        // Por ahora solo es un placeholder
    }
}
