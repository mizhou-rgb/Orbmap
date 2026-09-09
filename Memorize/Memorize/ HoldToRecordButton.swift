//
//   HoldToRecordButton.swift
//  Memorize
//
//  Created by MI ZHOU on 6/2/26.
//

import SwiftUI

struct HoldToRecordButton: View {
    @State private var isPressing = false
    @State private var animateRipple = false

    var body: some View {
        VStack(spacing: 60) {
            // 独立的辉光圆，仅用于观察视觉效果。
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue, .cyan.opacity(0.5)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )

                Circle()
                    .fill(Color.purple.opacity(0.5))
                    .blur(radius: 25)
                    .offset(x: -25, y: 25)
            }
            .frame(width: 180, height: 180)
            .shadow(color: .purple.opacity(0.7), radius: 25)
            .blur(radius: 3)

            // 录音按钮和按压波纹。
            ZStack {
                if isPressing {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(.blue.opacity(0.1), lineWidth: 0)
                            .frame(width: 180, height: 180)
                            .scaleEffect(animateRipple ? 1.8 : 1.0)
                            .opacity(animateRipple ? 0.0 : 0.20)
                            .animation(
                                .easeOut(duration: 1.4)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                value: animateRipple
                            )
                    }
                }

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.7), lineWidth: 0)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 10)
                    .scaleEffect(isPressing ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isPressing)

                VStack(spacing: 6) {
                    Image(systemName: isPressing ? "waveform" : "mic.fill")
                        .font(.title)

                    Text(isPressing ? "Recording..." : "Hold to Record")
                        .font(.caption)
                }
            }
            .frame(width: 320, height: 320)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressing {
                            isPressing = true
                            animateRipple = true
                        }
                    }
                    .onEnded { _ in
                        isPressing = false
                        animateRipple = false
                    }
            )
        }
    }
}

#Preview {
    HoldToRecordButton()
}
