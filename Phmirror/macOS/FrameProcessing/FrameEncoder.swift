#if os(macOS)

import CoreImage
import CoreMedia
import Foundation
import ImageIO
import UniformTypeIdentifiers

final class FrameEncoder {
    private let context = CIContext()

    func encodeJPEG(sampleBuffer: CMSampleBuffer,
                    maxDimension: CGFloat = 1_280,
                    quality: CGFloat = 0.5) -> (data: Data, size: CGSize)? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent

        guard extent.width > 0, extent.height > 0 else { return nil }

        let scale = min(1.0, maxDimension / max(extent.width, extent.height))
        let outputImage = scale < 1.0
            ? ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            : ciImage

        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }

        return (outputData as Data, outputImage.extent.size)
    }
}

#endif
