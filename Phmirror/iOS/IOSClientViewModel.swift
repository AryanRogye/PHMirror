#if os(iOS)

import AVFoundation
import Combine
import CoreImage
import Foundation
import UIKit
import VideoToolbox
import SnapCoreEngine
import SnapCore
import SwiftUI

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
    @Published var frameInfo = ScreenInfo(width: 16, height: 9)
    @Published var isReceivingFrames = false
    
    @AppStorage("ControlEnabled") var controlEnabled = true
    @AppStorage("InvertX") var invertX = false
    @AppStorage("InvertY") var invertY = false
    @Published var videoScale: VideoScale = .normal
    @Published var fps: FPS = .fps120

    private let transport = PeerTransport(role: .client)
    private let liveStreamDecoder : LiveFileWritingDecoder = LiveFileWritingDecoder()

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
            if peers.isEmpty {
                self?.liveStreamDecoder.stop()
                self?.isReceivingFrames = false
            }
        }

        transport.onInputStreamChanged = { [weak self] stream in
            guard let self else { return }

            guard let stream else {
                self.liveStreamDecoder.stop()
                self.isReceivingFrames = false
                return
            }

            self.liveStreamDecoder.start(stream: stream)
        }

        transport.onFrameInfo = { [weak self] info in
            DispatchQueue.main.async {
                self?.frameInfo = info
            }
        }

        transport.onFrameData = { [weak self] frameData in
            guard let self, let image = UIImage(data: frameData) else { return }
            DispatchQueue.main.async {
                self.latestFrame = image
                self.isReceivingFrames = true
            }
        }

        liveStreamDecoder.onFrameImage = { [weak self] (image: CGImage, frameInfo: (width: CGFloat, height: CGFloat)) -> Void in
            guard let self else { return }
            self.latestFrame = UIImage(cgImage: image)
            self.frameInfo = ScreenInfo(width: Int(frameInfo.width), height: Int(frameInfo.height))
            self.isReceivingFrames = true
        }

        liveStreamDecoder.onStatus = { [weak self] (status: String) in
            guard let self else { return }
            if self.connectedPeers.isEmpty { return }
            self.connectionStatus = status
        }
    }

    deinit {
        liveStreamDecoder.stop()
        transport.stop()
    }

    func start() {
        transport.start()
    }

    func stop() {
        liveStreamDecoder.stop()
        transport.stop()
        isReceivingFrames = false
    }

    func reconnect() {
        liveStreamDecoder.stop()
        isReceivingFrames = false
        transport.stop()
        transport.start()
    }
    
    public func sendClick(atRawPoint rawPoint: CGPoint) {
        guard controlEnabled else { return }
        sendPointer(phase: .down, atRawPoint: rawPoint, primaryDown: true)
        sendPointer(phase: .up, atRawPoint: rawPoint, primaryDown: false)
    }
    
    public func sendPointer(
        phase: PointerPhase,
        atRawPoint rawPoint: CGPoint,
        primaryDown: Bool
    ) {
        let point = applyAxisAdjustments(to: rawPoint)
        sendPointer(
            PointerEvent(
                x: point.x,
                y: point.y,
                phase: phase,
                isPrimaryButtonDown: primaryDown
            )
        )
    }
    
    private func applyAxisAdjustments(to point: CGPoint) -> CGPoint {
        CGPoint(
            x: invertX ? 1 - point.x : point.x,
            y: invertY ? 1 - point.y : point.y
        )
    }
    
    func sendVideoScale(_ event: VideoScale) {
        transport.sendVideoScale(event)
    }
    
    func sendFPS(_ event: FPS) {
        transport.sendFPS(event)
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
