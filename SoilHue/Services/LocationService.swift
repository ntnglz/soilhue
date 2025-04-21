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
    
    #if DEBUG
    /// Coordenadas de Apple Park para modo DEBUG
    private let appleParkLocation = CLLocation(
        coordinate: CLLocationCoordinate2D(
            latitude: 37.334722,
            longitude: -122.008889
        ),
        altitude: 25.0, // Altura aproximada de Apple Park
        horizontalAccuracy: 10.0,
        verticalAccuracy: 10.0,
        timestamp: Date()
    )
    #endif
    
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
        #if DEBUG
        // En modo DEBUG, devolver siempre la ubicación de Apple Park
        return appleParkLocation
        #else
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
        #endif
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
                    userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("location.error.permission.denied", comment: "Location permission denied error message")]
                )
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            #if DEBUG
            // En modo DEBUG, ignoramos las actualizaciones de ubicación real
            self.currentLocation = appleParkLocation
            
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(returning: appleParkLocation)
                self.stopUpdatingLocation()
            }
            #else
            self.currentLocation = location
            
            if let continuation = self.locationContinuation {
                self.locationContinuation = nil
                continuation.resume(returning: location)
                self.stopUpdatingLocation()
            }
            #endif
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