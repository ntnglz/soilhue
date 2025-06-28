import SwiftUI
import PhotosUI

/// Componente que permite al usuario seleccionar imágenes de su biblioteca de fotos.
///
/// Este componente utiliza PHPickerViewController para proporcionar una interfaz nativa
/// para la selección de imágenes, con opciones de configuración personalizables.
struct ImagePicker: UIViewControllerRepresentable {
    /// Binding a la imagen seleccionada.
    @Binding var image: UIImage?
    
    /// Modo de presentación para controlar la visualización del selector.
    @Environment(\.presentationMode) private var presentationMode
    
    /// Tipo de filtro para las imágenes que se pueden seleccionar.
    var filter: PHPickerFilter = .images
    
    /// Límite de selección (número máximo de imágenes que se pueden seleccionar).
    var selectionLimit: Int = 1
    
    /// Callback opcional que se ejecuta cuando se completa la selección.
    var onSelectionComplete: ((UIImage?) -> Void)? = nil
    
    /// Crea y configura el controlador de vista para el selector de imágenes.
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = filter
        config.selectionLimit = selectionLimit
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    /// Actualiza el controlador de vista cuando cambian las propiedades.
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    /// Crea el coordinador para manejar los eventos del selector.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinador que implementa el delegado del selector de imágenes.
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        /// Maneja el evento cuando el usuario termina de seleccionar imágenes.
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        let selectedImage = image as? UIImage
                        self.parent.image = selectedImage
                        
                        // Ejecutar el callback si está definido
                        if let callback = self.parent.onSelectionComplete {
                            callback(selectedImage)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Extensiones de conveniencia

extension ImagePicker {
    /// Crea un selector de imágenes con configuración predeterminada.
    /// - Parameter image: Binding a la imagen seleccionada.
    static func standard(image: Binding<UIImage?>) -> ImagePicker {
        ImagePicker(image: image)
    }
    
    /// Crea un selector de imágenes para capturas de pantalla.
    /// - Parameter image: Binding a la imagen seleccionada.
    static func screenshots(image: Binding<UIImage?>) -> ImagePicker {
        ImagePicker(
            image: image,
            filter: .screenshots,
            selectionLimit: 1
        )
    }
    
    /// Crea un selector de imágenes para videos.
    /// - Parameter image: Binding a la imagen seleccionada.
    static func videos(image: Binding<UIImage?>) -> ImagePicker {
        ImagePicker(
            image: image,
            filter: .videos,
            selectionLimit: 1
        )
    }
}

#Preview {
    ImagePicker(image: .constant(nil))
} 