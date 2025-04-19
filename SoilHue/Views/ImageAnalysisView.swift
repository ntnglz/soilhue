import SwiftUI

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
    
    var body: some View {
        VStack {
            AnalysisButtonView(
                isAnalyzing: $isAnalyzing,
                isEnabled: isAnalysisEnabled,
                onAnalyze: analyze
            )
            .padding(.vertical)
            
            SelectionModePickerView(selectionMode: $selectionMode)
            
            ImageSelectionAreaView(
                image: image,
                selectionMode: selectionMode,
                selectionRect: $selectionRect,
                polygonPoints: $polygonPoints
            )
            
            if let sample = viewModel.currentSample,
               let munsellColor = sample.munsellColor,
               !munsellColor.isEmpty {
                AnalysisResultsView(
                    image: image,
                    munsellNotation: munsellColor,
                    soilClassification: soilClassification,
                    soilDescription: soilDescription,
                    selectionArea: SelectionArea(
                        type: selectionMode == .rectangle ? .rectangle : .polygon,
                        coordinates: selectionMode == .rectangle ? 
                            .rectangle(selectionRect ?? .zero) : 
                            .polygon(polygonPoints ?? [])
                    ),
                    wasCalibrated: colorAnalysisService.isCalibrated,
                    correctionFactors: colorAnalysisService.correctionFactors,
                    onNewSample: onNewSample
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("Calibrar", role: .none) {
                showCalibration = true
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
