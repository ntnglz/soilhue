import SwiftUI
import PhotosUI

struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.2, green: 0.5, blue: 0.3), Color(red: 0.1, green: 0.3, blue: 0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Contenido principal
                TabView(selection: $currentPage) {
                    // Página 1: Bienvenida
                    welcomePage
                        .tag(0)
                    
                    // Página 2: Características
                    featuresPage
                        .tag(1)
                    
                    // Página 3: Comenzar
                    startPage
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Botones de navegación
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Text(NSLocalizedString("onboarding.button.previous", comment: "Previous button"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    if currentPage < 2 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text(NSLocalizedString("onboarding.button.next", comment: "Next button"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            hasCompletedOnboarding = true
                        }) {
                            Text(NSLocalizedString("onboarding.button.start", comment: "Start button"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
    
    // Página de bienvenida
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "leaf.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.white)
            
            Text(NSLocalizedString("welcome.title", comment: "Welcome title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("welcome.description", comment: "Welcome description"))
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // Página de características
    private var featuresPage: some View {
        VStack(spacing: 30) {
            Text(NSLocalizedString("feature.capture.title", comment: "Feature capture title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                featureCard(
                    icon: "camera.fill",
                    title: NSLocalizedString("feature.capture.title", comment: "Feature capture title"),
                    description: NSLocalizedString("feature.capture.description", comment: "Feature capture description")
                )
                
                featureCard(
                    icon: "eyedropper",
                    title: NSLocalizedString("feature.analysis.title", comment: "Feature analysis title"),
                    description: NSLocalizedString("feature.analysis.description", comment: "Feature analysis description")
                )
                
                featureCard(
                    icon: "map.fill",
                    title: NSLocalizedString("feature.classification.title", comment: "Feature classification title"),
                    description: NSLocalizedString("feature.classification.description", comment: "Feature classification description")
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // Página de comenzar
    private var startPage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
            
            Text(NSLocalizedString("onboarding.step4.title", comment: "Ready to start title"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("onboarding.step4.description", comment: "Ready to start description"))
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // Tarjeta de característica
    private func featureCard(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(15)
    }
}

#Preview {
    WelcomeView()
} 