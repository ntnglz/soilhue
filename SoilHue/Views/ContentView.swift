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
struct ToolbarView: ToolbarContent {
    var showSettings: () -> Void
    var showExport: () -> Void
    var hasImage: Bool
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: showSettings) {
                Image(systemName: "gear")
            }
            
            if hasImage {
                Button(action: showExport) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

struct ContentView: View {
    /// ViewModel que gestiona la lógica de las muestras de suelo.
    @StateObject private var viewModel = SoilSampleViewModel()
    @StateObject private var onboardingModel = OnboardingModel()
    @EnvironmentObject private var settingsModel: SettingsModel
    @StateObject private var locationService = LocationService()
    @StateObject private var colorAnalysisService = ColorAnalysisService()
    
    /// Item seleccionado del selector de fotos.
    @State private var selectedItem: PhotosPickerItem?
    
    /// Imagen seleccionada para mostrar en la UI.
    @State private var selectedImage: UIImage?
    
    /// Indica si la vista de la cámara está activa.
    @State private var isCameraActive = false
    
    /// Indica si la vista de resultados está activa.
    @State private var isResultActive = false
    
    @State private var munsellNotation: String = ""
    @State private var soilClassification: String = ""
    @State private var soilDescription: String = ""
    @State private var isAnalyzing = false
    @State private var selectionRect: CGRect?
    @State private var polygonPoints: [CGPoint]?
    @State private var showImagePicker = false
    @State private var selectionMode: SelectionMode = .rectangle
    @State private var showCalibration = false
    @State private var showSettings = false
    @State private var showExport = false
    
    var mainContent: some View {
        VStack {
            if let image = selectedImage {
                ImageAnalysisView(
                    viewModel: viewModel,
                    colorAnalysisService: colorAnalysisService,
                    image: image,
                    selectionMode: $selectionMode,
                    onNewSample: {
                        selectedImage = nil
                    }
                )
            } else {
                WelcomeView(
                    isCameraActive: $isCameraActive,
                    selectedItem: $selectedItem,
                    showCalibration: $showCalibration
                )
            }
        }
    }
    
    /// Contenido principal de la vista.
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("SoilHue")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(id: "mainToolbar") {
                    ToolbarItem(id: "settingsButton", placement: .primaryAction) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                    
                    if selectedImage != nil {
                        ToolbarItem(id: "exportButton", placement: .primaryAction) {
                            Button(action: { showExport = true }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
        }
        .onAppear {
            // Solicitar permisos de ubicación al iniciar
            locationService.requestAuthorization()
        }
        .onChange(of: selectedItem) { item in
            if let item = item {
                loadTransferable(from: item)
            }
        }
        .sheet(isPresented: $isCameraActive) {
            CameraCaptureView(
                capturedImage: $selectedImage,
                capturedLocation: Binding(
                    get: { viewModel.currentSample?.location },
                    set: { location in
                        if viewModel.currentSample == nil {
                            viewModel.addSample(image: selectedImage ?? UIImage(), location: location)
                        }
                        viewModel.currentSample?.location = location
                    }
                ),
                resolution: settingsModel.cameraResolution,
                showGuide: false
            )
        }
        .sheet(isPresented: $showCalibration) {
            CalibrationView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(model: settingsModel)
        }
        .sheet(isPresented: $showExport) {
            ExportView()
        }
        .fullScreenCover(isPresented: .constant(!onboardingModel.hasSeenOnboarding)) {
            OnboardingView(model: onboardingModel)
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem) {
        Task { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsModel())
        .environmentObject(CalibrationService())
}
