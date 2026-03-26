#if os(macOS)

import Combine
import CoreMedia
import Foundation
import SnapCore

@MainActor
final class MacHostViewModel: ObservableObject {
    enum HostPhase {
        case idle
        case waitingForClient
        case connecting
        case connected
        case error
    }

    enum SharingPhase {
        case notSharing
        case waitingForPicker
        case streaming
    }

    @Published var connectionStatus = "Idle"
    @Published var connectedPeers: [String] = []
    @Published var isSharing = false
    @Published var isHosting = false
    @Published var hostPhase: HostPhase = .idle
    @Published var sharingPhase: SharingPhase = .notSharing
    @Published var lastFrameSizeText = "-"
    @Published var lastError: String?

    private let transport = PeerTransport(role: .host)
    private let recorder = ScreenRecordService()
    private let framePipeline: FramePipeline
    
    @Published var videoScale: VideoScale = .normal
    @Published var fps: FPS = .fps120

    init() {
        framePipeline = FramePipeline(transport: transport)

        transport.onStatusChanged = { [weak self] status in
            self?.connectionStatus = status
            self?.hostPhase = Self.phase(for: status)
        }

        transport.onPeersChanged = { [weak self] peers in
            self?.connectedPeers = peers
        }

        transport.onPointerEvent = { event in
            PointerInputInjector.inject(event)
        }

        transport.onScrollEvent = { event in
            PointerInputInjector.injectScroll(event)
        }

        transport.onKeyboardEvent = { event in
            PointerInputInjector.injectKeyboard(event)
        }
        
        transport.onVideoScale = { [weak self] scale in
            DispatchQueue.main.async {
                self?.videoScale = scale
                self?.restartSharing()
            }
        }
        transport.onFPSInfo = { [weak self] fps in
            DispatchQueue.main.async {
                self?.fps = fps
                self?.restartSharing()
            }
        }

        /// When we get a frame, we can update the UI to show the frame size
        framePipeline.onFrameSize = { [weak self] size in
            Task { @MainActor [weak self] in
                self?.lastFrameSizeText = "\(Int(size.width)) x \(Int(size.height))"
                self?.sharingPhase = .streaming
            }
        }

        /// When we get a frame from the recorder, we process it
        recorder.onScreenFrame = { [framePipeline] sample in
            framePipeline.process(sample.buffer)
        }
    }

    deinit {
        transport.stop()
    }

    func startHosting() {
        guard !isHosting else { return }
        transport.start()
        isHosting = true
    }

    func stopHosting() {
        guard isHosting else { return }
        transport.stop()
        isHosting = false
        hostPhase = .idle
    }

    func startSharing() {
        if !isHosting {
            startHosting()
        }

        guard recorder.hasScreenRecordPermission() else {
            connectionStatus = "Grant Screen Recording permission in System Settings, then relaunch."
            hostPhase = .error
            return
        }

        framePipeline.reset()
        lastError = nil
        isSharing = true
        sharingPhase = .waitingForPicker

        recorder.startRecording(
            scale: videoScale,
            showsCursor: true,
            capturesAudio: false,
            fps: fps
        )
        connectionStatus = "Pick a display in the system content picker."
    }

    func stopSharing() {
        Task { @MainActor in
            await recorder.stopRecording()
            isSharing = false
            sharingPhase = .notSharing
        }
    }

    private static func phase(for status: String) -> HostPhase {
        let lower = status.lowercased()

        if lower.contains("error") || lower.contains("failed") {
            return .error
        }
        if lower.contains("connected") {
            return .connected
        }
        if lower.contains("connecting") || lower.contains("inviting") {
            return .connecting
        }
        if lower.contains("hosting") || lower.contains("searching") || lower.contains("waiting") {
            return .waitingForClient
        }
        return .idle
    }
    
    func restartSharing() {
        Task { @MainActor in
            await recorder.stopRecording()
            
            framePipeline.reset()
            lastError = nil
            sharingPhase = .waitingForPicker
            isSharing = true
            
            recorder.startRecording(
                scale: videoScale,
                showsCursor: true,
                capturesAudio: false,
                fps: fps
            )
            
            connectionStatus = "Pick a display in the system content picker."
        }
    }
}

#endif
