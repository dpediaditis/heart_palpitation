import SwiftUI
import SafariServices

struct ECGMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingECGGuide = false
    
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
                    // TODO: Navigate to symptom survey
                    dismiss()
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
                    // TODO: Skip to symptom survey
                    dismiss()
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
                    dismiss()
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
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
} 