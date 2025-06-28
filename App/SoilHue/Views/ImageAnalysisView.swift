import SwiftUI
import MapKit
import PhotosUI

struct ImageAnalysisView: View {
    @StateObject var viewModel: SoilSampleViewModel
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var notes: String = ""
    @State private var tags: String = ""
    @State private var showingSaveAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @ObservedObject var colorAnalysisService: ColorAnalysisService
    let image: UIImage
    @Binding var selectionMode: SelectionMode
    let onNewSample: () -> Void
    
    @State private var selectionRect: CGRect?
    @State private var showCalibration = false
    @State private var showHelp = false
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showingSaveDialog = false
    @State private var polygonPoints: [CGPoint]?
    @State private var isAnalyzing = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var locationAnnotation: LocationAnnotation?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
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
                        .padding(.bottom, 40) // Espacio extra para la leyenda
                        
                        // Botón de análisis
                        AnalysisButtonView(
                            isAnalyzing: $isAnalyzing,
                            isEnabled: isAnalysisEnabled,
                            onAnalyze: analyze
                        )
                        .padding(.horizontal)
                        
                        if let locationInfo = viewModel.currentSample?.location {
                            Section(NSLocalizedString("analysis.location", comment: "Location section title")) {
                                LocationView(location: locationInfo)
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Label(String(format: NSLocalizedString("analysis.latitude", comment: "Latitude format"), locationInfo.coordinate.latitude), systemImage: "location.north.fill")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Label(String(format: NSLocalizedString("analysis.longitude", comment: "Longitude format"), locationInfo.coordinate.longitude), systemImage: "location.fill")
                                            .foregroundColor(.blue)
                                    }
                                    
                                    HStack {
                                        Label(String(format: NSLocalizedString("analysis.altitude", comment: "Altitude format"), locationInfo.altitude), systemImage: "arrow.up.forward")
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Label(String(format: NSLocalizedString("analysis.accuracy", comment: "Accuracy format"), locationInfo.horizontalAccuracy), systemImage: "scope")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .font(.caption)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Resultados del análisis
                        if let sample = viewModel.currentSample,
                           let munsellColor = sample.munsellColor,
                           !munsellColor.isEmpty {
                            AnalysisResultsView(
                                image: sample.image,
                                munsellNotation: munsellColor,
                                soilClassification: sample.soilClassification ?? "",
                                soilDescription: sample.soilDescription ?? "",
                                selectionArea: SelectionArea(
                                    type: .rectangle,
                                    coordinates: .rectangle(CGRect(x: 0, y: 0, width: 1, height: 1))
                                ),
                                wasCalibrated: colorAnalysisService.isCalibrated,
                                correctionFactors: colorAnalysisService.correctionFactors,
                                location: sample.location,
                                onNewSample: onNewSample
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .id("results")
                        }
                    }
                    .padding(.vertical, 24)
                }
                .onAppear {
                    scrollProxy = proxy
                    if let sample = viewModel.currentSample,
                       let location = sample.location {
                        mapRegion = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
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
            .alert(NSLocalizedString("analysis.error", comment: "Error alert title"), isPresented: $showingErrorAlert) {
                #if DEBUG
                // En modo DEBUG (simulador), no mostrar botón de calibración
                Button("OK", role: .cancel) { }
                #else
                // En modo RELEASE, mostrar botón de calibración
                Button(NSLocalizedString("analysis.calibrate.now", comment: "Calibrate now button")) {
                    showCalibration = true
                }
                Button("OK", role: .cancel) { }
                #endif
            } message: {
                Text(errorMessage)
            }
            .alert(NSLocalizedString("analysis.success", comment: "Success alert title"), isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(NSLocalizedString("analysis.saved", comment: "Analysis saved message"))
            }
            .sheet(isPresented: $showCalibration) {
                CalibrationView()
            }
        }
    }
    
    private var isAnalysisEnabled: Bool {
        // Siempre permitir el análisis
        return true
    }
    
    private func analyze() {
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            
            do {
                print("DEBUG: ImageAnalysisView - Iniciando análisis")
                print("DEBUG: ImageAnalysisView - currentSample: \(String(describing: viewModel.currentSample))")
                
                guard let sample = viewModel.currentSample else {
                    print("DEBUG: ImageAnalysisView - ERROR: currentSample es nil")
                    throw NSError(domain: "", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString("analysis.error.no.sample", comment: "No sample selected error")
                    ])
                }
                
                print("DEBUG: ImageAnalysisView - Muestra encontrada, procediendo con análisis")
                
                // Realizar el análisis según el modo de selección y si hay área seleccionada
                let result: SoilAnalysisResult
                switch selectionMode {
                case .rectangle:
                    if let rect = selectionRect {
                        print("DEBUG: ImageAnalysisView - Analizando región rectangular: \(rect)")
                        result = try await viewModel.analyzeSampleRegion(sample, region: rect)
                    } else {
                        print("DEBUG: ImageAnalysisView - Analizando imagen completa")
                        result = try await viewModel.analyzeSample(sample)
                    }
                case .polygon:
                    if let points = polygonPoints, points.count >= 3 {
                        print("DEBUG: ImageAnalysisView - Analizando polígono con \(points.count) puntos")
                        result = try await viewModel.analyzeSamplePolygon(sample, polygonPoints: points)
                    } else {
                        print("DEBUG: ImageAnalysisView - Analizando imagen completa (polígono inválido)")
                        result = try await viewModel.analyzeSample(sample)
                    }
                }
                
                print("DEBUG: ImageAnalysisView - Análisis completado exitosamente")
                
                // Actualizar la muestra actual con los resultados
                await MainActor.run {
                    viewModel.currentSample?.munsellColor = result.munsellColor
                    viewModel.currentSample?.soilClassification = result.soilClassification
                    viewModel.currentSample?.soilDescription = result.soilDescription
                    
                    // Scroll to results after analysis
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            scrollProxy?.scrollTo("results", anchor: .top)
                        }
                    }
                }
            } catch {
                print("DEBUG: ImageAnalysisView - ERROR durante análisis: \(error)")
                await MainActor.run {
                    errorMessage = String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error))
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func saveAnalysis() async {
        do {
            try await viewModel.saveSample(notes: notes, tags: tags.split(separator: ",").map(String.init))
            await MainActor.run {
                showingSaveDialog = false
                showingErrorAlert = false
                showingSaveAlert = true
            }
            print("DEBUG: Análisis guardado correctamente")
        } catch {
            await MainActor.run {
                errorMessage = String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error))
                showingErrorAlert = true
            }
            print("DEBUG: Error al guardar análisis: \(String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error)))")
        }
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let location: CLLocation
    
    var coordinate: CLLocationCoordinate2D {
        location.coordinate
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
