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

## Examples
this is me asking Codex 5.3 to build a random app that generates a random color on every tap, all built while taking a shit, but this can be used for a whole other range of things

<img width="225" height="430" src="https://github.com/user-attachments/assets/47051478-6f54-4dbf-b057-0a884adb1865" />
<img width="225" height="430" src="https://github.com/user-attachments/assets/51d9a87d-66e6-48d9-be84-3f1c9ee42c72" />
<img width="225" height="430" src="https://github.com/user-attachments/assets/d20681c3-72fc-4899-a015-e7014433123e" />
<img width="225" height="430" src="https://github.com/user-attachments/assets/5ba708fa-bb62-4bff-ab17-b5937805071e" />
<img width="225" height="430" src="https://github.com/user-attachments/assets/8525a0a3-881e-4d4d-be5a-2dce907592ab" />

## Why I Built this
[SnapCore](https://github.com/AryanRogye/SnapCore) is the main core that the app is built on top of, this was built by me a few months ago
Wanted to test out Codex 5.3 while playing video games, a friend told me a sick idea for a app where he could control his mac from his bed,
so with 1 prompt + a few polishes added by me, I was able to spit out a fully functional app

## License
This project is licensed under the MIT License. See `LICENSE`.
