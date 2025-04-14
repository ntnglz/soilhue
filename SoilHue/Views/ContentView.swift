//
//  ContentView.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

// ContentView.swift
import SwiftUI
import PhotosUI

/// Modo de selección de área.
enum SelectionMode {
    case rectangle
    case polygon
}

/// Vista principal de la aplicación SoilHue.
///
/// Esta vista proporciona la interfaz principal para:
/// - Mostrar la imagen de la muestra de suelo seleccionada
/// - Permitir la captura de imágenes con la cámara
/// - Permitir la selección de imágenes desde la galería
/// - Gestionar el estado de la muestra actual
///
/// La vista integra la cámara y el selector de fotos, manteniendo
/// el estado de la imagen seleccionada y el ViewModel de la muestra.
struct ContentView: View {
    /// ViewModel que gestiona la lógica de las muestras de suelo.
    @StateObject private var viewModel = SoilSampleViewModel()
    
    /// Item seleccionado del selector de fotos.
    @State private var selectedItem: PhotosPickerItem?
    
    /// Imagen seleccionada para mostrar en la UI.
    @State private var selectedImage: UIImage?
    
    /// Indica si la vista de la cámara está activa.
    @State private var isCameraActive = false
    
    /// Indica si la vista de resultados está activa.
    @State private var isResultActive = false
    
    @StateObject private var colorAnalysisService = ColorAnalysisService()
    @State private var munsellNotation: String = ""
    @State private var soilClassification: String = ""
    @State private var soilDescription: String = ""
    @State private var isAnalyzing = false
    @State private var selectionRect: CGRect?
    @State private var polygonPoints: [CGPoint]?
    @State private var showImagePicker = false
    @State private var selectionMode: SelectionMode = .rectangle
    
    /// Contenido principal de la vista.
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if let image = selectedImage {
                        ImageAnalysisView(
                            image: image,
                            selectionMode: $selectionMode,
                            viewModel: viewModel,
                            colorAnalysisService: colorAnalysisService,
                            onNewSample: resetState
                        )
                    } else {
                        ImageSelectionView(
                            isCameraActive: $isCameraActive,
                            showImagePicker: $showImagePicker,
                            onImageSelected: { image in
                                selectedImage = image
                            }
                        )
                    }
                }
            }
            .navigationTitle("SoilHue")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $isCameraActive) {
                CameraView { image in
                    selectedImage = image
                }
            }
        }
    }
    
    private func resetState() {
        selectedImage = nil
        viewModel.currentSample = nil
    }
}

// MARK: - ImageSelectionView
struct ImageSelectionView: View {
    @Binding var isCameraActive: Bool
    @Binding var showImagePicker: Bool
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Selecciona una imagen para analizar")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button(action: { showImagePicker = true }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                        Text("Galería")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: { isCameraActive = true }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                        Text("Cámara")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - ImageAnalysisView
struct ImageAnalysisView: View {
    let image: UIImage
    @Binding var selectionMode: SelectionMode
    @ObservedObject var viewModel: SoilSampleViewModel
    @ObservedObject var colorAnalysisService: ColorAnalysisService
    let onNewSample: () -> Void
    
    @State private var selectionRect: CGRect?
    @State private var polygonPoints: [CGPoint]?
    @State private var isAnalyzing = false
    @State private var munsellNotation: String = ""
    @State private var soilClassification: String = ""
    @State private var soilDescription: String = ""
    
    var body: some View {
        VStack {
            AnalysisButtonView(
                isAnalyzing: $isAnalyzing,
                isEnabled: isAnalysisEnabled,
                onAnalyze: analyze
            )
            .padding(.vertical)
            
            SelectionModePickerView(selectionMode: $selectionMode)
            
            ImageSelectionAreaView(
                image: image,
                selectionMode: selectionMode,
                selectionRect: $selectionRect,
                polygonPoints: $polygonPoints
            )
            
            if let sample = viewModel.currentSample,
               let munsellColor = sample.munsellColor,
               !munsellColor.isEmpty {
                AnalysisResultsView(
                    munsellNotation: munsellColor,
                    soilClassification: soilClassification,
                    soilDescription: soilDescription,
                    onNewSample: onNewSample
                )
            }
        }
    }
    
    private var isAnalysisEnabled: Bool {
        !isAnalyzing && 
        ((selectionMode == .rectangle && selectionRect != nil) ||
         (selectionMode == .polygon && (polygonPoints?.count ?? 0) >= 3))
    }
    
    private func analyze() {
        Task {
            isAnalyzing = true
            defer { isAnalyzing = false }
            
            // Crear una nueva muestra si no existe
            if viewModel.currentSample == nil {
                viewModel.addSample(image: image)
            }
            
            let result = if selectionMode == .rectangle {
                await colorAnalysisService.analyzeImage(image, region: selectionRect)
            } else {
                await colorAnalysisService.analyzeImage(image, polygonPoints: polygonPoints)
            }
            
            await MainActor.run {
                munsellNotation = result.munsellNotation
                soilClassification = result.soilClassification
                soilDescription = result.soilDescription
                
                // Actualizar la muestra actual
                viewModel.currentSample?.munsellColor = result.munsellNotation
                viewModel.currentSample?.soilClassification = result.soilClassification
                viewModel.currentSample?.soilDescription = result.soilDescription
            }
        }
    }
}

// MARK: - Supporting Views
struct SelectionModePickerView: View {
    @Binding var selectionMode: SelectionMode
    
    var body: some View {
        Picker("Modo de selección", selection: $selectionMode) {
            Text("Rectángulo").tag(SelectionMode.rectangle)
            Text("Polígono").tag(SelectionMode.polygon)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

struct ImageSelectionAreaView: View {
    let image: UIImage
    let selectionMode: SelectionMode
    @Binding var selectionRect: CGRect?
    @Binding var polygonPoints: [CGPoint]?
    
    var body: some View {
        VStack {
            if selectionMode == .rectangle {
                ColorSelectionView(image: image, selectionRect: $selectionRect)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                
                if let rect = selectionRect {
                    Text("Área seleccionada: \(Int(rect.width * 100))% x \(Int(rect.height * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                PolygonSelectionView(image: image, polygonPoints: $polygonPoints)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                
                if let points = polygonPoints, points.count >= 3 {
                    Text("Polígono con \(points.count) vértices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AnalysisButtonView: View {
    @Binding var isAnalyzing: Bool
    let isEnabled: Bool
    let onAnalyze: () -> Void
    
    var body: some View {
        Button(action: onAnalyze) {
            if isAnalyzing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Analizar Color")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .disabled(!isEnabled)
        .padding(.horizontal)
    }
}

struct AnalysisResultsView: View {
    let munsellNotation: String
    let soilClassification: String
    let soilDescription: String
    let onNewSample: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Resultados del Análisis")
                .font(.headline)
                .padding(.top)
            
            Text("Color Munsell: \(munsellNotation)")
            Text("Clasificación: \(soilClassification)")
            Text("Descripción: \(soilDescription)")
            
            Button(action: onNewSample) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Nueva Muestra")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
