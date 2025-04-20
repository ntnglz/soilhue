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
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var showHelp = false
    
    var mainContent: some View {
        VStack {
            if selectedImage == nil {
                VStack(spacing: 20) {
                    // Logo y título
                    VStack(spacing: 15) {
                        Image(systemName: "leaf.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.green)
                        
                        Text(NSLocalizedString("welcome.title", comment: "Welcome message"))
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text(NSLocalizedString("welcome.description", comment: "App description"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 10)
                    }
                    .padding(.top, 40)
                    
                    // Características principales
                    HStack(spacing: 25) {
                        FeatureItem(
                            icon: "camera.viewfinder",
                            title: NSLocalizedString("feature.capture.title", comment: "Precise capture feature")
                        )
                        FeatureItem(
                            icon: "eyedropper.halffull",
                            title: NSLocalizedString("feature.analysis.title", comment: "Munsell analysis feature")
                        )
                        FeatureItem(
                            icon: "square.stack.3d.up",
                            title: NSLocalizedString("feature.classification.title", comment: "Soil classification feature")
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    
                    Spacer(minLength: 30)
                    
                    // Botones de acción
                    VStack(spacing: 15) {
                        Button(action: { isCameraActive = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text(NSLocalizedString("button.camera", comment: "Camera button"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 2)
                        }
                        
                        Button(action: { showImagePicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title2)
                                Text(NSLocalizedString("button.gallery", comment: "Gallery button"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                        
                        Button(action: { showCalibration = true }) {
                            HStack {
                                Image(systemName: "camera.aperture")
                                    .font(.title2)
                                Text(NSLocalizedString("button.calibrate", comment: "Calibrate button"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Botón de ayuda
                    Button(action: { showHelp = true }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text(NSLocalizedString("button.help", comment: "Help button"))
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                }
            } else {
                ImageAnalysisView(
                    viewModel: viewModel,
                    colorAnalysisService: colorAnalysisService,
                    image: selectedImage!,
                    selectionMode: $selectionMode,
                    onNewSample: {
                        selectedImage = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
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
        .alert(NSLocalizedString("alert.error.title", comment: "Error alert title"), 
               isPresented: $showError,
               presenting: errorMessage) { _ in
            Button(NSLocalizedString("button.ok", comment: "OK button")) {}
        } message: { message in
            Text(message)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
    }
    
    /// Contenido principal de la vista.
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle(NSLocalizedString("app.name", comment: "App name"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            if selectedImage != nil {
                                Button(action: { showExport = true }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .accessibilityLabel(NSLocalizedString("button.export", comment: "Export button"))
                                }
                            }
                            
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gear")
                                    .accessibilityLabel(NSLocalizedString("button.settings", comment: "Settings button"))
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


