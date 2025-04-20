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
                        Text(NSLocalizedString("help.section.general", comment: "General section")).tag(0)
                        Text(NSLocalizedString("help.section.soils", comment: "Soils section")).tag(1)
                        Text(NSLocalizedString("help.section.horizons", comment: "Horizons section")).tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if selectedSection == 0 {
                        generalSection
                    } else if selectedSection == 1 {
                        soilTypesSection
                    } else {
                        horizonsSection
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
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpSection(
                title: NSLocalizedString("help.general.what.title", comment: "What is SoilHue title"),
                content: NSLocalizedString("help.general.what.content", comment: "What is SoilHue content")
            )
            
            helpSection(
                title: NSLocalizedString("help.general.how.title", comment: "How it works title"),
                content: NSLocalizedString("help.general.how.content", comment: "How it works content")
            )
            
            helpSection(
                title: NSLocalizedString("help.general.tips.title", comment: "Tips title"),
                content: NSLocalizedString("help.general.tips.content", comment: "Tips content")
            )
            
            helpSection(
                title: NSLocalizedString("help.general.munsell.title", comment: "Munsell system title"),
                content: NSLocalizedString("help.general.munsell.content", comment: "Munsell system content")
            )
        }
    }
    
    private var soilTypesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpSection(
                title: NSLocalizedString("help.soils.types.title", comment: "Main soil types title"),
                content: NSLocalizedString("help.soils.types.content", comment: "Main soil types content")
            )
            
            helpSection(
                title: NSLocalizedString("help.soils.color.title", comment: "Color characteristics title"),
                content: NSLocalizedString("help.soils.color.content", comment: "Color characteristics content")
            )
            
            helpSection(
                title: NSLocalizedString("help.soils.factors.title", comment: "Influencing factors title"),
                content: NSLocalizedString("help.soils.factors.content", comment: "Influencing factors content")
            )
        }
    }
    
    private var horizonsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpSection(
                title: NSLocalizedString("help.horizons.main.title", comment: "Main horizons title"),
                content: NSLocalizedString("help.horizons.main.content", comment: "Main horizons content")
            )
            
            helpSection(
                title: NSLocalizedString("help.horizons.a.title", comment: "A horizon title"),
                content: NSLocalizedString("help.horizons.a.content", comment: "A horizon content")
            )
            
            helpSection(
                title: NSLocalizedString("help.horizons.b.title", comment: "B horizon title"),
                content: NSLocalizedString("help.horizons.b.content", comment: "B horizon content")
            )
            
            helpSection(
                title: NSLocalizedString("help.horizons.color.title", comment: "Color importance title"),
                content: NSLocalizedString("help.horizons.color.content", comment: "Color importance content")
            )
        }
    }
    
    private func helpSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
} 