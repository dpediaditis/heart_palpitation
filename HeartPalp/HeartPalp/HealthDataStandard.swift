import Spezi
import SpeziHealthKit
import HealthKit

actor HealthDataStandard: Standard, HealthKitConstraint {
    func handleNewSamples<Sample>(
        _ addedSamples: some Collection<Sample>,
        ofType sampleType: SampleType<Sample>
    ) async {
        print("📥 \(addedSamples.count) new \(sampleType)")
    }

    func handleDeletedObjects<Sample>(
        _ deletedObjects: some Collection<HKDeletedObject>,
        ofType sampleType: SampleType<Sample>
    ) async {
        print("🗑️ \(deletedObjects.count) deleted \(sampleType)")
    }
}
