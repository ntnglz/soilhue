import CoreLocation
import SwiftUI

/// Servicio para obtener la ubicación del dispositivo
@MainActor
class LocationService: NSObject, ObservableObject {
    /// Estado de la autorización de ubicación
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Ubicación actual
    @Published private(set) var currentLocation: CLLocation?
    
    /// Error actual
    @Published private(set) var error: Error?
    
    /// Manager de ubicación
    private let locationManager = CLLocationManager()
    
    /// Continuación para la ubicación
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    /// Solicita autorización para usar la ubicación
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Obtiene la ubicación actual
    func getCurrentLocation() async throws -> CLLocation {
        // Si ya tenemos autorización y una ubicación reciente, la devolvemos
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways,
           let location = currentLocation,
           Date().timeIntervalSince(location.timestamp) < 30 {
            return location
        }
        
        // Si no tenemos autorización, la solicitamos
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
        
        // Esperamos a obtener la ubicación
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.startUpdatingLocation()
        }
    }
    
    /// Detiene la actualización de ubicación
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if manager.authorizationStatus == .denied {
            error = NSError(
                domain: "LocationService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "El acceso a la ubicación está desactivado. Por favor, actívalo en Ajustes."]
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(returning: location)
            stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(throwing: error)
            stopUpdatingLocation()
        }
    }
} 