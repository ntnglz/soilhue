//
//  SoilHueApp.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import SwiftUI

/// Punto de entrada principal de la aplicación SoilHue.
///
/// Esta estructura define la configuración inicial de la aplicación y su escena principal.
/// Actualmente, la aplicación muestra la vista de contenido principal (`ContentView`) en una ventana estándar.
@main
struct SoilHueApp: App {
    /// Define la escena principal de la aplicación.
    ///
    /// - Returns: Una escena que contiene la vista principal de la aplicación.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
