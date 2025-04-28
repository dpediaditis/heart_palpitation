import Spezi
import SpeziHealthKit
import HealthKit

/// A Spezi standard that reacts to new HealthKit samples by pushing them to a FHIR server.
actor HealthDataStandard: Standard, HealthKitConstraint {
    private let fhirService = FHIRDataService()

    func handleNewSamples<Sample>(
        _ addedSamples: some Collection<Sample>,
        ofType sampleType: SampleType<Sample>
    ) async {
        // 1️⃣ ECG samples
        if let ecgSamples = addedSamples as? [HKElectrocardiogram], !ecgSamples.isEmpty {
            do {
                try await fhirService.uploadAllHealthData(
                    hrSamples:       [],
                    restingSamples:  [],
                    oxygenSamples:   [],
                    stepSamples:     [],
                    energySamples:   [],
                    exerciseSamples: [],
                    standSamples:    [],
                    glucoseSamples:  [],
                    ecgSamples:      ecgSamples
                )
                print("✅ Pushed ECG samples (\(ecgSamples.count)) to FHIR")
            } catch {
                print("❌ Failed pushing ECG: \(error)")
            }
            return
        }

        // 2️⃣ Quantity samples
        guard let qtySamples = addedSamples as? [HKQuantitySample], !qtySamples.isEmpty else {
            return
        }

        // Bucket arrays
        var hrSamples:      [HKQuantitySample] = []
        var restingSamples: [HKQuantitySample] = []
        var oxygenSamples:  [HKQuantitySample] = []
        var stepSamples:    [HKQuantitySample] = []
        var energySamples:  [HKQuantitySample] = []
        var exerciseSamples:[HKQuantitySample] = []
        var standSamples:   [HKQuantitySample] = []
        var glucoseSamples: [HKQuantitySample] = []

        for sample in qtySamples {
            switch sample.quantityType.identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                hrSamples.append(sample)
            case HKQuantityTypeIdentifier.restingHeartRate.rawValue:
                restingSamples.append(sample)
            case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
                oxygenSamples.append(sample)
            case HKQuantityTypeIdentifier.stepCount.rawValue:
                stepSamples.append(sample)
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                energySamples.append(sample)
            case HKQuantityTypeIdentifier.appleExerciseTime.rawValue:
                exerciseSamples.append(sample)
            case HKQuantityTypeIdentifier.appleStandTime.rawValue:
                standSamples.append(sample)
            case HKQuantityTypeIdentifier.bloodGlucose.rawValue:
                glucoseSamples.append(sample)
            default:
                break
            }
        }

        // 3️⃣ Upload quantities
        do {
            try await fhirService.uploadAllHealthData(
                hrSamples:       hrSamples,
                restingSamples:  restingSamples,
                oxygenSamples:   oxygenSamples,
                stepSamples:     stepSamples,
                energySamples:   energySamples,
                exerciseSamples: exerciseSamples,
                standSamples:    standSamples,
                glucoseSamples:  glucoseSamples,
                ecgSamples:      []
            )
            print("✅ Pushed quantity samples counts -> HR:\(hrSamples.count), Resting:\(restingSamples.count), Oxygen:\(oxygenSamples.count), Steps:\(stepSamples.count), Energy:\(energySamples.count), Exercise:\(exerciseSamples.count), Stand:\(standSamples.count), Glucose:\(glucoseSamples.count)")
        } catch {
            print("❌ Failed pushing quantity samples: \(error)")
        }
    }

    func handleDeletedObjects<Sample>(
        _ deletedObjects: some Collection<HKDeletedObject>,
        ofType sampleType: SampleType<Sample>
    ) async {
        // No action on deletions
        print("🗑️ Deleted objects count: \(deletedObjects.count) for type \(sampleType)")
    }
}
