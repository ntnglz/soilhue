import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: Int
    let initialSection: Int
    
    init(initialSection: Int = 0) {
        _selectedSection = State(initialValue: initialSection)
        self.initialSection = initialSection
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker(NSLocalizedString("help.section", comment: "Section picker title"), selection: $selectedSection) {
                        Text(NSLocalizedString("help.section.intro", comment: "Introduction section")).tag(0)
                        Text(NSLocalizedString("help.section.calibration", comment: "Calibration section")).tag(1)
                        Text(NSLocalizedString("help.section.analysis", comment: "Analysis section")).tag(2)
                        Text(NSLocalizedString("help.section.data", comment: "Data section")).tag(3)
                        Text(NSLocalizedString("help.section.troubleshooting", comment: "Troubleshooting section")).tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    switch selectedSection {
                    case 0:
                        IntroductionSection()
                    case 1:
                        CalibrationSection()
                    case 2:
                        AnalysisSection()
                    case 3:
                        DataSection()
                    case 4:
                        TroubleshootingSection()
                    default:
                        IntroductionSection()
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("help.title", comment: "Help view title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("button.close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct IntroductionSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("help.intro.title", comment: "Introduction title"))
                .font(.title2)
                .bold()
            
            Text(NSLocalizedString("help.intro.description", comment: "Introduction description"))
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach([
                    "help.intro.feature.capture",
                    "help.intro.feature.calibration",
                    "help.intro.feature.analysis",
                    "help.intro.feature.export"
                ], id: \.self) { key in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(NSLocalizedString(key, comment: "Feature"))
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct CalibrationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Proceso de calibración
            GroupBox(label: Text(NSLocalizedString("help.calibration.process.title", comment: "Calibration process title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(1...6, id: \.self) { step in
                        HStack(alignment: .top) {
                            Text("\(step).")
                                .bold()
                            Text(NSLocalizedString("help.calibration.step.\(step)", comment: "Calibration step"))
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Limitaciones
            GroupBox(label: Text(NSLocalizedString("help.calibration.limitations.title", comment: "Limitations title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "help.calibration.limitation.basic",
                        "help.calibration.limitation.professional",
                        "help.calibration.limitation.lighting",
                        "help.calibration.limitation.recalibration"
                    ], id: \.self) { key in
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(NSLocalizedString(key, comment: "Limitation"))
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct AnalysisSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Captura de muestras
            GroupBox(label: Text(NSLocalizedString("help.analysis.capture.title", comment: "Sample capture title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(1...4, id: \.self) { step in
                        HStack(alignment: .top) {
                            Text("\(step).")
                                .bold()
                            Text(NSLocalizedString("help.analysis.step.\(step)", comment: "Analysis step"))
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Mejores prácticas
            GroupBox(label: Text(NSLocalizedString("help.analysis.practices.title", comment: "Best practices title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "help.analysis.practice.light",
                        "help.analysis.practice.shadows",
                        "help.analysis.practice.clean",
                        "help.analysis.practice.surface",
                        "help.analysis.practice.calibration"
                    ], id: \.self) { key in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text(NSLocalizedString(key, comment: "Practice"))
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct DataSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Guardar análisis
            GroupBox(label: Text(NSLocalizedString("help.data.save.title", comment: "Save analysis title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        HStack(alignment: .top) {
                            Text("\(step).")
                                .bold()
                            Text(NSLocalizedString("help.data.save.step.\(step)", comment: "Save step"))
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Exportar datos
            GroupBox(label: Text(NSLocalizedString("help.data.export.title", comment: "Export title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        HStack(alignment: .top) {
                            Text("\(step).")
                                .bold()
                            Text(NSLocalizedString("help.data.export.step.\(step)", comment: "Export step"))
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct TroubleshootingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Problemas comunes
            GroupBox(label: Text(NSLocalizedString("help.troubleshooting.problems.title", comment: "Common problems title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "help.troubleshooting.calibration",
                        "help.troubleshooting.results",
                        "help.troubleshooting.camera"
                    ], id: \.self) { key in
                        HStack(alignment: .top) {
                            Image(systemName: "wrench.fill")
                                .foregroundColor(.gray)
                            Text(NSLocalizedString(key, comment: "Problem"))
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Contacto
            GroupBox(label: Text(NSLocalizedString("help.contact.title", comment: "Contact title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("soilhue@ajgb.eu")
                    }
                    HStack {
                        Image(systemName: "globe")
                        Text("soilhue.ajgb.eu")
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

#Preview {
    HelpView()
} 