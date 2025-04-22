import Spezi
import SpeziAccount
import SpeziHealthKit
import HealthKit

class AppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: HealthDataStandard()) {
            HealthKit {
                CollectSample(.heartRate)
                CollectSample(.restingHeartRate)
                CollectSample(.bloodOxygen)
                CollectSample(.sleepAnalysis)
                CollectSample(.electrocardiogram, start: .manual)

                RequestReadAccess([
                    HKObjectType.quantityType(forIdentifier: .heartRate)!,
                    HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                    HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
                    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                    HKObjectType.electrocardiogramType()
                ])
            }
        }
    }
}
