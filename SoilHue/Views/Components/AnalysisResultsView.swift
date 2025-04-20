import SwiftUI

struct AnalysisResultsView: View {
    // Datos del análisis
    let image: UIImage
    let munsellNotation: String
    let soilClassification: String
    let soilDescription: String
    let selectionArea: SelectionArea
    let wasCalibrated: Bool
    let correctionFactors: CorrectionFactors
    
    // Callback
    let onNewSample: () -> Void
    
    // Estado
    @State private var showHelp = false
    @State private var showSaveDialog = false
    @State private var selectedHelpSection = 1
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Servicios
    @StateObject private var storageService: StorageService = {
        do {
            return try StorageService()
        } catch {
            fatalError("Error inicializando StorageService: \(error.localizedDescription)")
        }
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // Título
            Text("Resultados del Análisis")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // Información del análisis
            VStack(alignment: .leading, spacing: 15) {
                ResultInfoRow(title: "Color Munsell", value: munsellNotation)
                ResultInfoRow(title: "Clasificación", value: soilClassification)
                ResultInfoRow(title: "Descripción", value: soilDescription)
            }
            .padding(.horizontal)
            
            Spacer(minLength: 20)
            
            // Botones de acción
            VStack(spacing: 12) {
                // Botón principal
                Button(action: { showSaveDialog = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Guardar Análisis")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Botones secundarios
                HStack(spacing: 12) {
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
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $showHelp) {
            HelpView(initialSection: selectedHelpSection)
        }
        .sheet(isPresented: $showSaveDialog) {
            SaveAnalysisSheet(isPresented: $showSaveDialog, onSave: saveAnalysis)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveAnalysis(notes: String, tags: String) {
        Task {
            do {
                // Crear el análisis
                let analysis = SoilAnalysis(
                    colorInfo: ColorInfo(
                        munsellNotation: munsellNotation,
                        soilClassification: soilClassification,
                        soilDescription: soilDescription,
                        correctedRGB: RGBValues(red: 0, green: 0, blue: 0) // TODO: Obtener valores reales
                    ),
                    imageInfo: ImageInfo(
                        imageURL: URL(fileURLWithPath: ""), // Se actualizará en el storage
                        selectionArea: selectionArea,
                        resolution: ImageResolution(
                            width: Int(image.size.width),
                            height: Int(image.size.height),
                            quality: .high
                        )
                    ),
                    calibrationInfo: CalibrationInfo(
                        wasCalibrated: wasCalibrated,
                        correctionFactors: correctionFactors,
                        lastCalibrationDate: Date()
                    ),
                    metadata: AnalysisMetadata(
                        location: nil, // TODO: Implementar localización
                        notes: notes.isEmpty ? nil : notes,
                        tags: tags.split(separator: ",").map(String.init),
                        environmentalConditions: nil // TODO: Implementar condiciones
                    )
                )
                
                // Guardar el análisis
                try await storageService.saveAnalysis(analysis, image: image)
                showSaveDialog = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct ResultInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

struct SaveAnalysisSheet: View {
    @Binding var isPresented: Bool
    let onSave: (String, String) -> Void
    
    @State private var notes = ""
    @State private var tags = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notas")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text("Etiquetas")) {
                    TextField("Separadas por comas", text: $tags)
                }
            }
            .navigationTitle("Guardar Análisis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(notes, tags)
                    }
                }
            }
        }
    }
} 