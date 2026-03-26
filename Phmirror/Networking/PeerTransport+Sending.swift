import Foundation
import MultipeerConnectivity
import SnapCore

// MARK: - Sending

extension PeerTransport {

    func sendFrame(_ frameData: Data) {
        send(payload: frameData, as: .frame, mode: .unreliable)
    }

    func sendFrameInfo(_ frameInfo: ScreenInfo) {
        guard let data = try? JSONEncoder().encode(frameInfo) else { return }
        send(payload: data, as: .frameInfo, mode: .reliable)
    }
    
    func sendVideoScale(_ event: VideoScale) {
        guard let data = try? JSONEncoder().encode(event) else { return }
        send(payload: data, as: .videoScale, mode: .reliable)
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

    func send(payload: Data, as packetType: WirePacketType, mode: MCSessionSendDataMode) {
        guard !session.connectedPeers.isEmpty else { return }

        let packet = makeSessionPacket(payload: payload, type: packetType)

        do {
            try session.send(packet, toPeers: session.connectedPeers, with: mode)
        } catch {
            publishStatus("Send error: \(error.localizedDescription)")
        }
    }

    func makeSessionPacket(payload: Data, type: WirePacketType) -> Data {
        var packet = Data([type.rawValue])
        packet.append(payload)
        return packet
    }
}
