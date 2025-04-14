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
                    Picker("Sección", selection: $selectedSection) {
                        Text("General").tag(0)
                        Text("Suelos").tag(1)
                        Text("Horizontes").tag(2)
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
            .navigationTitle("Ayuda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpSection(
                title: "¿Qué es SoilHue?",
                content: "SoilHue es una aplicación diseñada para ayudar en la clasificación y análisis del color del suelo utilizando el sistema Munsell, un estándar internacional para la descripción del color."
            )
            
            helpSection(
                title: "¿Cómo funciona?",
                content: "1. Captura una foto del suelo o selecciona una existente\n2. Selecciona el área específica a analizar\n3. Obtén el color Munsell y la clasificación del suelo"
            )
            
            helpSection(
                title: "Consejos para mejores resultados",
                content: "• Toma las fotos con luz natural\n• Evita sombras y reflejos\n• Mantén la muestra limpia y seca\n• Usa una superficie plana"
            )
            
            helpSection(
                title: "Sistema Munsell",
                content: "El sistema Munsell describe el color usando tres componentes:\n• Matiz (hue): el color base\n• Valor (value): la luminosidad\n• Croma (chroma): la saturación"
            )
        }
    }
    
    private var soilTypesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpSection(
                title: "Tipos Principales de Suelo",
                content: """
                • Entisoles: Suelos jóvenes con poco desarrollo de horizontes
                • Inceptisoles: Suelos poco desarrollados con horizontes incipientes
                • Mollisoles: Suelos oscuros, fértiles, ricos en materia orgánica
                • Alfisoles: Suelos con horizonte de arcilla, fértiles
                • Ultisoles: Suelos ácidos, muy meteorizados
                • Oxisoles: Suelos muy meteorizados de regiones tropicales
                • Vertisoles: Suelos arcillosos que se agrietan
                • Aridisoles: Suelos de regiones áridas
                • Espodosoles: Suelos ácidos con acumulación de hierro
                • Histosoles: Suelos orgánicos (turbas)
                """
            )
            
            helpSection(
                title: "Características del Color",
                content: """
                • Rojo: Indica presencia de óxidos de hierro, buena aireación
                • Amarillo: Presencia de óxidos de hierro hidratados
                • Gris: Condiciones de reducción, mal drenaje
                • Negro/Marrón oscuro: Alto contenido en materia orgánica
                • Blanco: Presencia de carbonatos, sales o sílice
                """
            )
            
            helpSection(
                title: "Factores que Influyen",
                content: """
                • Materia orgánica
                • Minerales presentes
                • Contenido de humedad
                • Grado de oxidación
                • Actividad biológica
                """
            )
        }
    }
    
    private var horizonsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpSection(
                title: "Horizontes Principales",
                content: """
                • O - Horizonte orgánico: Restos vegetales en descomposición
                • A - Horizonte mineral superficial: Rico en materia orgánica
                • E - Horizonte de eluviación: Pérdida de materiales por lavado
                • B - Horizonte de iluviación: Acumulación de materiales
                • C - Material parental: Roca madre poco alterada
                • R - Roca madre: Material original sin alterar
                """
            )
            
            helpSection(
                title: "Horizonte A",
                content: """
                • A1: Mayor contenido de materia orgánica
                • A2: Transición, menos materia orgánica
                • A3: Transición al horizonte B
                
                Características:
                • Color oscuro por materia orgánica
                • Alta actividad biológica
                • Buena estructura del suelo
                """
            )
            
            helpSection(
                title: "Horizonte B",
                content: """
                • Bt: Acumulación de arcillas
                • Bs: Acumulación de sesquióxidos
                • Bh: Acumulación de humus
                • Bk: Acumulación de carbonatos
                
                Características:
                • Mayor desarrollo estructural
                • Colores más intensos
                • Menor contenido orgánico
                """
            )
            
            helpSection(
                title: "Importancia del Color",
                content: """
                El color es un indicador importante de:
                • Contenido de materia orgánica
                • Condiciones de drenaje
                • Procesos de oxidación-reducción
                • Presencia de minerales específicos
                • Historia del desarrollo del suelo
                """
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