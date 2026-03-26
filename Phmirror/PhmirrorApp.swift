import SwiftUI

@main
struct PhmirrorApp: App {
    
    #if os(macOS)
    @StateObject private var hostViewModel = MacHostViewModel()
    @State private var permission = PermissionService()
    #endif

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra("Phmirror", systemImage: "display.2") {
            if permission.isAccessibilityEnabled {
                MacHostView(viewModel: hostViewModel)
                    .frame(width: 460)
            } else {
                PermissionView(permission: permission)
            }
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}


#if os(macOS)
struct PermissionView: View {
    
    @Bindable var permission: PermissionService
    @State private var clickedPermissions: Bool = false
    
    var body: some View {
        VStack {
            Text("👀 ComfyTile can’t see your windows yet.\nTurn on Accessibility so it can actually do its job.")
            
            Spacer()
            Button(action: {
                clickedPermissions = true
                permission.requestPermission()
            }) {
                if clickedPermissions {
                    Text("😐 macOS still pretending we don’t exist?")
                } else {
                    Text("Request Accessibility")
                }
            }
            if clickedPermissions {
                Text("Sometimes macOS is just being stubborn. 😅")
                Button(action: {
                    try? permission.resetAccessibility()
                }) {
                    Text("Reset Accessibility For ComfyTile")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
