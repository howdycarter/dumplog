import Foundation
import SwiftData
import Combine

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var processingProgress: Double = 0

    private let audioService = AudioRecordingService()
    private let transcriptionService = TranscriptionService()
    private let aiService = AIStructuringService()

    var isRecording: Bool { audioService.isRecording }
    var duration: TimeInterval { audioService.duration }
    var audioLevel: Float { audioService.audioLevel }
    var waveformSamples: [Float] { audioService.waveformSamples }
    var permissionGranted: Bool { audioService.permissionGranted }

    private var cancellables = Set<AnyCancellable>()

    init() {
        audioService.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
    }

    enum RecordingState {
        case idle, recording, processing
        case done(JournalEntry)
        case error(String)
    }

    func requestPermissions() async -> Bool {
        let mic = await audioService.requestPermission()
        let speech = await transcriptionService.requestPermission()
        return mic && speech
    }

    func startRecording() {
        do { try audioService.startRecording(); state = .recording }
        catch { state = .error(error.localizedDescription) }
    }

    func stopAndProcess(context: ModelContext) async {
        guard let url = audioService.stopRecording() else {
            state = .error("Failed to save recording"); return
        }
        state = .processing; processingProgress = 0.1
        do {
            processingProgress = 0.3
            let transcript = try await transcriptionService.transcribe(url: url)
            processingProgress = 0.7
            let structured = aiService.structure(transcript: transcript)
            processingProgress = 0.9
            let entry = JournalEntry(date: Date(), audioURL: url.path, transcript: transcript,
                themes: structured.themes, sentiment: structured.sentiment,
                actionItems: structured.actionItems, duration: audioService.duration, title: structured.title)
            context.insert(entry)
            try context.save()
            processingProgress = 1.0; state = .done(entry)
        } catch { state = .error(error.localizedDescription) }
    }

    func reset() { state = .idle; processingProgress = 0 }
}
