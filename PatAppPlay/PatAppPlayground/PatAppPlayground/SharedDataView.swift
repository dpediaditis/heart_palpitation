import SwiftUI
import HealthKit

struct SharedDataView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var sharedData: [SharedDataType] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(sharedData) { dataType in
                    VStack(alignment: .leading) {
                        Text(dataType.name)
                            .font(.headline)
                        Text("\(dataType.sampleCount) samples")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Last updated: \(dataType.lastUpdate.formatted())")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle(languageManager.localizedString("sharedDataTitle"))
        .onAppear {
            fetchSharedData()
        }
    }
    
    private func fetchSharedData() {
        isLoading = true
        errorMessage = nil
        
        // Get the current consent to know what data types to check
        guard let consent = ConsentStore.shared.currentConsent else {
            errorMessage = languageManager.localizedString("noActiveConsent")
            isLoading = false
            return
        }
        
        var fetchedData: [SharedDataType] = []
        let group = DispatchGroup()
        
        for dataType in consent.dataTypes {
            group.enter()
            
            let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: dataType.rawValue)
            guard let sampleType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) else {
                group.leave()
                continue
            }
            
            let predicate = HKQuery.predicateForSamples(
                withStart: consent.startDate,
                end: consent.endDate,
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                defer { group.leave() }
                
                if let error = error {
                    print("❌ Error fetching \(dataType.rawValue): \(error.localizedDescription)")
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else { return }
                
                let lastUpdate = samples.first?.startDate ?? Date()
                let dataType = SharedDataType(
                    id: dataType.rawValue,
                    name: dataType.rawValue,
                    sampleCount: samples.count,
                    lastUpdate: lastUpdate
                )
                
                fetchedData.append(dataType)
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            sharedData = fetchedData.sorted { $0.lastUpdate > $1.lastUpdate }
            isLoading = false
        }
    }
}

struct SharedDataType: Identifiable {
    let id: String
    let name: String
    let sampleCount: Int
    let lastUpdate: Date
} 