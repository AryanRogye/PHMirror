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
            handle(ScreenInfo.self, payload, onReceive: onFrameInfo)
            
        case .fps:
            handle(FPS.self, payload, onReceive: onFPSInfo)

        case .videoScale:
            handle(VideoScale.self, payload, onReceive: onVideoScale)

        case .pointer:
            handle(PointerEvent.self, payload, onReceive: onPointerEvent)

        case .scroll:
            handle(ScrollEvent.self, payload, onReceive: onScrollEvent)

        case .keyboard:
            handle(KeyboardEvent.self, payload, onReceive: onKeyboardEvent)
        }
    }
    
    func handle<T: Decodable>(
        _ type: T.Type,
        _ data: Data,
        onReceive: ((T) -> Void)?
    ) {
        guard let decoded: T = try? JSONDecoder().decode(type, from: data) else { return }
        onReceive?(decoded)
    }
}
