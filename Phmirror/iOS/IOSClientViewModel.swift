#if os(iOS)

import Combine
import Foundation
import UIKit

@MainActor
final class IOSClientViewModel: ObservableObject {
    enum NetworkPhase {
        case idle
        case searching
        case inviting
        case connecting
        case connected
        case disconnected
        case error
    }

    @Published var connectionStatus = "Idle"
    @Published var networkPhase: NetworkPhase = .idle
    @Published var connectedPeers: [String] = []
    @Published var latestFrame: UIImage?
    @Published var frameInfo = FrameInfo(width: 16, height: 9)
    @Published var isReceivingFrames = false

    private let transport = PeerTransport(role: .client)

    init() {
        transport.onStatusChanged = { [weak self] status in
            self?.connectionStatus = status
            self?.networkPhase = Self.phase(for: status)
        }

        transport.onPeersChanged = { [weak self] peers in
            self?.connectedPeers = peers
            if peers.isEmpty, self?.networkPhase == .connected {
                self?.networkPhase = .disconnected
            }
        }

        transport.onFrameInfo = { [weak self] info in
            self?.frameInfo = info
        }

        transport.onFrameData = { [weak self] frameData in
            guard let self, let image = UIImage(data: frameData) else { return }
            self.latestFrame = image
            self.isReceivingFrames = true
        }
    }

    deinit {
        transport.stop()
    }

    func start() {
        transport.start()
    }

    func stop() {
        transport.stop()
        isReceivingFrames = false
    }

    func reconnect() {
        isReceivingFrames = false
        transport.stop()
        transport.start()
    }

    func sendPointer(_ event: PointerEvent) {
        transport.sendPointer(event)
    }

    func sendScroll(_ event: ScrollEvent) {
        transport.sendScroll(event)
    }

    func sendKeyboard(_ event: KeyboardEvent) {
        transport.sendKeyboard(event)
    }

    private static func phase(for status: String) -> NetworkPhase {
        let lower = status.lowercased()

        if lower.contains("error") || lower.contains("failed") {
            return .error
        }
        if lower.contains("inviting") {
            return .inviting
        }
        if lower.contains("connecting") {
            return .connecting
        }
        if lower.contains("connected to") {
            return .connected
        }
        if lower.contains("searching") || lower.contains("retrying") {
            return .searching
        }
        if lower.contains("disconnected") || lower.contains("not connected") {
            return .disconnected
        }

        return .idle
    }
}

#endif
