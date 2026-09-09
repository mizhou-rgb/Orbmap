import SwiftUI

// MARK: - 首页入口

struct HomePageView: View {
    // 控制地图上的自定义标签是否显示。
    @State private var showsCustomLabels = true

    // 控制当前地图风格：卫星或 2D。
    @State private var selectedMapStyle: OrbHomeMapStyle = .satellite

    // 记录录制按钮是否处于按住录制状态。
    @State private var isRecording = false

    var body: some View {
        ZStack {
            // 深色地图作为整页底图，所有 UI 都浮在地图之上。
            OrbMapBackgroundView(
                selectedStyle: selectedMapStyle,
                showsCustomLabels: showsCustomLabels
            )
            .ignoresSafeArea()

            // 首页主要控件层，负责组织页面四周的交互入口。
            VStack(spacing: 0) {
                HomeTopBar(
                    showsCustomLabels: $showsCustomLabels,
                    selectedMapStyle: $selectedMapStyle
                )
                .padding(.top, 16)
                .padding(.horizontal, 18)

                Spacer()

                HStack(alignment: .bottom) {
                    HomeStatusPanel(isRecording: isRecording)

                    Spacer()

                    HomeSideToolbar(
                        onArchive: {},
                        onSettings: {},
                        onLocation: {}
                    )
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)

                HoldToRecordButton(isRecording: $isRecording)
                    .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    HomePageView()
}
