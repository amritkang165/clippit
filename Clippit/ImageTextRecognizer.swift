// Purpose: Extract text from local images with Vision off the main actor, without uploading data.
import Foundation
import ImageIO
import Vision
import CoreML
import os

actor ImageTextRecognizer {
    static let shared = ImageTextRecognizer()

    func recognize(at url: URL, cpuOnly: Bool = false) throws -> String {
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
        return try Self.withFallback(cpuOnly: cpuOnly) { attempt in
            // A failed request can retain execution state: never retry the same instance.
            let request = VNRecognizeTextRequest()
            request.revision = attempt.revision
            request.recognitionLevel = .accurate
            request.automaticallyDetectsLanguage = attempt.revision >= VNRecognizeTextRequestRevision3
            request.usesLanguageCorrection = true
            if attempt.cpu {
                let stages = try request.supportedComputeStageDevices
                guard !stages.isEmpty else { throw RecognitionError.cpuUnavailable }
                for (stage, devices) in stages {
                    guard let cpu = devices.first(where: {
                        if case .cpu = $0 { return true }
                        return false
                    }) else { throw RecognitionError.cpuUnavailable }
                    request.setComputeDevice(cpu, for: stage)
                }
            }
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
            return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    struct Attempt: Equatable {
        let revision: Int
        let cpu: Bool
    }

    static func withFallback(cpuOnly: Bool = false,
                             revision: Int = VNRecognizeTextRequest.defaultRevision,
                             supported: IndexSet = VNRecognizeTextRequest.supportedRevisions,
                             perform: (Attempt) throws -> String) throws -> String {
        var attempts = cpuOnly ? [] : [Attempt(revision: revision, cpu: false)]
        attempts.append(Attempt(revision: revision, cpu: true))
        // Older supported Vision revisions can avoid a broken platform compute backend.
        if let older = supported.filter({ $0 < revision }).max() {
            attempts.append(Attempt(revision: older, cpu: true))
        }
        let logger = Logger(subsystem: "com.clippit.app", category: "ImageTextRecognition")
        for attempt in attempts {
            try Task.checkCancellation()
            do {
                let text = try perform(attempt)
                try Task.checkCancellation()
                return text
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                try Task.checkCancellation()
                // Never log image paths, contents or arbitrary underlying error descriptions.
                let phase = attempt.cpu ? "cpu" : "accelerated"
                let code = (error as NSError).code
                logger.error("OCR failed: phase=\(phase, privacy: .public) revision=\(attempt.revision) code=\(code)")
            }
        }
        throw RecognitionError.unavailable
    }

    enum RecognitionError: LocalizedError {
        case invalidImage, cpuUnavailable, unavailable

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "The saved image could not be read. It may have been moved, deleted, or damaged."
            case .cpuUnavailable:
                return "On-device text recognition could not use the CPU on this Mac."
            case .unavailable:
                return "Text recognition is temporarily unavailable on this Mac. Try again or try another image. Your saved image is unchanged."
            }
        }
    }
}
