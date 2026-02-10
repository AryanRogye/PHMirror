import Foundation
import MultipeerConnectivity

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class PeerTransport: NSObject {
    enum Role {
        case host
        case client
    }

    private let role: Role
    private let serviceType = "phmirrorctrl"
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var invitedPeers = Set<MCPeerID>()
    private var lastInviteAt: [MCPeerID: ContinuousClock.Instant] = [:]
    private let inviteCooldown: Duration = .seconds(8)
    private let clock = ContinuousClock()
    private var browserRetryScheduled = false

    var onStatusChanged: ((String) -> Void)?
    var onPeersChanged: (([String]) -> Void)?
    var onFrameData: ((Data) -> Void)?
    var onFrameInfo: ((FrameInfo) -> Void)?
    var onPointerEvent: ((PointerEvent) -> Void)?
    var onScrollEvent: ((ScrollEvent) -> Void)?
    var onKeyboardEvent: ((KeyboardEvent) -> Void)?

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
        session.disconnect()
        publishStatus("Disconnected")
        publishPeers([String]())
    }

    func sendFrame(_ frameData: Data) {
        send(payload: frameData, as: .frame, mode: .unreliable)
    }

    func sendFrameInfo(_ frameInfo: FrameInfo) {
        guard let data = try? JSONEncoder().encode(frameInfo) else { return }
        send(payload: data, as: .frameInfo, mode: .reliable)
    }

    func sendPointer(_ event: PointerEvent) {
        guard let data = try? JSONEncoder().encode(event) else { return }
        send(payload: data, as: .pointer, mode: .reliable)
    }

    func sendScroll(_ event: ScrollEvent) {
        guard let data = try? JSONEncoder().encode(event) else { return }
        send(payload: data, as: .scroll, mode: .unreliable)
    }

    func sendKeyboard(_ event: KeyboardEvent) {
        guard let data = try? JSONEncoder().encode(event) else { return }
        send(payload: data, as: .keyboard, mode: .reliable)
    }

    private func send(payload: Data, as packetType: WirePacketType, mode: MCSessionSendDataMode) {
        guard !session.connectedPeers.isEmpty else { return }

        var packet = Data([packetType.rawValue])
        packet.append(payload)

        do {
            try session.send(packet, toPeers: session.connectedPeers, with: mode)
        } catch {
            publishStatus("Send error: \(error.localizedDescription)")
        }
    }

    private func receive(_ data: Data) {
        guard let typeByte = data.first, let packetType = WirePacketType(rawValue: typeByte) else {
            return
        }

        let payload = data.dropFirst()

        switch packetType {
        case .frame:
            onFrameData?(Data(payload))

        case .frameInfo:
            guard let frameInfo = try? JSONDecoder().decode(FrameInfo.self, from: payload) else { return }
            onFrameInfo?(frameInfo)

        case .pointer:
            guard let pointerEvent = try? JSONDecoder().decode(PointerEvent.self, from: payload) else { return }
            onPointerEvent?(pointerEvent)

        case .scroll:
            guard let scrollEvent = try? JSONDecoder().decode(ScrollEvent.self, from: payload) else { return }
            onScrollEvent?(scrollEvent)

        case .keyboard:
            guard let keyboardEvent = try? JSONDecoder().decode(KeyboardEvent.self, from: payload) else { return }
            onKeyboardEvent?(keyboardEvent)
        }
    }

    private static func deviceName() -> String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? "Phmirror Mac"
        #else
        return "Phmirror Device"
        #endif
    }

    private func publishStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onStatusChanged?(status)
        }
    }

    private func publishPeers(_ peerIDs: [MCPeerID]) {
        let names = peerIDs.map(\.displayName)
        publishPeers(names)
    }

    private func publishPeers(_ names: [String]) {
        DispatchQueue.main.async { [weak self] in
            self?.onPeersChanged?(names)
        }
    }

    private func describeNetServiceError(_ error: Error, for operation: String) -> String {
        let nsError = error as NSError
        if nsError.domain == NetService.errorDomain && nsError.code == -72008 {
            return "\(operation) failed: missing Bonjour config in Info.plist (NSBonjourServices)."
        }

        return "\(operation) failed: \(nsError.domain) (\(nsError.code)) \(nsError.localizedDescription)"
    }

    private func scheduleBrowserRetryIfNeeded() {
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

extension PeerTransport: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let stateText: String
        switch state {
        case .notConnected:
            invitedPeers.remove(peerID)
            stateText = "Not connected"
        case .connecting:
            stateText = "Connecting to \(peerID.displayName)..."
        case .connected:
            invitedPeers.remove(peerID)
            stateText = "Connected to \(peerID.displayName)"
        @unknown default:
            stateText = "Unknown connection state"
        }

        publishStatus(stateText)
        publishPeers(session.connectedPeers)
    }

    func session(_ session: MCSession,
                 didReceiveCertificate certificate: [Any]?,
                 fromPeer peerID: MCPeerID,
                 certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receive(data)
    }

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
    }

    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
    }

    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
    }
}

extension PeerTransport: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        publishStatus("Accepting invitation from \(peerID.displayName)")
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        publishStatus(describeNetServiceError(error, for: "Advertiser"))
    }
}

extension PeerTransport: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard role == .client else { return }
        guard !session.connectedPeers.contains(peerID), !invitedPeers.contains(peerID) else { return }
        if let peerRole = info?["role"], peerRole != "host" { return }

        if let lastInviteTime = lastInviteAt[peerID], clock.now - lastInviteTime < inviteCooldown {
            return
        }

        invitedPeers.insert(peerID)
        lastInviteAt[peerID] = clock.now
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        publishStatus("Inviting \(peerID.displayName)...")
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        invitedPeers.remove(peerID)
        publishStatus("Lost \(peerID.displayName)")
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        publishStatus(describeNetServiceError(error, for: "Browser"))
        scheduleBrowserRetryIfNeeded()
    }
}
