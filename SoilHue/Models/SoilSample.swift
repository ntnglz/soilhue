//
//  SoilSample.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import SwiftUI
import CoreLocation

/// Representa una muestra de suelo capturada por la aplicación.
///
/// Una muestra de suelo contiene la imagen capturada, su ubicación geográfica (opcional),
/// y el color Munsell correspondiente (opcional). Cada muestra tiene un identificador único
/// y una marca de tiempo de cuando fue capturada.
struct SoilSample: Identifiable {
    /// Identificador único de la muestra.
    let id = UUID()
    
    /// Imagen capturada de la muestra de suelo.
    let image: UIImage
    
    /// Fecha y hora en que se capturó la muestra.
    let timestamp: Date
    
    /// Ubicación geográfica donde se capturó la muestra (opcional).
    var location: CLLocation?
    
    /// Color Munsell correspondiente a la muestra (opcional).
    var munsellColor: String?
    
    /// Clasificación del suelo basada en el color Munsell (opcional).
    var soilClassification: String?
    
    /// Descripción detallada del tipo de suelo (opcional).
    var soilDescription: String?
    
    /// Crea una nueva muestra de suelo.
    ///
    /// - Parameters:
    ///   - image: Imagen capturada de la muestra de suelo.
    ///   - location: Ubicación geográfica donde se capturó la muestra (opcional).
    ///   - munsellColor: Color Munsell correspondiente a la muestra (opcional).
    ///   - soilClassification: Clasificación del suelo basada en el color Munsell (opcional).
    ///   - soilDescription: Descripción detallada del tipo de suelo (opcional).
    init(image: UIImage,
         location: CLLocation? = nil,
         munsellColor: String? = nil,
         soilClassification: String? = nil,
         soilDescription: String? = nil) {
        self.image = image
        self.timestamp = Date()
        self.location = location
        self.munsellColor = munsellColor
        self.soilClassification = soilClassification
        self.soilDescription = soilDescription
    }
}
