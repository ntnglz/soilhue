//
//  ContentView.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

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

#Preview {
    ContentView()
}
