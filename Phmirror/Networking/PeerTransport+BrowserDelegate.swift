import Foundation
import MultipeerConnectivity

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerTransport: MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
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

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        invitedPeers.remove(peerID)
        publishStatus("Lost \(peerID.displayName)")
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        publishStatus(describeNetServiceError(error, for: "Browser"))
        scheduleBrowserRetryIfNeeded()
    }
}
