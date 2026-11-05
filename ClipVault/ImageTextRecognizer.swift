// Purpose: Extract text from local images with Vision off the main actor, without uploading data.
import Foundation
import ImageIO
import Vision
import CoreML

actor ImageTextRecognizer {
    static let shared = ImageTextRecognizer()

    func recognize(at url: URL) throws -> String {
        try Task.checkCancellation()
        guard url.isFileURL else { throw RecognitionError.invalidImage }
        // Bound decoding cost and honor image orientation without changing the saved file.
        guard let source = CGImageSourceCreateWithURL(url as CFURL,
                [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 4096
              ] as CFDictionary) else { throw RecognitionError.invalidImage }
        try Task.checkCancellation()
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            try Task.checkCancellation()
            // Some Macs cannot initialize Vision's accelerated execution path.
            // Retry on the CPU using the compute-device APIs available in macOS 14.
            var assignedCPU = false
            for (stage, devices) in try request.supportedComputeStageDevices {
                if let cpu = devices.first(where: {
                    if case .cpu = $0 { return true }
                    return false
                }) {
                    request.setComputeDevice(cpu, for: stage)
                    assignedCPU = true
                }
            }
            guard assignedCPU else { throw error }
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        }
        // A view can disappear during synchronous Vision work. Discard that result.
        try Task.checkCancellation()
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum RecognitionError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            "The saved image could not be read. It may have been moved, deleted, or damaged."
        }
    }
}
