import Foundation
import AVFoundation
import Combine

@MainActor
class AudioRecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var duration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var waveformSamples: [Float] = Array(repeating: 0, count: 40)
    @Published var permissionGranted = false

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?
    private var startTime: Date?
    private(set) var recordingURL: URL?

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: permissionGranted = true
        default: permissionGranted = false
        }
    }

    func requestPermission() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        permissionGranted = granted
        return granted
    }

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        recordingURL = url
        startTime = Date()
        isRecording = true
        duration = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.startTime else { return }
                self.duration = Date().timeIntervalSince(start)
            }
        }
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateAudioLevel() }
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        timer?.invalidate(); levelTimer?.invalidate()
        timer = nil; levelTimer = nil
        isRecording = false
        let url = recordingURL
        try? AVAudioSession.sharedInstance().setActive(false)
        return url
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = max(0, (power + 60) / 60)
        audioLevel = normalized
        var samples = waveformSamples
        samples.removeFirst()
        samples.append(Float.random(in: normalized * 0.5...max(normalized, 0.05)))
        waveformSamples = samples
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {}
}
