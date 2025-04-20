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
            List {
                Section {
                    ForEach(0..<8) { index in
                        Button(action: {
                            selectedSection = index
                        }) {
                            HStack {
                                Text(sectionTitle(for: index))
                                    .foregroundColor(selectedSection == index ? .accentColor : .primary)
                                Spacer()
                                if selectedSection == index {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text(NSLocalizedString("help.section", comment: "Section picker title"))
                }
                
                Section {
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
                        MunsellSection()
                    case 5:
                        SoilTypesSection()
                    case 6:
                        SoilHorizonsSection()
                    case 7:
                        TroubleshootingSection()
                    default:
                        IntroductionSection()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
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
    
    private func sectionTitle(for index: Int) -> String {
        switch index {
        case 0:
            return NSLocalizedString("help.section.intro", comment: "Introduction section")
        case 1:
            return NSLocalizedString("help.section.calibration", comment: "Calibration section")
        case 2:
            return NSLocalizedString("help.section.analysis", comment: "Analysis section")
        case 3:
            return NSLocalizedString("help.section.data", comment: "Data section")
        case 4:
            return NSLocalizedString("help.section.munsell", comment: "Munsell section")
        case 5:
            return NSLocalizedString("help.section.soils", comment: "Soil types section")
        case 6:
            return NSLocalizedString("help.section.horizons", comment: "Soil horizons section")
        case 7:
            return NSLocalizedString("help.section.troubleshooting", comment: "Troubleshooting section")
        default:
            return ""
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

struct MunsellSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("help.munsell.title", comment: "Munsell system title"))
                .font(.title2)
                .bold()
            
            Text(NSLocalizedString("help.munsell.description", comment: "Munsell system description"))
                .fixedSize(horizontal: false, vertical: true)
            
            // Componentes del color
            GroupBox(label: Text(NSLocalizedString("help.munsell.components.title", comment: "Color components title")).bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([
                        "help.munsell.component.hue",
                        "help.munsell.component.value",
                        "help.munsell.component.chroma"
                    ], id: \.self) { key in
                        HStack(alignment: .top) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.blue)
                            Text(NSLocalizedString(key, comment: "Color component"))
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Notación
            GroupBox(label: Text(NSLocalizedString("help.munsell.notation.title", comment: "Notation title")).bold()) {
                Text(NSLocalizedString("help.munsell.notation.example", comment: "Notation example"))
                    .padding(.vertical)
            }
            
            // Importancia
            GroupBox(label: Text(NSLocalizedString("help.munsell.importance.title", comment: "Importance title")).bold()) {
                Text(NSLocalizedString("help.munsell.importance.text", comment: "Importance text"))
                    .padding(.vertical)
            }
        }
    }
}

struct SoilTypesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("help.soils.title", comment: "Soil types title"))
                .font(.title2)
                .bold()
            
            Text(NSLocalizedString("help.soils.description", comment: "Soil types description"))
                .fixedSize(horizontal: false, vertical: true)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach([
                        "histosols", "mollisols", "alfisols", "oxisols",
                        "vertisols", "spodosols", "aridisols", "entisols",
                        "inceptisols", "ultisols"
                    ], id: \.self) { soilType in
                        GroupBox(label: Text(NSLocalizedString("help.soils.\(soilType).title", comment: "Soil type title")).bold()) {
                            Text(NSLocalizedString("help.soils.\(soilType).description", comment: "Soil type description"))
                                .padding(.vertical)
                        }
                    }
                }
            }
        }
    }
}

struct SoilHorizonsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("help.horizons.title", comment: "Soil horizons title"))
                .font(.title2)
                .bold()
            
            Text(NSLocalizedString("help.horizons.description", comment: "Soil horizons description"))
                .fixedSize(horizontal: false, vertical: true)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(["o", "a", "e", "b", "c", "r"], id: \.self) { horizon in
                        GroupBox(label: Text(NSLocalizedString("help.horizons.\(horizon).title", comment: "Horizon title")).bold()) {
                            Text(NSLocalizedString("help.horizons.\(horizon).description", comment: "Horizon description"))
                                .padding(.vertical)
                        }
                    }
                    
                    GroupBox(label: Text(NSLocalizedString("help.horizons.importance.title", comment: "Importance title")).bold()) {
                        Text(NSLocalizedString("help.horizons.importance.text", comment: "Importance text"))
                            .padding(.vertical)
                    }
                }
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