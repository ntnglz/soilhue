import SwiftUI
import MapKit
import CoreLocation

/// Vista que muestra un mapa y detalles de una ubicación
struct LocationView: View {
    let location: CLLocation
    @State private var region: MKCoordinateRegion
    
    init(location: CLLocation) {
        self.location = location
        print("DEBUG: LocationView - Inicializando con ubicación: \(location.coordinate)")
        _region = State(initialValue: MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 17.0, *) {
                Map {
                    Marker("Ubicación", coordinate: location.coordinate)
                        .tint(.red)
                }
                .mapStyle(.standard)
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .frame(height: 200)
            } else {
                Map(coordinateRegion: $region, annotationItems: [location]) { location in
                    MapMarker(coordinate: location.coordinate, tint: .red)
                }
                .frame(height: 200)
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
        .onChange(of: location) { newLocation in
            print("DEBUG: LocationView - Actualizando región para nueva ubicación: \(newLocation.coordinate)")
            withAnimation {
                region = MKCoordinateRegion(
                    center: newLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}

extension CLLocation: Identifiable {
    public var id: String {
        "\(coordinate.latitude),\(coordinate.longitude)"
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
        )
    )
    .frame(height: 200)
    .cornerRadius(12)
} 
