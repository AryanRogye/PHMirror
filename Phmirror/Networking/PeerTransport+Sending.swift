import Foundation
import MultipeerConnectivity
import SnapCore

// MARK: - Sending

extension PeerTransport {

    func sendFrame(_ frameData: Data) {
        send(frameData, as: .frame, mode: .unreliable, encode: false)
    }

    func sendFrameInfo(_ frameInfo: ScreenInfo) {
        send(frameInfo, as: .frameInfo, mode: .reliable)
    }
    
    func sendFPS(_ event: FPS) {
        send(event, as: .fps, mode: .reliable)
    }
    
    func sendVideoScale(_ event: VideoScale) {
        send(event, as: .videoScale, mode: .reliable)
    }

    func sendPointer(_ event: PointerEvent) {
        send(event, as: .pointer, mode: .reliable)
    }

    func sendScroll(_ event: ScrollEvent) {
        send(event, as: .scroll, mode: .unreliable)
    }

    func sendKeyboard(_ event: KeyboardEvent) {
        send(event, as: .keyboard, mode: .reliable)
    }
    
    func send<T: Encodable>(
        _ event: T,
        as type: WirePacketType,
        mode: MCSessionSendDataMode,
        encode: Bool = true
    ) {
        var data: Data
        if encode {
            guard let encoded = try? JSONEncoder().encode(event) else { return }
            data = encoded
        } else {
            guard let dt = event as? Data else { return }
            data = dt
        }
        
        guard !session.connectedPeers.isEmpty else { return }
        
        let packet = makeSessionPacket(payload: data, type: type)
        
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
