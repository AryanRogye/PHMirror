import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        Root()
        #else
        Text("Phmirror is currently supported on macOS and iOS.")
            .padding()
        #endif
    }
}

#Preview {
    ContentView()
}
