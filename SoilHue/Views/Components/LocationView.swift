import SwiftUI
import MapKit
import CoreLocation

/// Vista que muestra un mapa y detalles de una ubicación
struct LocationView: View {
    let location: CLLocation
    @Binding var region: MKCoordinateRegion
    
    init(location: CLLocation, region: Binding<MKCoordinateRegion>) {
        self.location = location
        self._region = region
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 17.0, *) {
                Map(position: .constant(MapCameraPosition.region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))) {
                    Marker("Ubicación", coordinate: location.coordinate)
                        .tint(.red)
                }
            } else {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [LocationAnnotation(location: location)]) { annotation in
                    MapMarker(coordinate: annotation.coordinate, tint: .red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Label {
                        Text("Latitud: \(location.coordinate.latitude, specifier: "%.6f")°")
                    } icon: {
                        Image(systemName: "location.north.fill")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Label {
                        Text("Longitud: \(location.coordinate.longitude, specifier: "%.6f")°")
                    } icon: {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Label {
                        Text("Altitud: \(location.altitude, specifier: "%.1f") m")
                    } icon: {
                        Image(systemName: "arrow.up.forward")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Label {
                        Text("Precisión: \(location.horizontalAccuracy, specifier: "%.1f") m")
                    } icon: {
                        Image(systemName: "scope")
                            .foregroundColor(.blue)
                    }
                }
            }
            .font(.caption)
            .padding(8)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            DispatchQueue.main.async {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}

/// Modelo para representar una anotación en el mapa
private struct LocationAnnotation: Identifiable {
    let id = UUID()
    let location: CLLocation
    
    var coordinate: CLLocationCoordinate2D {
        location.coordinate
    }
}

#Preview {
    LocationView(
        location: CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 100,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        ),
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    )
    .frame(height: 200)
    .cornerRadius(12)
} 