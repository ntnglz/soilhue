import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exportService = ExportService()
    @StateObject private var storageService: StorageService = {
        do {
            return try StorageService()
        } catch {
            fatalError("Error inicializando StorageService: \(error.localizedDescription)")
        }
    }()
    
    @State private var selectedFormat: ExportService.ExportFormat = .excel
    @State private var isExporting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Formato de Exportación")) {
                    Picker("Formato", selection: $selectedFormat) {
                        Text("Excel").tag(ExportService.ExportFormat.excel)
                        Text("CSV").tag(ExportService.ExportFormat.csv)
                        Text("JSON").tag(ExportService.ExportFormat.json)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: exportData) {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Exportar Datos")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isExporting)
                }
                
                Section(header: Text("Información")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Excel (.xlsx)")
                            .font(.headline)
                        Text("Formato compatible con Microsoft Excel y otras hojas de cálculo. Incluye formato y estilos.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("CSV (.csv)")
                            .font(.headline)
                        Text("Formato de texto simple separado por comas. Compatible con la mayoría de programas.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("JSON (.json)")
                            .font(.headline)
                        Text("Formato estructurado ideal para procesamiento de datos y desarrollo.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Exportar Datos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportData() {
        Task {
            isExporting = true
            do {
                let analyses = try await storageService.loadAllAnalyses()
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let exportURL = try await exportService.exportAnalyses(analyses, to: selectedFormat, baseURL: documentsDirectory)
                exportedFileURL = exportURL
                showShareSheet = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isExporting = false
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 