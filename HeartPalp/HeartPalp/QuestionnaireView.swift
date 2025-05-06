//import SwiftUI
//
//struct QuestionnaireView: View {
//    @Environment(\.presentationMode) private var presentationMode
//    @State private var response = HealthQuestionnaireResponse()
//    @State private var showAlert = false
//    @ObservedObject private var fhirService = FHIRDataService()
//
//    var body: some View {
//        NavigationView {
//            Form {
//                Section("About You") {
//                    Stepper("Age: \(response.age ?? 0)", value: Binding(
//                        get: { response.age ?? 0 },
//                        set: { response.age = $0 }
//                    ), in: 0...120)
//
//                    Picker("Gender", selection: $response.gender) {
//                        ForEach(HealthQuestionnaireResponse.Gender.allCases) { g in
//                            Text(g.display).tag(g)
//                        }
//                    }
//                }
//                Section("Measurements") {
//                    HStack {
//                        Text("Height (cm)"); Spacer()
//                        TextField("e.g. 170", value: $response.heightCm, formatter: NumberFormatter())
//                            .keyboardType(.decimalPad)
//                            .multilineTextAlignment(.trailing)
//                    }
//                    HStack {
//                        Text("Weight (kg)"); Spacer()
//                        TextField("e.g. 70", value: $response.weightKg, formatter: NumberFormatter())
//                            .keyboardType(.decimalPad)
//                            .multilineTextAlignment(.trailing)
//                    }
//                }
//                Section("Lifestyle") {
//                    Toggle("Do you smoke?", isOn: $response.smoking)
//
//                    Picker("Alcohol Intake", selection: $response.alcoholFrequency) {
//                        ForEach(HealthQuestionnaireResponse.AlcoholFrequency.allCases) { f in
//                            Text(f.display).tag(f)
//                        }
//                    }
//                    Stepper("Exercise days/week: \(response.exerciseDaysPerWeek)",
//                            value: $response.exerciseDaysPerWeek, in: 0...7)
//                }
//                Section("Habits & Stress") {
//                    HStack {
//                        Text("Sleep (hrs/night)")
//                        Slider(value: $response.sleepHours, in: 0...12, step: 0.5)
//                        Text(String(format: "%.1f", response.sleepHours))
//                            .frame(width:  40)
//                    }
//                    VStack(alignment: .leading) {
//                        Text("Stress level (0–10)")
//                        Slider(value: Binding(
//                            get: { Double(response.stressLevel) },
//                            set: { response.stressLevel = Int($0) }
//                        ), in: 0...10, step: 1)
//                        Text("\(response.stressLevel)")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                Section {
//                    Button("Submit") {
//                        guard
//                            response.age != nil,
//                            response.heightCm != nil,
//                            response.weightKg != nil
//                        else {
//                            showAlert = true
//                            return
//                        }
//
//                        Task {
//                            do {
//                                // 1) Build QuestionnaireResponse JSON
//                                let fhirData = try response.fhirJSON()
//                                print(String(data: fhirData, encoding: .utf8)!)
//
//                                // 2) Upload health data (placeholder – you’d gather real HK samples)
//                                try await fhirService.uploadQuestionnaireResponse(fhirData)
//
//                                // 3) Dismiss
//                                presentationMode.wrappedValue.dismiss()
//                            } catch {
//                                print("❌ FHIR JSON build failed:", error)
//                            }
//                        }
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                }
//            }
//            .navigationTitle("Health Check-In")
//            .alert("Missing Info",
//                   isPresented: $showAlert,
//                   actions: { Button("OK", role: .cancel) {} },
//                   message: { Text("Fill in age, height, and weight.") })
//        }
//    }
//}
