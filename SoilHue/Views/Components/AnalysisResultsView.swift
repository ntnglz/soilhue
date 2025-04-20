import SwiftUI
import CoreLocation

struct AnalysisResultsView: View {
    // Datos del análisis
    let image: UIImage
    let munsellNotation: String
    let soilClassification: String
    let soilDescription: String
    let selectionArea: SelectionArea
    let wasCalibrated: Bool
    let correctionFactors: CorrectionFactors
    let location: CLLocation?
    
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
            Text(NSLocalizedString("analysis.results.title", comment: "Analysis results title"))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // Información del análisis
            VStack(alignment: .leading, spacing: 15) {
                ResultInfoRow(
                    title: NSLocalizedString("analysis.munsell.color", comment: "Munsell color label"),
                    value: munsellNotation
                )
                ResultInfoRow(
                    title: NSLocalizedString("analysis.classification", comment: "Classification label"),
                    value: soilClassification
                )
                ResultInfoRow(
                    title: NSLocalizedString("analysis.description", comment: "Description label"),
                    value: soilDescription
                )
            }
            .padding(.horizontal)
            
            Spacer(minLength: 20)
            
            // Botones de acción
            VStack(spacing: 12) {
                // Botón principal
                Button(action: { showSaveDialog = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text(NSLocalizedString("analysis.save", comment: "Save analysis button"))
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
                            Text(NSLocalizedString("analysis.more.info", comment: "More information button"))
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
                            Text(NSLocalizedString("analysis.new.sample", comment: "New sample button"))
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
        .alert(NSLocalizedString("error.title", comment: "Error alert title"), isPresented: $showError) {
            Button(NSLocalizedString("ok", comment: "OK button"), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveAnalysis(notes: String, tags: String) {
        Task {
            do {
                let locationInfo = location.map { LocationInfo(from: $0) }
                
                // Crear el análisis
                let analysis = SoilAnalysis(
                    id: UUID(),
                    timestamp: Date(),
                    imageData: image.jpegData(compressionQuality: 0.8) ?? Data(),
                    notes: notes,
                    tags: tags.split(separator: ",").map(String.init),
                    locationInfo: location,
                    munsellColor: munsellNotation,
                    soilClassification: soilClassification,
                    soilDescription: soilDescription,
                    calibrationInfo: CalibrationInfo(
                        wasCalibrated: wasCalibrated,
                        correctionFactors: correctionFactors,
                        lastCalibrationDate: Date()
                    ),
                    environmentalConditions: nil // TODO: Implementar condiciones
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
                Section(header: Text(NSLocalizedString("analysis.notes", comment: "Notes section header"))) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text(NSLocalizedString("analysis.tags", comment: "Tags section header"))) {
                    TextField(NSLocalizedString("analysis.tags.placeholder", comment: "Tags placeholder"), text: $tags)
                }
            }
            .navigationTitle(NSLocalizedString("analysis.save.title", comment: "Save analysis sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("save", comment: "Save button")) {
                        onSave(notes, tags)
                    }
                }
            }
        }
    }
} 
