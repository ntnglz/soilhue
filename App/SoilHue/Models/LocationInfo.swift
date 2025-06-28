import Foundation
import CoreLocation

/// Modelo que representa la información de localización de una muestra
struct LocationInfo: Codable {
    /// Latitud en grados
    let latitude: Double
    
    /// Longitud en grados
    let longitude: Double
    
    /// Altitud en metros (opcional)
    let altitude: Double?
    
    /// Precisión horizontal en metros
    let horizontalAccuracy: Double
    
    /// Precisión vertical en metros (opcional)
    let verticalAccuracy: Double?
    
    /// Marca de tiempo de la localización
    let timestamp: Date
    
    /// Crea una instancia de LocationInfo a partir de un CLLocation
    /// - Parameter location: Objeto CLLocation del que obtener los datos
    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.verticalAccuracy >= 0 ? location.altitude : nil
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy >= 0 ? location.verticalAccuracy : nil
        self.timestamp = location.timestamp
    }
}

extension LocationInfo {
    /// Convierte la instancia a un objeto CLLocation
    /// - Returns: Un objeto CLLocation con los datos de la instancia
    func toCLLocation() -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            altitude: altitude ?? 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy ?? -1,
            timestamp: timestamp
        )
    }
} 
