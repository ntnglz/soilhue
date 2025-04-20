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
                        Section("Ubicación") {
                            LocationView(location: locationInfo)
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label("Latitud: \(locationInfo.coordinate.latitude, specifier: "%.6f")°", systemImage: "location.north.fill")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Label("Longitud: \(locationInfo.coordinate.longitude, specifier: "%.6f")°", systemImage: "location.fill")
                                        .foregroundColor(.blue)
                                }
                                
                                HStack {
                                    Label("Altitud: \(locationInfo.altitude, specifier: "%.1f") m", systemImage: "arrow.up.forward")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Label("Precisión: \(locationInfo.horizontalAccuracy, specifier: "%.1f") m", systemImage: "scope")
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
                        VStack(spacing: 24) {
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
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Botones de acción
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
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal)
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
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("Calibrar ahora") {
                showCalibration = true
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Éxito", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Análisis guardado correctamente")
        }
        .sheet(isPresented: $showCalibration) {
            CalibrationView()
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
                guard let sample = viewModel.currentSample else { return }
                
                // Realizar el análisis según el modo de selección y si hay área seleccionada
                let result: SoilAnalysisResult
                switch selectionMode {
                case .rectangle:
                    if let rect = selectionRect {
                        result = try await viewModel.analyzeSampleRegion(sample, region: rect)
                    } else {
                        // Si no hay selección, analizar la imagen completa
                        result = try await viewModel.analyzeSample(sample)
                    }
                case .polygon:
                    if let points = polygonPoints, points.count >= 3 {
                        result = try await viewModel.analyzeSamplePolygon(sample, polygonPoints: points)
                    } else {
                        // Si no hay selección válida, analizar la imagen completa
                        result = try await viewModel.analyzeSample(sample)
                    }
                }
                
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
                errorMessage = error.localizedDescription
                showingErrorAlert = true
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
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
            print("DEBUG: Error al guardar análisis: \(error.localizedDescription)")
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
