# Phmirror

Phmirror is a SwiftUI app for local macOS <-> iOS screen/control workflows over `MultipeerConnectivity`.

- macOS side hosts and streams frames.
- iOS side discovers the host and sends pointer/scroll/keyboard input.
- Discovery runs over Bonjour (`_phmirrorctrl._tcp`) on the local network.

## Requirements

- Xcode 16+
- macOS and iOS devices on the same local network
- Internet access to resolve Swift package dependencies (includes `SnapCore`)

## Build and Run

1. Open `Phmirror.xcodeproj` in Xcode.
2. Let Swift Package Manager resolve dependencies (`SnapCore` from GitHub).
3. Select a macOS run destination and run to start the host menu bar app.
4. Select an iOS device/simulator and run to start the client app.
5. Grant Local Network/Bluetooth permissions when prompted.

## Open Source Notes

Before publishing or accepting external contributors:

1. Keep release binaries out of source control (`updates/Phmirror.app`, `updates/Phmirror-Installer.dmg` are ignored by `.gitignore`).
2. Keep Xcode user-specific files out of source control (`xcuserdata`, `*.xcuserstate` are ignored by `.gitignore`).
3. Consider switching to a neutral bundle ID for public forks if needed.

## License

This project is licensed under the MIT License. See `LICENSE`.
