import SwiftUI
import MapKit

struct ImageAnalysisView: View {
    let image: UIImage
    @Binding var selectionMode: SelectionMode
    @ObservedObject var viewModel: SoilSampleViewModel
    @ObservedObject var colorAnalysisService: ColorAnalysisService
    let onNewSample: () -> Void
    
    @State private var selectionRect: CGRect?
    @State private var polygonPoints: [CGPoint]?
    @State private var isAnalyzing = false
    @State private var munsellNotation: String = ""
    @State private var soilClassification: String = ""
    @State private var soilDescription: String = ""
    @State private var errorMessage: String? = nil
    @State private var showError = false
    @State private var showCalibration = false
    @State private var showHelp = false
    @State private var scrollProxy: ScrollViewProxy? = nil
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
                .padding(.vertical)
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView(initialSection: 1)
        }
        .alert("Error", isPresented: $showError) {
            Button("Calibrar", role: .none) {
                showCalibration = false
                showError = false
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Error desconocido")
        }
        .sheet(isPresented: $showCalibration) {
            CalibrationView()
        }
    }
    
    private var isAnalysisEnabled: Bool {
        !isAnalyzing && 
        ((selectionMode == .rectangle && selectionRect != nil) ||
         (selectionMode == .polygon && (polygonPoints?.count ?? 0) >= 3))
    }
    
    private func analyze() {
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            
            // Crear una nueva muestra si no existe
            if viewModel.currentSample == nil {
                viewModel.addSample(image: image)
            }
            
            do {
                let result = if selectionMode == .rectangle {
                    try await colorAnalysisService.analyzeImage(image, region: selectionRect)
                } else {
                    try await colorAnalysisService.analyzeImage(image, polygonPoints: polygonPoints)
                }
                
                await MainActor.run {
                    munsellNotation = result.munsellNotation
                    soilClassification = result.soilClassification
                    soilDescription = result.soilDescription
                    
                    // Actualizar la muestra actual
                    viewModel.currentSample?.munsellColor = result.munsellNotation
                    viewModel.currentSample?.soilClassification = result.soilClassification
                    viewModel.currentSample?.soilDescription = result.soilDescription
                    
                    // Hacer scroll a los resultados con animación
                    withAnimation {
                        scrollProxy?.scrollTo("results", anchor: .top)
                    }
                }
            } catch let error as CalibrationError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error al analizar la imagen: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
} 
