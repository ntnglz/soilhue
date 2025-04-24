import SwiftUI
import CoreLocation
import MapKit

struct ResultView: View {
    let image: UIImage
    let location: CLLocation?
    let rgbValues: (red: Double, green: Double, blue: Double)
    let timestamp: Date
    
    @State private var showingSaveDialog = false
    @State private var notes = ""
    @State private var tags = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var region: MKCoordinateRegion?
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var analysisResult: (munsellNotation: String, soilClassification: String, soilDescription: String)?
    @State private var isAnalyzing = false
    
    @StateObject private var storageService: StorageService
    @StateObject private var colorAnalysisService = ColorAnalysisService()
    @Environment(\.dismiss) private var dismiss
    
    init(image: UIImage, location: CLLocation?, rgbValues: (red: Double, green: Double, blue: Double), timestamp: Date) {
        self.image = image
        self.location = location
        self.rgbValues = rgbValues
        self.timestamp = timestamp
        
        // Inicializar región del mapa si hay ubicación
        if let location = location {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            _region = State(initialValue: region)
        }
        
        // Inicializar StorageService de manera segura
        let service = try! StorageService()
        _storageService = StateObject(wrappedValue: service)
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                        
                        if isAnalyzing {
                            ProgressView(NSLocalizedString("analysis.analyzing", comment: "Analyzing progress"))
                                .padding()
                        } else if let result = analysisResult {
                            ResultInfoView(
                                munsellNotation: result.munsellNotation,
                                soilClassification: result.soilClassification,
                                soilDescription: result.soilDescription,
                                rgbValues: rgbValues
                            )
                            .id("results")
                        }
                        
                        if let location = location, let region = region {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(NSLocalizedString("analysis.location", comment: "Location section title"))
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if #available(iOS 17.0, *) {
                                    Map(position: .constant(MapCameraPosition.region(region))) {
                                        Marker(NSLocalizedString("analysis.location", comment: "Location marker"), coordinate: location.coordinate)
                                            .tint(.red)
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                } else {
                                    Map(coordinateRegion: .constant(region), annotationItems: [LocationPin(coordinate: location.coordinate)]) { pin in
                                        MapMarker(coordinate: pin.coordinate, tint: .red)
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                                
                                LocationDetailsView(location: location)
                            }
                        }
                        
                        VStack(spacing: 15) {
                            Button(action: {
                                showingSaveDialog = true
                            }) {
                                Label(NSLocalizedString("analysis.save", comment: "Save analysis button"), systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Label(NSLocalizedString("analysis.new.sample", comment: "New sample button"), systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.secondary.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .onAppear {
                    scrollProxy = proxy
                    analyzeImage()
                }
            }
            .navigationTitle(NSLocalizedString("analysis.results.title", comment: "Analysis results title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSaveDialog) {
                SaveAnalysisView(notes: $notes, tags: $tags) {
                    Task {
                        await saveAnalysis()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button(NSLocalizedString("button.ok", comment: "OK button"), role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func analyzeImage() {
        isAnalyzing = true
        
        Task {
            do {
                let result = try await colorAnalysisService.analyzeImage(image)
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                    
                    // Hacer scroll a los resultados con una pequeña animación
                    withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                        scrollProxy?.scrollTo("results", anchor: .center)
                    }
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    showAlert(title: NSLocalizedString("alert.error.title", comment: "Error alert title"), 
                             message: String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error)))
                }
            }
        }
    }
    
    private func saveAnalysis() async {
        do {
            guard let result = analysisResult else {
                throw NSError(domain: "SoilHue", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("analysis.error", comment: "Analysis error")])
            }
            
            let analysis = SoilAnalysis(
                id: UUID(),
                timestamp: Date(),
                imageData: image.jpegData(compressionQuality: 0.8) ?? Data(),
                notes: notes,
                tags: tags.split(separator: ",").map(String.init),
                locationInfo: location,
                munsellColor: result.munsellNotation,
                soilClassification: result.soilClassification,
                soilDescription: result.soilDescription,
                calibrationInfo: CalibrationInfo(
                    wasCalibrated: colorAnalysisService.isCalibrated,
                    correctionFactors: colorAnalysisService.correctionFactors,
                    lastCalibrationDate: Date()
                ),
                environmentalConditions: nil // TODO: Implementar condiciones
            )
            
            try await storageService.saveAnalysis(analysis, image: image)
            showingSaveDialog = false
            dismiss()
        } catch {
            showAlert(title: NSLocalizedString("alert.error.title", comment: "Error alert title"), 
                     message: String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error)))
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct LocationPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct LocationDetailsView: View {
    let location: CLLocation
    @State private var placemark: CLPlacemark?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let placemark = placemark {
                Text(formatAddress(from: placemark))
                    .font(.subheadline)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("analysis.latitude", comment: "Latitude label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.6f°", location.coordinate.latitude))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("analysis.longitude", comment: "Longitude label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.6f°", location.coordinate.longitude))
                        .font(.subheadline)
                }
            }
            
            if location.altitude != 0 {
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("analysis.altitude", comment: "Altitude label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f m", location.altitude))
                        .font(.subheadline)
                }
            }
            
            Text(String(format: NSLocalizedString("analysis.accuracy", comment: "Accuracy format"), location.horizontalAccuracy))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .task {
            await loadPlacemark()
        }
    }
    
    private func loadPlacemark() async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let firstPlacemark = placemarks.first {
                await MainActor.run {
                    placemark = firstPlacemark
                }
            }
        } catch {
            print("Error getting placemark: \(String(format: NSLocalizedString("error.generic", comment: "Generic error message format"), String(describing: error)))")
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

struct ResultInfoView: View {
    let munsellNotation: String
    let soilClassification: String
    let soilDescription: String
    let rgbValues: (red: Double, green: Double, blue: Double)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NSLocalizedString("Munsell Notation", comment: "Munsell notation label") + ":")
                .font(.headline)
            Text(munsellNotation)
            
            Text(NSLocalizedString("Soil Classification", comment: "Soil classification label") + ":")
                .font(.headline)
            Text(soilClassification)
            
            Text(NSLocalizedString("Description", comment: "Description label") + ":")
                .font(.headline)
            Text(soilDescription)
            
            Text("RGB:")
                .font(.headline)
            
            HStack(spacing: 20) {
                ColorValueView(label: "R", value: rgbValues.red, color: .red)
                ColorValueView(label: "G", value: rgbValues.green, color: .green)
                ColorValueView(label: "B", value: rgbValues.blue, color: .blue)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ColorValueView: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack {
            Text(label)
                .font(.headline)
                .foregroundColor(color)
            Text(String(format: "%.2f", value))
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SaveAnalysisView: View {
    @Binding var notes: String
    @Binding var tags: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Notes", comment: "Notes section header"))) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text(NSLocalizedString("Tags", comment: "Tags section header")), 
                        footer: Text(NSLocalizedString("Tags separated by commas", comment: "Tags section footer"))) {
                    TextField(NSLocalizedString("e.g. sample1, garden, clay", comment: "Tags placeholder"), text: $tags)
                }
            }
            .navigationTitle(NSLocalizedString("Save Analysis", comment: "Save analysis title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "Save button")) {
                        onSave()
                    }
                }
            }
        }
    }
}

#Preview {
    ResultView(
        image: UIImage(),
        location: CLLocation(latitude: 40.7128, longitude: -74.0060),
        rgbValues: (red: 0.5, green: 0.3, blue: 0.7),
        timestamp: Date()
    )
} 
