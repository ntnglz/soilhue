//
//  ResultView.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import SwiftUI

/// Vista para mostrar los resultados del análisis de una muestra de suelo.
///
/// Esta vista muestra:
/// - El color Munsell identificado
/// - La clasificación del suelo
/// - La descripción del suelo
/// - La imagen de la muestra analizada
/// - Opciones para compartir o guardar los resultados
///
/// Nota: Esta vista está pendiente de implementación.
struct ResultView: View {
    /// La muestra de suelo a analizar.
    let sample: SoilSample
    
    /// El color Munsell identificado.
    @State private var munsellColor: String = "Analizando..."
    
    /// La clasificación del suelo.
    @State private var soilClassification: String = ""
    
    /// La descripción del suelo.
    @State private var soilDescription: String = ""
    
    /// Indica si el análisis está en progreso.
    @State private var isAnalyzing = true
    
    /// Entorno que proporciona acceso a funciones de presentación.
    @Environment(\.dismiss) private var dismiss
    
    /// ViewModel que gestiona la lógica de las muestras de suelo.
    @StateObject private var viewModel = SoilSampleViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Imagen de la muestra
                    Image(uiImage: sample.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    
                    // Resultado del análisis
                    VStack(spacing: 15) {
                        // Color Munsell
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Color Munsell:")
                                .font(.headline)
                            
                            if isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text(munsellColor)
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Clasificación del suelo
                        if !soilClassification.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Clasificación del suelo:")
                                    .font(.headline)
                                
                                Text(soilClassification)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                
                                Text(soilDescription)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Botones de acción
                    HStack(spacing: 20) {
                        Button(action: shareResult) {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: saveResult) {
                            Label("Guardar", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Resultado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await analyzeColor()
        }
    }
    
    /// Analiza el color de la imagen para determinar el color Munsell.
    private func analyzeColor() async {
        do {
            let result = try await viewModel.analyzeSample(sample)
            munsellColor = result.munsellColor
            soilClassification = result.soilClassification
            soilDescription = result.soilDescription
        } catch {
            munsellColor = "Error en el análisis"
            print("Error analyzing color: \(error)")
        }
        isAnalyzing = false
    }
    
    /// Comparte el resultado del análisis.
    private func shareResult() {
        // TODO: Implementar la funcionalidad de compartir
    }
    
    /// Guarda el resultado del análisis.
    private func saveResult() {
        // TODO: Implementar la funcionalidad de guardar
    }
}

/// Vista previa para desarrollo y testing.
#Preview {
    ResultView(sample: SoilSample(
        image: UIImage(systemName: "photo")!,
        munsellColor: "10YR 4/3",
        soilClassification: "Suelo arcilloso",
        soilDescription: "Suelo con alto contenido de arcilla, color pardo oscuro"
    ))
}

