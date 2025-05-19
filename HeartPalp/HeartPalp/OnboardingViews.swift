// OnboardingViews.swift
import SwiftUI
import SpeziOnboarding
import PencilKit

// 1️⃣ Welcome Screen
struct WelcomeOnboarding: View {
    let action: () -> Void
    var body: some View {
        Image("SymptomSaga_Logo_Transp")
            .resizable()
            .scaledToFit()
            .frame(width: 160, height: 160)
            .accessibilityLabel("SymptomSaga Logo")
            .padding(.top, 50)
        VStack(spacing: 34) {
            OnboardingView(
                title: "Welcome to SymptomSaga",
                subtitle: "Turning data into story, and story into care",
                areas: [
                    .init(icon: Image(systemName: "heart.fill"),
                          title: "Track Heart Episodes",
                          description: "ECG & Heart Rate data from Apple Watch."),
                    .init(icon: Image(systemName: "heart.text.square"),
                          title: "Log Episode Symptoms",
                          description: "Track Episode Subjective Symptoms.")
                ],
                actionText: "Next",
                action: action
            )
            
        }
    }
}

// 2️⃣ Permissions Screen
struct PermissionsOnboarding: View {
    let action: () -> Void
    var body: some View {
        SequentialOnboardingView(
            title: "Permissions",
            subtitle: "Grant HealthKit access",
            content: [
                .init(title: "Heart Rate & Sleep",
                      description: "Allow HealthKit to track your vitals.")
            ],
            actionText: "Grant",
            action: action
        )
    }
}

// 3️⃣ Signature Screen
struct SignatureOnboarding: View {
    let action: () -> Void
    @State private var drawing = PKDrawing()

    var body: some View {
        VStack(spacing: 16) {
            Text("Please Sign Below")
                .font(.headline)

            SignaturePad(drawing: $drawing)
                .frame(height: 240)
                .border(Color.gray)

            Button("Next", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// PencilKit helper
struct SignaturePad: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.allowsFingerDrawing = true
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvas.delegate = context.coordinator
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignaturePad
        init(_ parent: SignaturePad) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// 4️⃣ Simple Consent Screen
struct ConsentOnboarding: View {
    let action: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Sharing Consent")
                    .font(.title2).bold()
                Text("""
By tapping "I Consent," you agree to share your health data. All data will be transmitted securely over HTTPS. The data can only be viewed using your custom generated link.
""")
            }
            .padding()
        }
        Button("I Consent", action: action)
            .buttonStyle(.borderedProminent)
            .padding()
    }
}


#if DEBUG
struct OnboardingViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeOnboarding(action: {})
                .previewLayout(.sizeThatFits)
                .padding()
            PermissionsOnboarding(action: {})
                .previewLayout(.sizeThatFits)
                .padding()
            SignatureOnboarding(action: {})
                .previewLayout(.sizeThatFits)
                .padding()
            ConsentOnboarding(action: {})
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
#endif
