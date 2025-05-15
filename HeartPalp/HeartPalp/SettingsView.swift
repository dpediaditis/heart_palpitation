import SwiftUI

struct SettingsView: View {
    @AppStorage("fibriCheckEnabled") private var fibriCheckEnabled = false
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Digital Prescriptions")) {
                    HStack {
                        Image("fibricheck-logo") // Make sure to add this image to your assets
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        Text("FibriCheck")
                        Spacer()
                        Toggle("", isOn: $fibriCheckEnabled)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(leading: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            })
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
} 