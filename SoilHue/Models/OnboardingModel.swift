import Foundation

/// Modelo para gestionar el estado del onboarding y tutorial
class OnboardingModel: ObservableObject {
    /// Clave para almacenar si el onboarding ya se ha mostrado
    private let hasSeenOnboardingKey = "hasSeenOnboarding"
    
    /// Indica si el usuario ya ha visto el onboarding
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: hasSeenOnboardingKey)
        }
    }
    
    /// Paso actual del tutorial
    @Published var currentStep = 0
    
    /// Información de cada paso del tutorial
    let tutorialSteps = [
        TutorialStep(
            title: "Bienvenido a SoilHue",
            description: "Descubre el color y las características de tus muestras de suelo de forma precisa y sencilla.",
            imageName: "soil.sample"
        ),
        TutorialStep(
            title: "Calibración",
            description: "Antes de empezar, calibra la cámara usando la tarjeta de color. Esto asegurará resultados precisos.",
            imageName: "camera.metering.center.weighted"
        ),
        TutorialStep(
            title: "Captura de Muestras",
            description: "Toma fotos de tus muestras de suelo o selecciona imágenes existentes de tu galería.",
            imageName: "camera.fill"
        ),
        TutorialStep(
            title: "¡Listo para Empezar!",
            description: "Ya estás preparado para analizar tus muestras de suelo. ¿Comenzamos?",
            imageName: "checkmark.circle.fill"
        )
    ]
    
    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
    }
    
    /// Avanza al siguiente paso del tutorial
    func nextStep() {
        if currentStep < tutorialSteps.count - 1 {
            currentStep += 1
        } else {
            completeOnboarding()
        }
    }
    
    /// Retrocede al paso anterior del tutorial
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    /// Marca el onboarding como completado
    func completeOnboarding() {
        hasSeenOnboarding = true
    }
    
    /// Reinicia el onboarding
    func resetOnboarding() {
        hasSeenOnboarding = false
        currentStep = 0
    }
}

/// Estructura que representa un paso del tutorial
struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
} 