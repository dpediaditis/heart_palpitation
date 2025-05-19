import SwiftUI

struct HeartEpisodeMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingECGMeasurement = false
    @State private var shouldIncludePartOf = false
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Start Measurement of Heart Episode")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
            
            Text("For serious symptoms or emergency")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("CALL 112")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Spacer()
            
            Button(action: {
                // Show ECG measurement view
                showingECGMeasurement = true
            }) {
                Text("Continue to measurement")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
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
        .fullScreenCover(isPresented: $showingECGMeasurement) {
            NavigationView {
                ECGMeasurementView(shouldIncludePartOf: $shouldIncludePartOf, isPresented: $isPresented)
            }
        }
    }
} 