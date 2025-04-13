//
//  SoilSample.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import Foundation
import CoreLocation

struct SoilSample: Identifiable {
    let id = UUID()
    let image: UIImage
    let timestamp: Date
    var location: CLLocation?
    var munsellColor: String?
}
