import SwiftUI
import AVFoundation

// MARK: - 页面入口与转场

struct ContentView: View {
    // 记录 Intro 页面被手指向上拖动的距离。
    @State private var dragOffset: CGFloat = 0

    // 切换完成后禁止再次处理上滑手势。
    @State private var isShowingHome = false

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height

            // 把拖动距离转换为 0...1，用来控制首页的透明度和大小。
            let transitionProgress = min(max(-dragOffset / screenHeight, 0), 1)

            ZStack {
                // 首页放在底层，随着上滑逐渐出现。
                HomeView()
                    .opacity(transitionProgress)
                    .scaleEffect(0.94 + transitionProgress * 0.06)

                // Intro 页面放在上层，并跟随手指向上移动。
                introView {
                    showHome(screenHeight: screenHeight)
                }
                .offset(y: dragOffset)
                .opacity(1 - transitionProgress * 0.4)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            guard !isShowingHome else { return }
                            dragOffset = min(value.translation.height, 0)
                        }
                        .onEnded { value in
                            guard !isShowingHome else { return }

                            // 滑动距离足够，或用户快速上滑时进入首页。
                            let shouldShowHome =
                                value.translation.height < -120 ||
                                value.predictedEndTranslation.height < -220

                            if shouldShowHome {
                                showHome(screenHeight: screenHeight)
                            } else {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .background(Color.black)
            .ignoresSafeArea()
        }
    }

    // 播放转场动画，把 Intro 页面移出屏幕。
    private func showHome(screenHeight: CGFloat) {
        isShowingHome = true

        withAnimation(.easeInOut(duration: 0.7)) {
            dragOffset = -screenHeight
        }
    }
}

// MARK: - Intro 页面

struct introView: View {
    // 每次数字增加，视频就会从头播放一次。
    @State private var replayCount = 0

    // 点击底部按钮时，由 ContentView 负责进入首页。
    let onEnterHome: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 宝声视频和品牌文字。
                    ZStack {
                    ReplayableVideoView(
                        videoName: "orb_intro",
                        replayCount: replayCount
                    )
                        .clipShape(Circle())

                    Text("宝 声\n地 图")
                        .font(.custom("PingFangSC-Light", size: 21))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 350, height: 350)
                // 将宝珠视频和品牌名整体向下移动。
                .offset(y: 50)
                .contentShape(Circle())
                .onTapGesture {
                    replayCount += 1
                }

                Spacer()

                // 产品简介文案。
                VStack(spacing: 12) {
                    Text("一张属于你的声音地图")
                    Text("将听见的瞬间，留在发生的地方")
                }
                .font(.system(size: 21, weight: .thin))
                .foregroundStyle(.white)

                Spacer()

                // 除了上滑，用户也可以点击这里进入首页。
                Button(action: onEnterHome) {
                    VStack(spacing: 8) {
                        Image(systemName: "waveform.path")
                            .font(.system(size: 28, weight: .thin))

                        Text("上滑")
                            .font(.system(size: 13, weight: .light))

                        Text("开始聆听世界")
                            .font(.system(size: 17, weight: .light))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)

                Spacer()
                    .frame(height: 55)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - 首页

// 当前是首页占位内容，之后可以直接在这里替换成正式首页。
private struct HomeView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("宝声地图")
                    .font(.custom("PingFangSC-Light", size: 30))

                Text("这里将是你的首页")
                    .font(.custom("PingFangSC-Light", size: 16))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(.white)
        }
    }
}

// MARK: - 可重复播放的视频

// UIViewRepresentable 让 SwiftUI 可以使用 AVPlayer 播放本地视频。
private struct ReplayableVideoView: UIViewRepresentable {
    let videoName: String
    let replayCount: Int

    // Coordinator 负责保存播放器，避免 SwiftUI 刷新时重复创建。
    func makeCoordinator() -> Coordinator {
        Coordinator(videoName: videoName)
    }

    // 首次创建视频视图时连接播放器，并自动播放一次。
    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = context.coordinator.player
        context.coordinator.player.play()
        return view
    }

    // replayCount 变化表示用户点击了宝珠，需要重新播放。
    func updateUIView(_ uiView: PlayerView, context: Context) {
        guard context.coordinator.lastReplayCount != replayCount else {
            return
        }

        context.coordinator.lastReplayCount = replayCount
        context.coordinator.replay()
    }

    // 视频视图离开页面时暂停播放。
    static func dismantleUIView(_ uiView: PlayerView, coordinator: Coordinator) {
        coordinator.player.pause()
    }

    final class Coordinator {
        let player = AVPlayer()
        var lastReplayCount = 0

        init(videoName: String) {
            // 优先寻找 mov；如果没有，再寻找项目当前使用的 mp4。
            guard let url = Bundle.main.url(forResource: videoName, withExtension: "mov")
                    ?? Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
                return
            }

            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            player.isMuted = true
        }

        // 回到视频开头，然后播放一次。
        func replay() {
            player.seek(to: .zero) { [weak player] _ in
                player?.play()
            }
        }
    }
}

// MARK: - AVPlayer 显示层

// 使用 AVPlayerLayer 显示视频画面，不显示系统播放器控制栏。
private final class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 填满宝珠区域，超出的画面会被裁切。
        playerLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        nil
    }
}

#Preview {
    ContentView()
}

