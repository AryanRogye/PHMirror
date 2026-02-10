import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        MacHostView(viewModel: MacHostViewModel())
        #elseif os(iOS)
        IOSClientView()
        #else
        Text("Phmirror is currently supported on macOS and iOS.")
            .padding()
        #endif
    }
}

#Preview {
    ContentView()
}
