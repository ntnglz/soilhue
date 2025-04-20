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
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            if manager.authorizationStatus == .denied {
                self.error = NSError(
                    domain: "LocationService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "El acceso a la ubicación está desactivado. Por favor, actívalo en Ajustes."]
                )
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.currentLocation = location
            
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(returning: location)
                self.stopUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
            
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(throwing: error)
                self.stopUpdatingLocation()
            }
        }
    }
} 