import SwiftUI

// MARK: - 首页基础信息面板

struct HomeStatusPanel: View {
    let isRecording: Bool

    var body: some View {
        OrbGlassPanel(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isRecording ? .red : .mint)
                        .frame(width: 8, height: 8)

                    Text(isRecording ? "正在录制" : "准备记录")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text("今日 3 段 · 最近 200m")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.58))

                Text("长按底部按钮，把当下的声音放进地图。")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 190, alignment: .leading)
        }
    }
}
