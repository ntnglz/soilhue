import SwiftUI

struct AnalysisResultsView: View {
    let munsellNotation: String
    let soilClassification: String
    let soilDescription: String
    let onNewSample: () -> Void
    @State private var showHelp = false
    @State private var selectedHelpSection = 1 // Por defecto muestra la sección de suelos
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Resultados del Análisis")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Color Munsell: \(munsellNotation)")
                    .font(.subheadline)
                Text("Clasificación: \(soilClassification)")
                    .font(.subheadline)
                Text("Descripción: \(soilDescription)")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            HStack(spacing: 15) {
                Button(action: { 
                    selectedHelpSection = 1
                    showHelp = true 
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Más Información")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                Button(action: onNewSample) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Nueva Muestra")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.top)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showHelp) {
            HelpView(initialSection: selectedHelpSection)
        }
    }
} 