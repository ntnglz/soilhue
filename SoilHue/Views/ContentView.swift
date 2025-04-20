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
    case full
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
    @StateObject private var onboardingModel = OnboardingModel()
    @EnvironmentObject private var settingsModel: SettingsModel
    
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
    @State private var showCalibration = false
    @State private var showSettings = false
    @State private var showExport = false
    
    /// Contenido principal de la vista.
    var body: some View {
        Group {
            if onboardingModel.hasSeenOnboarding {
                mainContent
            } else {
                OnboardingView(model: onboardingModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: onboardingModel.hasSeenOnboarding)
        .onAppear {
            if settingsModel.autoCalibration {
                showCalibration = true
            }
        }
        .preferredColorScheme(colorScheme)
    }
    
    /// Botón de configuración para el toolbar
    private var settingsButton: some View {
        Button(action: { showSettings = true }) {
            Image(systemName: "gear")
                .imageScale(.medium)
        }
    }
    
    /// Botón de exportación para el toolbar
    private var exportButton: some View {
        Button(action: { showExport = true }) {
            Image(systemName: "square.and.arrow.up")
                .imageScale(.medium)
        }
    }
    
    /// Vista principal de la aplicación
    private var mainContent: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            if let image = selectedImage {
                                ImageAnalysisView(
                                    viewModel: viewModel,
                                    colorAnalysisService: colorAnalysisService,
                                    image: image,
                                    selectionMode: $selectionMode,
                                    onNewSample: resetState
                                )
                                .frame(maxHeight: .infinity)
                            } else {
                                ImageSelectionView(
                                    isCameraActive: $isCameraActive,
                                    showImagePicker: $showImagePicker,
                                    showCalibration: $showCalibration,
                                    onImageSelected: { image in
                                        selectedImage = image
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("SoilHue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        exportButton
                        settingsButton
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $isCameraActive) {
                CameraCaptureView(
                    capturedImage: Binding(
                        get: { viewModel.currentSample?.image },
                        set: { newImage in
                            if let image = newImage {
                                viewModel.addSample(image: image)
                                isCameraActive = false
                                selectedImage = image
                            }
                        }
                    ),
                    capturedLocation: Binding(
                        get: { viewModel.currentSample?.location },
                        set: { newLocation in
                            if let location = newLocation {
                                viewModel.currentSample?.location = location
                            }
                        }
                    ),
                    resolution: .high,
                    showGuide: false
                )
            }
            .sheet(isPresented: $showCalibration) {
                CalibrationView(onCalibrationComplete: {
                    showCalibration = false
                })
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(model: settingsModel)
            }
            .sheet(isPresented: $showExport) {
                ExportView()
            }
        }
    }
    
    private func resetState() {
        selectedImage = nil
        viewModel.currentSample = nil
    }
    
    /// Esquema de color basado en los ajustes
    private var colorScheme: ColorScheme? {
        switch settingsModel.darkMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsModel())
}
