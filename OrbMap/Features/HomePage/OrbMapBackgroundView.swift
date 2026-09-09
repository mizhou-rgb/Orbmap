import MapKit
import SwiftUI

// MARK: - 深色地图底图

struct OrbMapBackgroundView: View {
    let selectedStyle: OrbHomeMapStyle
    let showsCustomLabels: Bool

    // 首版固定在上海，后续接入定位后可以改为用户当前位置。
    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            distance: 5200,
            heading: 18,
            pitch: 48
        )
    )

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(OrbMapSampleLabel.samples) { label in
                    Annotation(label.title, coordinate: label.coordinate) {
                        OrbMapPointMarker(label: label, showsTitle: showsCustomLabels)
                    }
                }
            }
            .mapStyle(mapStyle)
            .mapControlVisibility(.hidden)
            .preferredColorScheme(.dark)

            // 暗色压层让地图退到背景层级，保证 Liquid Glass 控件的可读性。
            LinearGradient(
                colors: [
                    .black.opacity(0.18),
                    .black.opacity(0.42),
                    .black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // 轻微冷色遮罩统一整体暗色调，避免卫星图过亮。
            Color.cyan.opacity(0.06)
                .blendMode(.screen)
                .allowsHitTesting(false)
        }
        .onChange(of: selectedStyle) { _, newStyle in
            updateCamera(for: newStyle)
        }
    }

    private var mapStyle: MapStyle {
        switch selectedStyle {
        case .satellite:
            showsCustomLabels ? .hybrid(elevation: .realistic, pointsOfInterest: .all, showsTraffic: false) : .imagery(elevation: .realistic)
        case .standard2D:
            .standard(elevation: .flat, emphasis: .muted, pointsOfInterest: showsCustomLabels ? .all : .excludingAll, showsTraffic: false)
        }
    }

    // 切换到 2D 时降低俯仰角，切回卫星时恢复更有空间感的视角。
    private func updateCamera(for style: OrbHomeMapStyle) {
        let pitch: CGFloat = style == .satellite ? 48 : 0
        let distance: CLLocationDistance = style == .satellite ? 5200 : 6200

        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
                    distance: distance,
                    heading: style == .satellite ? 18 : 0,
                    pitch: pitch
                )
            )
        }
    }
}

// MARK: - 地图示例标签数据

private struct OrbMapSampleLabel: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D

    static let samples: [OrbMapSampleLabel] = [
        OrbMapSampleLabel(
            id: "river",
            title: "河边风声",
            subtitle: "00:28",
            coordinate: CLLocationCoordinate2D(latitude: 31.2362, longitude: 121.4895)
        ),
        OrbMapSampleLabel(
            id: "lane",
            title: "弄堂人声",
            subtitle: "01:12",
            coordinate: CLLocationCoordinate2D(latitude: 31.2246, longitude: 121.4681)
        ),
        OrbMapSampleLabel(
            id: "station",
            title: "站台广播",
            subtitle: "00:43",
            coordinate: CLLocationCoordinate2D(latitude: 31.2319, longitude: 121.4597)
        )
    ]
}

private struct OrbMapPointMarker: View {
    let label: OrbMapSampleLabel
    let showsTitle: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 34, height: 34)

                Circle()
                    .fill(.cyan.opacity(0.9))
                    .frame(width: 12, height: 12)
            }
            .orbGlassSurface(cornerRadius: 17)

            if showsTitle {
                VStack(spacing: 2) {
                    Text(label.title)
                        .font(.system(size: 11, weight: .medium))
                    Text(label.subtitle)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .orbGlassSurface(cornerRadius: 12)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
