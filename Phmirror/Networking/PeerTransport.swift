import Foundation
import MultipeerConnectivity

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import SnapCore

// MARK: - Core

final class PeerTransport: NSObject {
    enum Role {
        case host
        case client
    }

    internal static let streamName = "phmirror-wire"
    internal let role: Role
    internal let serviceType = "phmirrorctrl"
    internal let session: MCSession
    internal var advertiser: MCNearbyServiceAdvertiser?
    internal var browser: MCNearbyServiceBrowser?
    internal var invitedPeers = Set<MCPeerID>()
    internal var lastInviteAt: [MCPeerID: ContinuousClock.Instant] = [:]
    internal let inviteCooldown: Duration = .seconds(8)
    internal let clock = ContinuousClock()
    internal var browserRetryScheduled = false
    internal var outputStreams: [MCPeerID: OutputStream] = [:]
    internal var inputStreams: [MCPeerID: InputStream] = [:]

    var onStatusChanged: ((String) -> Void)?
    var onPeersChanged: (([String]) -> Void)?
    var onFrameData: ((Data) -> Void)?
    var onFrameInfo: ((ScreenInfo) -> Void)?
    var onFPSInfo: ((FPS) -> Void)?
    var onVideoScale: ((VideoScale) -> Void)?
    var onPointerEvent: ((PointerEvent) -> Void)?
    var onScrollEvent: ((ScrollEvent) -> Void)?
    var onKeyboardEvent: ((KeyboardEvent) -> Void)?
    var onOutputStreamChanged: ((OutputStream?) -> Void)?
    var onInputStreamChanged: ((InputStream?) -> Void)?
    var currentOutputStream: OutputStream? { outputStreams.values.first }
    var currentInputStream: InputStream? { inputStreams.values.first }

    init(role: Role) {
        self.role = role
        let peerID = MCPeerID(displayName: Self.deviceName())
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    deinit {
        stop()
    }

    func start() {
        stop()
        switch role {
        case .host:
            let discoveryInfo = ["role": "host"]
            let advertiser = MCNearbyServiceAdvertiser(peer: session.myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()
            self.advertiser = advertiser
            publishStatus("Hosting as \(session.myPeerID.displayName). Waiting for iPhone...")
        case .client:
            let browser = MCNearbyServiceBrowser(peer: session.myPeerID, serviceType: serviceType)
            browser.delegate = self
            browser.startBrowsingForPeers()
            self.browser = browser
            publishStatus("Searching for Mac host...")
        }
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        invitedPeers.removeAll()
        lastInviteAt.removeAll()
        browserRetryScheduled = false
        closeAllStreams()
        session.disconnect()
        publishStatus("Disconnected")
        publishPeers([String]())
    }

    // MARK: - Helpers

    static func deviceName() -> String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? "Phmirror Mac"
        #else
        return "Phmirror Device"
        #endif
    }

    func publishStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onStatusChanged?(status)
        }
    }

    func publishPeers(_ peerIDs: [MCPeerID]) {
        let names = peerIDs.map(\.displayName)
        publishPeers(names)
    }

    func publishPeers(_ names: [String]) {
        DispatchQueue.main.async { [weak self] in
            self?.onPeersChanged?(names)
        }
    }

    func describeNetServiceError(_ error: Error, for operation: String) -> String {
        let nsError = error as NSError
        if nsError.domain == NetService.errorDomain && nsError.code == -72008 {
            return "\(operation) failed: missing Bonjour config in Info.plist (NSBonjourServices)."
        }

        return "\(operation) failed: \(nsError.domain) (\(nsError.code)) \(nsError.localizedDescription)"
    }

    func scheduleBrowserRetryIfNeeded() {
        guard role == .client else { return }
        guard !browserRetryScheduled else { return }
        guard let browser else { return }
        browserRetryScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak browser] in
            guard let self, let browser else { return }
            self.browserRetryScheduled = false
            browser.stopBrowsingForPeers()
            browser.startBrowsingForPeers()
            self.publishStatus("Retrying discovery...")
        }
    }
}
