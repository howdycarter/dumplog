import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    let isRecording: Bool
    let color: Color

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.7 + Double(sample) * 0.3))
                        .frame(width: (geo.size.width / CGFloat(samples.count)) - 2,
                               height: max(4, CGFloat(sample) * geo.size.height))
                        .animation(.easeInOut(duration: 0.1), value: sample)
                }
            }
        }
    }
}

struct PulsingRecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 0.8).repeatForever(), value: isRecording)
                }
                Circle()
                    .fill(isRecording ? Color.red : Color.dlAccent)
                    .frame(width: 80, height: 80)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}
