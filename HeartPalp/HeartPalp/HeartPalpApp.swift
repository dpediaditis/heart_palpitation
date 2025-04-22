import SwiftUI
import Spezi
import SpeziHealthKit
import HealthKit

@main
struct HeartPalpApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            // Wrap your conditional UI in a single View so you can apply .spezi(...) once:
            Group {
                if hasOnboarded {
                    MainTabView()
                } else {
                    OnboardingFlow()
                }
            }
            // This injects HealthKit (and anything else configured in AppDelegate)
            .spezi(appDelegate)
        }
    }
}
