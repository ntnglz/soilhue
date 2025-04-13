//
//  ContentView.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

// ContentView.swift
import SwiftUI
import PhotosUI

/// Vista principal de la aplicación SoilHue.
///
/// Esta vista proporciona la interfaz principal para:
/// - Mostrar la imagen de la muestra de suelo seleccionada
/// - Permitir la selección de una nueva imagen desde la galería
/// - Gestionar el estado de la muestra actual
///
/// La vista utiliza `PhotosPicker` para la selección de imágenes y mantiene
/// el estado de la imagen seleccionada y el ViewModel de la muestra.
struct ContentView: View {
    /// ViewModel que gestiona la lógica de las muestras de suelo.
    @StateObject private var viewModel = SoilSampleViewModel()
    
    /// Item seleccionado del selector de fotos.
    @State private var selectedItem: PhotosPickerItem?
    
    /// Imagen seleccionada para mostrar en la UI.
    @State private var selectedImage: Image?
    
    /// Contenido principal de la vista.
    var body: some View {
        NavigationView {
            VStack {
                if let selectedImage {
                    selectedImage
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else {
                    ContentUnavailableView(
                        "No Sample",
                        systemImage: "camera.fill",
                        description: Text("Tap the button below to capture a soil sample")
                    )
                }
                
                PhotosPicker(selection: $selectedItem,
                           matching: .images) {
                    Label("Select Sample", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("SoilHue")
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                        viewModel.addSample(image: uiImage)
                    }
                }
            }
        }
    }
}
