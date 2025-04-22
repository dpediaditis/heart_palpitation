import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()    // see step 5
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 14")
    }
}
#endif
