import Foundation
import Speech
import AVFoundation

@MainActor
class TranscriptionService: ObservableObject {
    @Published var isTranscribing = false

    private var speechRecognizer: SFSpeechRecognizer?

    init() {
        let locale = Locale(identifier: UserDefaults.standard.string(forKey: "transcriptionLanguage") ?? "en-US")
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func transcribe(url: URL) async throws -> String {
        isTranscribing = true
        defer { isTranscribing = false }
        let recognizer = speechRecognizer ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error { continuation.resume(throwing: error); return }
                if let result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    enum TranscriptionError: LocalizedError {
        case recognizerUnavailable
        var errorDescription: String? { "Speech recognizer is not available." }
    }
}
