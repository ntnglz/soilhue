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
    
    @State private var selectedFormat: ExportService.ExportFormat = .csv
    @State private var isExporting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Export Format", comment: "Export format section header"))) {
                    Picker(NSLocalizedString("Export Format", comment: "Export format picker"), selection: $selectedFormat) {
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
                            Text(NSLocalizedString("Export Data", comment: "Export data button"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isExporting)
                }
                
                Section(header: Text(NSLocalizedString("Information", comment: "Information section header"))) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CSV (.csv)")
                            .font(.headline)
                        Text(NSLocalizedString("export.format.csv.description", comment: "CSV format description"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Text("JSON (.json)")
                            .font(.headline)
                        Text(NSLocalizedString("export.format.json.description", comment: "JSON format description"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(NSLocalizedString("Export Data", comment: "Export view title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("button.close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
            .alert(NSLocalizedString("alert.error.title", comment: "Error alert title"), isPresented: $showError) {
                Button(NSLocalizedString("button.ok", comment: "OK button"), role: .cancel) { }
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