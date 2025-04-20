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
                        Text(NSLocalizedString("sample.analyze", comment: "Analyze sample button"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isAnalyzing)
                
                if isAnalyzing {
                    ProgressView(NSLocalizedString("sample.analyzing", comment: "Analyzing progress"))
                        .frame(maxWidth: .infinity)
                }
                
                if let error = error {
                    Text(String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error)))
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Información del color Munsell
                VStack(alignment: .leading, spacing: 10) {
                    Text(NSLocalizedString("sample.munsell.title", comment: "Munsell color title"))
                        .font(.headline)
                    Text(sample.munsellColor ?? NSLocalizedString("sample.not.analyzed", comment: "Not analyzed text"))
                        .font(.body)
                }
                
                // Clasificación del suelo
                if let classification = sample.soilClassification {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("sample.classification.title", comment: "Soil classification title"))
                            .font(.headline)
                        Text(classification)
                            .font(.body)
                    }
                }
                
                // Descripción del suelo
                if let description = sample.soilDescription {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("sample.description.title", comment: "Description title"))
                            .font(.headline)
                        Text(description)
                            .font(.body)
                    }
                }
                
                // Ubicación
                if let location = sample.location {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("sample.location.title", comment: "Location title"))
                            .font(.headline)
                        Text(String(format: NSLocalizedString("sample.latitude.format", comment: "Latitude format"), location.coordinate.latitude))
                        Text(String(format: NSLocalizedString("sample.longitude.format", comment: "Longitude format"), location.coordinate.longitude))
                    }
                }
                
                // Fecha de muestreo
                VStack(alignment: .leading, spacing: 10) {
                    Text(NSLocalizedString("sample.date.title", comment: "Sampling date title"))
                        .font(.headline)
                    Text(sample.timestamp, style: .date)
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("sample.details.title", comment: "Sample details title"))
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
        soilClassification: NSLocalizedString("preview.soil.classification", comment: "Preview soil classification"),
        soilDescription: NSLocalizedString("preview.soil.description", comment: "Preview soil description")
    ))
} 
