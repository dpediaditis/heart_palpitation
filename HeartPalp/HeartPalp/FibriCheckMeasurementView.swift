import SwiftUI

struct FibriCheckMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
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
            
            HStack(spacing: 12) {
                Image("fibricheck-logo") // Make sure to add this image to your assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Text("Measurements will be collected via FibriCheck")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            
            Spacer()
            
            Button(action: {
                isPresented = false
                if let url = URL(string: "https://fibricheck.app.link/?screen=start_measurement") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Continue to FibriCheck Measurement")
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
    }
}

#Preview {
    FibriCheckMeasurementView(isPresented: .constant(true))
} 