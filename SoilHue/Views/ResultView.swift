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
    
    @StateObject private var storageService: StorageService
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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    
                    ResultInfoView(rgbValues: rgbValues)
                    
                    if let location = location, let region = region {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ubicación de la muestra")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Map(coordinateRegion: .constant(region), annotationItems: [LocationPin(coordinate: location.coordinate)]) { pin in
                                MapMarker(coordinate: pin.coordinate, tint: .red)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            LocationDetailsView(location: location)
                        }
                    }
                    
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
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Label("Nueva muestra", systemImage: "camera")
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
            .navigationTitle("Resultados")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSaveDialog) {
                SaveAnalysisView(notes: $notes, tags: $tags) {
                    Task {
                        await saveAnalysis()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveAnalysis() async {
        print("DEBUG: Iniciando saveAnalysis")
        print("DEBUG: Location recibido: \(String(describing: location))")
        if let loc = location {
            print("DEBUG: Coordenadas - lat: \(loc.coordinate.latitude), lon: \(loc.coordinate.longitude)")
            print("DEBUG: Altitud: \(loc.altitude), Precisión H: \(loc.horizontalAccuracy), Precisión V: \(loc.verticalAccuracy)")
        }
        
        do {
            let locationInfo = location.map { LocationInfo(from: $0) }
            print("DEBUG: LocationInfo creado: \(String(describing: locationInfo))")
            if let info = locationInfo {
                print("DEBUG: LocationInfo detalles - lat: \(info.latitude), lon: \(info.longitude)")
            }
            
            let analysis = SoilAnalysis(
                colorInfo: ColorInfo(
                    munsellNotation: "10YR 4/3", // TODO: Obtener valor real
                    soilClassification: "Mollisoles", // TODO: Obtener valor real
                    soilDescription: "Suelo oscuro y fértil, con contenido moderado en materia orgánica", // TODO: Obtener valor real
                    correctedRGB: RGBValues(
                        red: rgbValues.red,
                        green: rgbValues.green,
                        blue: rgbValues.blue
                    )
                ),
                imageInfo: ImageInfo(
                    imageURL: URL(fileURLWithPath: ""), // Se actualizará en el storage
                    selectionArea: SelectionArea(
                        type: .rectangle,
                        coordinates: .rectangle(CGRect(x: 0, y: 0, width: 1, height: 1))
                    ),
                    resolution: ImageResolution(
                        width: Int(image.size.width),
                        height: Int(image.size.height),
                        quality: .high
                    )
                ),
                calibrationInfo: CalibrationInfo(
                    wasCalibrated: true, // TODO: Obtener valor real
                    correctionFactors: CorrectionFactors(red: 1, green: 1, blue: 1), // TODO: Obtener valor real
                    lastCalibrationDate: Date()
                ),
                metadata: AnalysisMetadata(
                    location: locationInfo,
                    notes: notes.isEmpty ? nil : notes,
                    tags: tags.split(separator: ",").map(String.init),
                    environmentalConditions: nil // TODO: Implementar condiciones
                )
            )
            
            try await storageService.saveAnalysis(analysis, image: image)
            showingSaveDialog = false
            dismiss()
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
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
                    Text("Latitud")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.6f°", location.coordinate.latitude))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Longitud")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.6f°", location.coordinate.longitude))
                        .font(.subheadline)
                }
            }
            
            if location.altitude != 0 {
                VStack(alignment: .leading) {
                    Text("Altitud")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f m", location.altitude))
                        .font(.subheadline)
                }
            }
            
            Text("Precisión: \(String(format: "±%.0f m", location.horizontalAccuracy))")
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
            print("Error getting placemark: \(error.localizedDescription)")
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
    let rgbValues: (red: Double, green: Double, blue: Double)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Valores RGB:")
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
                Section(header: Text("Notas")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text("Etiquetas"), footer: Text("Separadas por comas")) {
                    TextField("ej: muestra1, jardín, arcilloso", text: $tags)
                }
            }
            .navigationTitle("Guardar análisis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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