import SwiftUI
import SafariServices
import SpeziQuestionnaire

struct ECGMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingECGGuide = false
    @State private var showingSymptomSurvey = false
    @Binding var shouldIncludePartOf: Bool
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("Take an ECG measurement on your Apple Watch")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Press Continue to Symptom Survey after completed ECG or skip to go directly to Symptom Survey")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingECGGuide = true
            }) {
                HStack {
                    Image(systemName: "info.circle.fill")
                    Text("How to take an ECG measurement")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    // Show symptom survey with partOf
                    shouldIncludePartOf = true
                    print("📱 ECGMeasurementView: Setting shouldIncludePartOf to true")
                    showingSymptomSurvey = true
                }) {
                    Text("Continue to Symptom Survey")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // Show symptom survey without partOf
                    shouldIncludePartOf = false
                    print("📱 ECGMeasurementView: Setting shouldIncludePartOf to false")
                    showingSymptomSurvey = true
                }) {
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(isPresented: $showingECGGuide) {
            SafariView(url: URL(string: "https://support.apple.com/en-us/120278")!)
        }
        .fullScreenCover(isPresented: $showingSymptomSurvey) {
            NavigationView {
                SymptomSurveyView(isPresented: $isPresented, shouldIncludePartOf: $shouldIncludePartOf)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
} 
