import Vision
import UIKit
import PDFKit

class VisionOCRService {
    static let shared = VisionOCRService()
    
    private init() {}
    
    /// Extracts text from a UIImage using the Vision framework.
    /// - Parameter image: The image to perform OCR on.
    /// - Returns: The extracted text as a String.
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCLError.invalidImage
        }
        
        let recognizedText = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCLError.extractionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCLError.extractionFailed(error))
            }
        }
        
        return normalizeText(recognizedText)
    }
    
    /// Converts a PDF to images and extracts text from each page.
    func extractTextFromPDF(at url: URL) async throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw OCLError.invalidPDF
        }
        
        var combinedText = ""
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            
            // Render PDF page to image for Vision OCR (better for scanned docs)
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            let pageText = try await extractText(from: image)
            combinedText += pageText + "\n"
        }
        
        return combinedText
    }
    
    private func normalizeText(_ text: String) -> String {
        var result = text.lowercased()
        
        // Handle common OCR noise (e.g., "1l.l5%" -> "11.15%")
        // This is a bit aggressive, so we use regex to target specifically percentage-like patterns
        let percentageNoisePattern = #"(\d)[l|i|\|]\.(\d+)\s?%"#
        if let regex = try? NSRegularExpression(pattern: percentageNoisePattern, options: []) {
            let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: nsRange, withTemplate: "$11.$2%")
        }
        
        // Generic digit fix for mixed characters
        result = result.replacingOccurrences(of: "l", with: "1", options: .regularExpression)
                       .replacingOccurrences(of: #"\|"#, with: "1", options: .regularExpression)
        
        // Remove extra spaces
        result = result.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum OCLError: LocalizedError {
    case invalidImage
    case invalidPDF
    case extractionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or could not be processed."
        case .invalidPDF:
            return "The provided PDF document is invalid or could not be opened."
        case .extractionFailed(let error):
            return "OCR text extraction failed: \(error.localizedDescription)"
        }
    }
}
