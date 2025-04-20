import SwiftUI

struct CameraGuideView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Marco guía
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white, lineWidth: 2)
                    .frame(
                        width: geometry.size.width * 0.8,
                        height: geometry.size.width * 0.8
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                
                // Texto guía
                VStack {
                    Spacer()
                    Text(NSLocalizedString("calibration.guide.frame", comment: "Instruction to align the calibration card within the frame"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.bottom, 120)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        Color.black
        CameraGuideView()
    }
} 