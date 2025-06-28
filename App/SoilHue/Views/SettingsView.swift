import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: SettingsModel
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Sección de Cámara
                Section(NSLocalizedString("Camera", comment: "Camera section title")) {
                    Picker(NSLocalizedString("Camera Resolution", comment: "Camera resolution picker"), selection: $model.cameraResolution) {
                        ForEach(CameraResolution.allCases) { resolution in
                            Text(NSLocalizedString(resolution.localizationKey, comment: "Camera resolution option"))
                                .tag(resolution)
                        }
                    }
                    
                    Toggle(NSLocalizedString("Auto Calibration", comment: "Auto calibration toggle"), isOn: $model.autoCalibration)
                }
                
                // Sección de Almacenamiento
                Section(NSLocalizedString("Storage Location", comment: "Storage section title")) {
                    Picker(NSLocalizedString("Storage Location", comment: "Storage location picker"), selection: $model.saveLocation) {
                        ForEach(SaveLocation.allCases) { location in
                            Text(NSLocalizedString(location.localizationKey, comment: "Storage location option"))
                                .tag(location)
                        }
                    }
                    
                    Picker(NSLocalizedString("Export Format", comment: "Export format picker"), selection: $model.exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(NSLocalizedString(format.localizationKey, comment: "Export format option"))
                                .tag(format)
                        }
                    }
                }
                
                // Sección de Apariencia
                Section(NSLocalizedString("Dark Mode", comment: "Appearance section title")) {
                    Picker(NSLocalizedString("Dark Mode", comment: "Dark mode picker"), selection: $model.darkMode) {
                        ForEach(DarkMode.allCases) { mode in
                            Text(NSLocalizedString(mode.localizationKey, comment: "Dark mode option"))
                                .tag(mode)
                        }
                    }
                }
                
                // Sección de Acciones
                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        HStack {
                            Text(NSLocalizedString("Reset to Defaults", comment: "Reset settings button"))
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Settings", comment: "Settings view title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
            .alert(NSLocalizedString("settings.reset.alert.title", comment: "Reset settings alert title"), isPresented: $showResetAlert) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) { }
                Button(NSLocalizedString("Reset", comment: "Reset button"), role: .destructive) {
                    model.resetToDefaults()
                }
            } message: {
                Text(NSLocalizedString("settings.reset.alert.message", comment: "Reset settings alert message"))
            }
        }
    }
}

#Preview {
    SettingsView(model: SettingsModel())
} 