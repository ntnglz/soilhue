import SwiftUI
import MapKit

struct ImageAnalysisView: View {
    @ObservedObject var viewModel: SoilSampleViewModel
    @ObservedObject var colorAnalysisService: ColorAnalysisService
    let image: UIImage
    @Binding var selectionMode: SelectionMode
    let onNewSample: () -> Void
    
    @State private var selectionRect: CGRect?
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var showCalibration = false
    @State private var showHelp = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showingSaveDialog = false
    @State private var notes: String = ""
    @State private var tags: String = ""
    
    @State private var polygonPoints: [CGPoint]?
    @State private var isAnalyzing = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // Selector de modo
                    SelectionModePickerView(selectionMode: $selectionMode)
                        .padding(.horizontal)
                    
                    // Imagen y selección
                    ImageSelectionAreaView(
                        image: image,
                        selectionMode: selectionMode,
                        selectionRect: $selectionRect,
                        polygonPoints: $polygonPoints
                    )
                    .frame(height: 300)
                    
                    // Mapa con localización
                    if let sample = viewModel.currentSample,
                       let location = sample.location {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ubicación de la muestra")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            LocationView(location: location, region: $mapRegion)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Botón de análisis
                    AnalysisButtonView(
                        isAnalyzing: $isAnalyzing,
                        isEnabled: isAnalysisEnabled,
                        onAnalyze: analyze
                    )
                    .padding(.horizontal)
                    
                    // Resultados del análisis
                    if let sample = viewModel.currentSample,
                       let munsellColor = sample.munsellColor,
                       !munsellColor.isEmpty {
                        VStack(spacing: 16) {
                            Text("Resultados del Análisis")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Color Munsell: \(munsellColor)")
                                    .font(.title3)
                                
                                if let classification = sample.soilClassification {
                                    Text("Clasificación: \(classification)")
                                        .font(.title3)
                                }
                                
                                if let description = sample.soilDescription {
                                    Text("Descripción: \(description)")
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 15) {
                                Button(action: {
                                    showingSaveDialog = true
                                }) {
                                    Label("Guardar análisis", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                
                                HStack(spacing: 16) {
                                    Button(action: {
                                        showHelp = true
                                    }) {
                                        VStack {
                                            Image(systemName: "book.fill")
                                                .font(.title2)
                                            Text("Más\nInfor-\nmación")
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                        .foregroundColor(.blue)
                                    }
                                    
                                    Button(action: onNewSample) {
                                        VStack {
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                            Text("Nueva\nMues-\ntra")
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                        .id("results")
                    }
                }
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView(initialSection: 1)
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveAnalysisView(
                notes: $notes,
                tags: $tags,
                onSave: {
                    Task {
                        await saveAnalysis()
                    }
                }
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showCalibration) {
            CalibrationView()
        }
    }
    
    private var isAnalysisEnabled: Bool {
        switch selectionMode {
        case .rectangle:
            return selectionRect != nil
        case .polygon:
            return polygonPoints?.count ?? 0 >= 3
        case .full:
            return true
        }
    }
    
    private func analyze() {
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            
            do {
                // Asegurarse de que hay una muestra actual
                if viewModel.currentSample == nil {
                    viewModel.addSample(image: image)
                }
                
                guard let sample = viewModel.currentSample else { return }
                
                switch selectionMode {
                case .rectangle:
                    guard let rect = selectionRect else { return }
                    try await viewModel.analyzeSampleRegion(sample, region: rect)
                case .polygon:
                    guard let points = polygonPoints, points.count >= 3 else { return }
                    try await viewModel.analyzeSamplePolygon(sample, polygonPoints: points)
                case .full:
                    try await viewModel.analyzeSample(sample)
                }
                
                // Scroll to results after analysis
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        scrollProxy?.scrollTo("results", anchor: .top)
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func saveAnalysis() async {
        do {
            try await viewModel.saveSample(notes: notes, tags: tags.split(separator: ",").map(String.init))
            await MainActor.run {
                showingSaveDialog = false
                errorMessage = "Análisis guardado correctamente"
                showError = true
            }
            print("DEBUG: Análisis guardado correctamente")
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
            print("DEBUG: Error al guardar análisis: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ImageAnalysisView(
        viewModel: SoilSampleViewModel(),
        colorAnalysisService: ColorAnalysisService(),
        image: UIImage(),
        selectionMode: .constant(.rectangle),
        onNewSample: {}
    )
} 
