import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingEntry: JournalEntry?
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.dlWarmBackground.ignoresSafeArea()
                switch viewModel.state {
                case .idle, .recording: recordingUI
                case .processing: processingUI
                case .done(let entry): doneUI(entry: entry)
                case .error(let message): errorUI(message: message)
                }
            }
            .navigationTitle("DumpLog")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $showingEntry) { entry in EntryDetailView(entry: entry) }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("DumpLog needs microphone and speech recognition access to transcribe your voice journal entries.")
        }
    }

    private var recordingUI: some View {
        VStack(spacing: 40) {
            Spacer()
            Text(formatDuration(viewModel.duration))
                .font(.system(size: 56, weight: .thin, design: .rounded))
                .foregroundStyle(viewModel.isRecording ? .red : .secondary)
                .monospacedDigit()
                .opacity(viewModel.isRecording ? 1 : 0.6)
            WaveformView(samples: viewModel.waveformSamples, isRecording: viewModel.isRecording, color: viewModel.isRecording ? .red : .dlAccent)
                .frame(height: 80).padding(.horizontal, 24)
            PulsingRecordButton(isRecording: viewModel.isRecording) {
                Task { await handleRecordTap() }
            }
            Text(viewModel.isRecording ? "Tap to stop" : "Tap to start recording")
                .font(.callout).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    private var processingUI: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().stroke(Color.dlAccent.opacity(0.2), lineWidth: 6).frame(width: 80, height: 80)
                Circle().trim(from: 0, to: viewModel.processingProgress)
                    .stroke(Color.dlAccent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80).rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.processingProgress)
            }
            VStack(spacing: 8) {
                Text("Processing your entry").font(.headline)
                Text(processingStatusText).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var processingStatusText: String {
        switch viewModel.processingProgress {
        case 0..<0.3: return "Saving audio..."
        case 0.3..<0.7: return "Transcribing on-device..."
        case 0.7..<0.9: return "Extracting insights..."
        default: return "Finalizing..."
        }
    }

    private func doneUI(entry: JournalEntry) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundStyle(Color.moodGreen)
            VStack(spacing: 8) {
                Text("Entry saved!").font(.title2.weight(.semibold))
                Text("\(entry.themes.prefix(3).joined(separator: ", "))").font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            HStack(spacing: 16) {
                Button("View Entry") { showingEntry = entry }.buttonStyle(.borderedProminent).controlSize(.large)
                Button("New Entry") { viewModel.reset() }.buttonStyle(.bordered).controlSize(.large)
            }
            Spacer()
        }
        .padding()
    }

    private func errorUI(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50)).foregroundStyle(.orange)
            Text("Something went wrong").font(.headline)
            Text(message).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Try Again") { viewModel.reset() }.buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func handleRecordTap() async {
        if viewModel.isRecording {
            await viewModel.stopAndProcess(context: modelContext)
        } else {
            if !viewModel.permissionGranted {
                let granted = await viewModel.requestPermissions()
                if !granted { showingPermissionAlert = true; return }
            }
            viewModel.startRecording()
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60)
    }
}
