import SwiftUI

@main
struct PhmirrorApp: App {
    #if os(macOS)
    @StateObject private var hostViewModel = MacHostViewModel()
    #endif

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("Phmirror", systemImage: "display.2") {
            MacHostView(viewModel: hostViewModel)
                .frame(width: 460)
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
