import SwiftUI

struct CalibrationStatusView: View {
    let state: CalibrationService.CalibrationState
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(backgroundColor.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var iconName: String {
        switch state {
        case .notCalibrated:
            return "camera.metering.unknown"
        case .calibrating:
            return "camera.metering.center.weighted"
        case .calibrated:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .notCalibrated:
            return .orange
        case .calibrating:
            return .blue
        case .calibrated:
            return .green
        case .error:
            return .red
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .notCalibrated:
            return .orange
        case .calibrating:
            return .blue
        case .calibrated:
            return .green
        case .error:
            return .red
        }
    }
    
    private var title: String {
        switch state {
        case .notCalibrated:
            return NSLocalizedString("calibration.status.notCalibrated.title", comment: "Not calibrated title")
        case .calibrating:
            return NSLocalizedString("calibration.status.calibrating.title", comment: "Calibrating title")
        case .calibrated:
            return NSLocalizedString("calibration.status.calibrated.title", comment: "Calibrated title")
        case .error:
            return NSLocalizedString("calibration.status.error.title", comment: "Error title")
        }
    }
    
    private var message: String {
        switch state {
        case .notCalibrated:
            return NSLocalizedString("calibration.status.notCalibrated.message", comment: "Not calibrated message")
        case .calibrating:
            return NSLocalizedString("calibration.status.calibrating.message", comment: "Calibrating message")
        case .calibrated:
            return NSLocalizedString("calibration.status.calibrated.message", comment: "Calibrated message")
        case .error(let error):
            return String(format: NSLocalizedString("calibration.status.error.message", comment: "Error message format"), error)
        }
    }
} 