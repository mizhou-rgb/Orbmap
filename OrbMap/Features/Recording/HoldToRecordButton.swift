import SwiftUI
import UIKit

// MARK: - 长按录制按钮

struct HoldToRecordButton: View {
    @Binding var isRecording: Bool

    // 控制录制时外圈脉冲动画的尺寸。
    @State private var pulseScale: CGFloat = 1

    var body: some View {
        ZStack {
            if isRecording {
                RecordingPulseRing(scale: pulseScale)
                    .transition(.opacity)
            }

            VStack(spacing: 10) {
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 30, weight: .semibold))

                Text(isRecording ? "松开保存" : "按住录制")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isRecording ? .black : .white)
            .frame(width: 116, height: 116)
            .background {
                Circle()
                    .fill(isRecording ? .white.opacity(0.9) : .white.opacity(0.12))
            }
            .orbGlassSurface(cornerRadius: 58)
            .scaleEffect(isRecording ? 1.08 : 1)
            .shadow(color: isRecording ? .white.opacity(0.32) : .clear, radius: 24, x: 0, y: 0)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    startRecordingIfNeeded()
                }
                .onEnded { _ in
                    stopRecordingIfNeeded()
                }
        )
        .accessibilityLabel(isRecording ? "正在录制，松开保存" : "按住录制")
    }

    // 第一次进入按住状态时触发震动和动画。
    private func startRecordingIfNeeded() {
        guard !isRecording else {
            return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            isRecording = true
        }

        withAnimation(.easeOut(duration: 0.9).repeatForever(autoreverses: false)) {
            pulseScale = 1.55
        }
    }

    // 手指松开后结束录制状态，并给一个更轻的收尾反馈。
    private func stopRecordingIfNeeded() {
        guard isRecording else {
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            isRecording = false
            pulseScale = 1
        }
    }
}

private struct RecordingPulseRing: View {
    let scale: CGFloat

    var body: some View {
        Circle()
            .stroke(.white.opacity(0.38), lineWidth: 2)
            .frame(width: 126, height: 126)
            .scaleEffect(scale)
            .opacity(2 - scale)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HoldToRecordButton(isRecording: .constant(false))
    }
}
