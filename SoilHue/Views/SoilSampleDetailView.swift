import SwiftUI

struct SoilSampleDetailView: View {
    @StateObject private var viewModel = SoilSampleViewModel()
    let sample: SoilSample
    @State private var isAnalyzing = false
    @State private var error: Error?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Imagen de la muestra
                Image(uiImage: sample.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                
                // Botón de análisis
                Button(action: {
                    Task {
                        await analyzeSample()
                    }
                }) {
                    HStack {
                        Image(systemName: "eyedropper")
                        Text("Analizar Muestra")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isAnalyzing)
                
                if isAnalyzing {
                    ProgressView("Analizando...")
                        .frame(maxWidth: .infinity)
                }
                
                if let error = error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Información del color Munsell
                VStack(alignment: .leading, spacing: 10) {
                    Text("Color Munsell")
                        .font(.headline)
                    Text(sample.munsellColor ?? "No analizado")
                        .font(.body)
                }
                
                // Clasificación del suelo
                if let classification = sample.soilClassification {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Clasificación del Suelo")
                            .font(.headline)
                        Text(classification)
                            .font(.body)
                    }
                }
                
                // Descripción del suelo
                if let description = sample.soilDescription {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Descripción")
                            .font(.headline)
                        Text(description)
                            .font(.body)
                    }
                }
                
                // Ubicación
                if let location = sample.location {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ubicación")
                            .font(.headline)
                        Text("Latitud: \(location.coordinate.latitude)")
                        Text("Longitud: \(location.coordinate.longitude)")
                    }
                }
                
                // Fecha de muestreo
                VStack(alignment: .leading, spacing: 10) {
                    Text("Fecha de Muestreo")
                        .font(.headline)
                    Text(sample.timestamp, style: .date)
                }
            }
            .padding()
        }
        .navigationTitle("Detalles de la Muestra")
    }
    
    private func analyzeSample() async {
        isAnalyzing = true
        error = nil
        
        do {
            _ = try await viewModel.analyzeSample(sample)
        } catch {
            self.error = error
        }
        
        isAnalyzing = false
    }
}

#Preview {
    SoilSampleDetailView(sample: SoilSample(
        image: UIImage(systemName: "photo")!,
        munsellColor: "10YR 4/3",
        soilClassification: "Suelo arcilloso",
        soilDescription: "Suelo con alto contenido de arcilla, color pardo oscuro"
    ))
} 
