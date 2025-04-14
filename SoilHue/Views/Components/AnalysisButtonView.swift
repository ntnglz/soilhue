import SwiftUI

struct AnalysisButtonView: View {
    @Binding var isAnalyzing: Bool
    let isEnabled: Bool
    let onAnalyze: () -> Void
    
    var body: some View {
        Button(action: onAnalyze) {
            if isAnalyzing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Analizar Color")
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