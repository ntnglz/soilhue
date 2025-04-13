//
//  CameraView.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

// Views/CameraView.swift
import SwiftUI
import PhotosUI

/// Vista para la selección de imágenes desde la galería de fotos.
///
/// Esta vista proporciona una interfaz para:
/// - Seleccionar imágenes desde la galería de fotos
/// - Mostrar un botón de selección con icono de cámara
/// - Permitir cerrar la vista mediante un botón "Done"
///
/// La vista utiliza `PhotosPicker` para la selección de imágenes y mantiene
/// un binding con el item seleccionado en la vista padre.
struct CameraView: View {
    /// Entorno que proporciona acceso a funciones de presentación.
    @Environment(\.dismiss) private var dismiss
    
    /// Binding al item de foto seleccionado en la vista padre.
    @Binding var selectedImage: PhotosPickerItem?
    
    /// Contenido principal de la vista.
    var body: some View {
        NavigationView {
            PhotosPicker(
                selection: $selectedImage,
                matching: .images,
                photoLibrary: .shared()) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                        Text("Select Photo")
                    }
                }
                .navigationTitle("Select Sample")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        dismiss()
                    }
                )
        }
    }
}

/// Vista previa para desarrollo y testing.
#Preview {
    CameraView(selectedImage: .constant(nil))
}
