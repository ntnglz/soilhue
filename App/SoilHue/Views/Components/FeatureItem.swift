import SwiftUI

struct FeatureItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 45)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack {
        FeatureItem(icon: "camera.viewfinder", title: "Captura\nPrecisa")
        FeatureItem(icon: "eyedropper.halffull", title: "Análisis\nMunsell")
        FeatureItem(icon: "square.stack.3d.up", title: "Clasificación\nde Suelos")
    }
    .padding()
} 