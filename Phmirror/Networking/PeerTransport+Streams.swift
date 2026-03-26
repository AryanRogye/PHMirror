import Foundation
import MultipeerConnectivity

// MARK: - Stream Management

extension PeerTransport {

    func openOutputStreamIfNeeded(to peerID: MCPeerID) {
        guard role == .host else { return }
        guard outputStreams[peerID] == nil else { return }

        do {
            let stream = try session.startStream(withName: Self.streamName, toPeer: peerID)
            stream.schedule(in: .main, forMode: .default)
            stream.open()
            outputStreams[peerID] = stream
            publishCurrentOutputStream()
        } catch {
            publishStatus("Stream open error: \(error.localizedDescription)")
        }
    }

    func closeOutputStream(for peerID: MCPeerID) {
        guard let stream = outputStreams.removeValue(forKey: peerID) else { return }
        closeStream(stream)
        publishCurrentOutputStream()
    }

    func closeInputStream(for peerID: MCPeerID) {
        guard let stream = inputStreams.removeValue(forKey: peerID) else { return }
        closeStream(stream)
        publishCurrentInputStream()
    }

    func closeAllStreams() {
        for stream in outputStreams.values {
            closeStream(stream)
        }
        outputStreams.removeAll()

        for stream in inputStreams.values {
            closeStream(stream)
        }
        inputStreams.removeAll()

        publishCurrentOutputStream()
        publishCurrentInputStream()
    }

    func closeStream(_ stream: Stream) {
        unregisterOutputStream(stream)
        unregisterInputStream(stream)
        stream.delegate = nil
        stream.remove(from: .main, forMode: .default)
        stream.close()
    }

    func unregisterOutputStream(_ stream: Stream) {
        outputStreams = outputStreams.filter { $0.value !== stream }
    }

    func unregisterInputStream(_ stream: Stream) {
        inputStreams = inputStreams.filter { $0.value !== stream }
    }

    func publishCurrentOutputStream() {
        let stream = currentOutputStream
        DispatchQueue.main.async { [weak self] in
            self?.onOutputStreamChanged?(stream)
        }
    }

    func publishCurrentInputStream() {
        let stream = currentInputStream
        DispatchQueue.main.async { [weak self] in
            self?.onInputStreamChanged?(stream)
        }
    }
}
