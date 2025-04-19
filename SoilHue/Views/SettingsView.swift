import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: SettingsModel
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Sección de Cámara
                Section("Cámara") {
                    Picker("Resolución", selection: $model.cameraResolution) {
                        ForEach(CameraResolution.allCases) { resolution in
                            Text(resolution.description)
                                .tag(resolution)
                        }
                    }
                    
                    Toggle("Calibración automática", isOn: $model.autoCalibration)
                }
                
                // Sección de Almacenamiento
                Section("Almacenamiento") {
                    Picker("Ubicación", selection: $model.saveLocation) {
                        ForEach(SaveLocation.allCases) { location in
                            Text(location.description)
                                .tag(location)
                        }
                    }
                    
                    Picker("Formato de exportación", selection: $model.exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.description)
                                .tag(format)
                        }
                    }
                }
                
                // Sección de Apariencia
                Section("Apariencia") {
                    Picker("Modo oscuro", selection: $model.darkMode) {
                        ForEach(DarkMode.allCases) { mode in
                            Text(mode.description)
                                .tag(mode)
                        }
                    }
                }
                
                // Sección de Acciones
                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        HStack {
                            Text("Restablecer ajustes")
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
            .alert("¿Restablecer ajustes?", isPresented: $showResetAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Restablecer", role: .destructive) {
                    model.resetToDefaults()
                }
            } message: {
                Text("Esta acción restablecerá todos los ajustes a sus valores predeterminados.")
            }
        }
    }
}

#Preview {
    SettingsView(model: SettingsModel())
} 