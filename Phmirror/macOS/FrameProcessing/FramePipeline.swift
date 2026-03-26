#if os(macOS)
import CoreMedia
import Foundation
import SnapCore

public final class FramePipeline {
    private let transport: PeerTransport
    private let frameEncoder = FrameEncoder()
    private var lastFrameSendTime = ContinuousClock.now
    private let frameInterval: Duration = .milliseconds(90)
    private var sentFrameInfo = false

    var onFrameSize: ((CGSize) -> Void)?

    init(transport: PeerTransport) {
        self.transport = transport
    }

    func reset() {
        sentFrameInfo = false
        lastFrameSendTime = ContinuousClock.now
    }

    func process(_ sample: CMSampleBuffer) {
        let now = ContinuousClock.now
        guard now - lastFrameSendTime >= frameInterval else { return }
        lastFrameSendTime = now

        guard let encoded = frameEncoder.encodeJPEG(sampleBuffer: sample) else { return }

        transport.sendFrame(encoded.data)

        if !sentFrameInfo {
            let frameInfo = ScreenInfo(width: Int(encoded.size.width), height: Int(encoded.size.height))
            transport.sendFrameInfo(frameInfo)
            sentFrameInfo = true
        }

        onFrameSize?(encoded.size)
    }
}

#endif
