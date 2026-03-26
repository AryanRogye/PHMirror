import Foundation
import MultipeerConnectivity
import SnapCore
// MARK: - MCSessionDelegate

extension PeerTransport: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let stateText: String
        switch state {
        case .notConnected:
            invitedPeers.remove(peerID)
            closeOutputStream(for: peerID)
            closeInputStream(for: peerID)
            stateText = "Not connected"
        case .connecting:
            stateText = "Connecting to \(peerID.displayName)..."
        case .connected:
            invitedPeers.remove(peerID)
            openOutputStreamIfNeeded(to: peerID)
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
        closeInputStream(for: peerID)
        inputStreams[peerID] = stream
        publishCurrentInputStream()
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

    // MARK: - Receiving

    func receive(_ data: Data) {
        guard let typeByte = data.first, let packetType = WirePacketType(rawValue: typeByte) else {
            return
        }

        let payload = data.dropFirst()

        switch packetType {
        case .frame:
            onFrameData?(Data(payload))

        case .frameInfo:
            guard let frameInfo = try? JSONDecoder().decode(ScreenInfo.self, from: payload) else { return }
            onFrameInfo?(frameInfo)
            
        case .videoScale:
            guard let videoScale = try? JSONDecoder().decode(VideoScale.self, from: payload) else { return }
            onVideoScale?(videoScale)

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
}
