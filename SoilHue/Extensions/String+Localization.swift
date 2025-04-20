import Foundation

extension String {
    /// Devuelve la versión localizada de la cadena
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Devuelve la versión localizada de la cadena con argumentos formateados
    /// - Parameter arguments: Argumentos para formatear la cadena
    /// - Returns: Cadena localizada y formateada
    func localized(_ arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
} 