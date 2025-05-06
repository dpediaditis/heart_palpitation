import Spezi
import SpeziAccount
import SpeziHealthKit
import HealthKit
import SpeziQuestionnaire

class AppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: HealthDataStandard()) {
            
            // MARK: – HealthKit
            HealthKit {
                CollectSample(.heartRate)
                CollectSample(.restingHeartRate)
                CollectSample(.bloodOxygen)
                CollectSample(.sleepAnalysis)
                CollectSample(.electrocardiogram, start: .manual)
                CollectSample(.stepCount)
                CollectSample(.distanceWalkingRunning)
                CollectSample(.activeEnergyBurned)
                CollectSample(.basalEnergyBurned)
                CollectSample(.appleExerciseTime)
                CollectSample(.appleStandTime)

                RequestReadAccess([
                    HKObjectType.quantityType(forIdentifier: .heartRate)!,
                    HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                    HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
                    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                    HKObjectType.electrocardiogramType(),
                    HKObjectType.quantityType(forIdentifier: .stepCount)!,
                    HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                    HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                    HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
                    HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
                    HKObjectType.quantityType(forIdentifier: .appleStandTime)!
                ])
            }

        }
    }
}
