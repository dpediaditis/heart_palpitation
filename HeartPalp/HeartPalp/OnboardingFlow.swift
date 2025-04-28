import SwiftUI
import HealthKit

struct OnboardingFlow: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var step = 0
    @State private var showError = false

    var body: some View {
        switch step {
        case 0:
            WelcomeOnboarding { step += 1 }

        case 1:
            PermissionsOnboarding {
                let store = HKHealthStore()
                let readTypes: Set<HKObjectType> = [
                    HKObjectType.quantityType(forIdentifier: .heartRate)!,
                    HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                    HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
                    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                    HKObjectType.quantityType(forIdentifier: .stepCount)!,
                    HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                    HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
                    HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
                    HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
                    HKObjectType.electrocardiogramType()
                ]

                store.requestAuthorization(toShare: [], read: readTypes) { granted, error in
                    DispatchQueue.main.async {
                        print("🔐 HealthKit granted: \(granted), error: \(String(describing: error))")
                        if granted {
                            step += 1
                        } else {
                            showError = true
                        }
                    }
                }
            }
            .alert("HealthKit Access Denied", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enable HealthKit in Settings to continue.")
            }

        case 2:
            SignatureOnboarding { step += 1 }

        case 3:
            ConsentOnboarding {
                hasOnboarded = true   // ✅ this ends onboarding and flips the flag
            }

        default:
            // Not needed anymore unless debugging
            EmptyView()
        }
    }
}
