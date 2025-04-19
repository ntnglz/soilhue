import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: OnboardingModel
    @Environment(\.colorScheme) var colorScheme
    
    private let dotSize: CGFloat = 10
    private let dotSpacing: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Imagen del paso actual
                Image(systemName: model.tutorialSteps[model.currentStep].imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.accentColor)
                    .padding()
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            .frame(width: 160, height: 160)
                    )
                
                // Título y descripción
                VStack(spacing: 16) {
                    Text(model.tutorialSteps[model.currentStep].title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(model.tutorialSteps[model.currentStep].description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Indicadores de paso
                HStack(spacing: dotSpacing) {
                    ForEach(0..<model.tutorialSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index == model.currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: dotSize, height: dotSize)
                            .scaleEffect(index == model.currentStep ? 1.2 : 1)
                            .animation(.spring(), value: model.currentStep)
                    }
                }
                .padding(.bottom)
                
                // Botones de navegación
                HStack(spacing: 20) {
                    if model.currentStep > 0 {
                        Button(action: model.previousStep) {
                            Text("Anterior")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: model.nextStep) {
                        Text(model.currentStep == model.tutorialSteps.count - 1 ? "Comenzar" : "Siguiente")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black : Color.white,
                colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    OnboardingView(model: OnboardingModel())
} 