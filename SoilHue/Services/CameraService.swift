//
//  CameraService.swift
//  SoilHue
//
//  Created by Antonio J. González on 13/4/25.
//

import AVFoundation
import UIKit

class CameraService: NSObject, ObservableObject {
    @Published var error: CameraError?
    @Published var session = AVCaptureSession()
    
    private let output = AVCapturePhotoOutput()
    private var permissionGranted = false
    
    enum CameraError: Error {
        case permissionDenied
        case captureError
        case invalidDevice
    }
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
            error = .permissionDenied
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionGranted = granted
                if !granted {
                    self?.error = .permissionDenied
                }
            }
        }
    }
}
