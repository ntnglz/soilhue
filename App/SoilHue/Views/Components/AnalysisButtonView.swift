import SwiftUI

struct AnalysisButtonView: View {
    @Binding var isAnalyzing: Bool
    let isEnabled: Bool
    let onAnalyze: () -> Void
    
    var body: some View {
        Button(action: onAnalyze) {
            if isAnalyzing {
                ProgressView(NSLocalizedString("analysis.analyzing", comment: "Analyzing progress"))
            } else {
                Text(NSLocalizedString("analysis.button.analyze", comment: "Analyze button"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .disabled(!isEnabled)
        .padding(.horizontal)
    }
} 