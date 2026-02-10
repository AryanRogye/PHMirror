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

        framePipeline.onFrameSize = { [weak self] size in
            Task { @MainActor [weak self] in
                self?.lastFrameSizeText = "\(Int(size.width)) x \(Int(size.height))"
                self?.sharingPhase = .streaming
            }
        }

        recorder.onScreenFrame = { [framePipeline] sample in
            framePipeline.process(sample)
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
            recorder.startRecording(scale: .normal, showsCursor: true, capturesAudio: false)
            connectionStatus = "Grant Screen Recording permission in System Settings, then relaunch."
            hostPhase = .error
            return
        }

        framePipeline.reset()
        lastError = nil
        isSharing = true
        sharingPhase = .waitingForPicker

        recorder.startRecording(scale: .normal, showsCursor: true, capturesAudio: false)
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
}

private final class FramePipeline {
    private let transport: PeerTransport
    private let frameEncoder = FrameEncoder()
    private var lastFrameSendTime = ContinuousClock.now
    private let frameInterval: Duration = .milliseconds(90)
    private var sentFrameInfo = false

    var onFrameSize: ((CGSize) -> Void)?

    init(transport: PeerTransport) {
        self.transport = transport
    }

    func reset() {
        sentFrameInfo = false
        lastFrameSendTime = ContinuousClock.now
    }

    func process(_ sample: CMSampleBuffer) {
        let now = ContinuousClock.now
        guard now - lastFrameSendTime >= frameInterval else { return }
        lastFrameSendTime = now

        guard let encoded = frameEncoder.encodeJPEG(sampleBuffer: sample) else { return }

        transport.sendFrame(encoded.data)

        if !sentFrameInfo {
            let frameInfo = FrameInfo(width: Int(encoded.size.width), height: Int(encoded.size.height))
            transport.sendFrameInfo(frameInfo)
            sentFrameInfo = true
        }

        onFrameSize?(encoded.size)
    }
}

#endif
