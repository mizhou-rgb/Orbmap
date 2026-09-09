import SwiftUI

// MARK: - 首页顶部控制区

struct HomeTopBar: View {
    @Binding var showsCustomLabels: Bool
    @Binding var selectedMapStyle: OrbHomeMapStyle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HomeIdentityView()

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 10) {
                CustomLabelToggleButton(isOn: $showsCustomLabels)
                MapStyleSegmentedButton(selectedStyle: $selectedMapStyle)
            }
        }
    }
}

private struct HomeIdentityView: View {
    var body: some View {
        OrbGlassPanel(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("宝声地图")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.white)

                Text("上海 · 23 个声音点")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .frame(minWidth: 128, alignment: .leading)
        }
    }
}

private struct CustomLabelToggleButton: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isOn.toggle()
            }
        } label: {
            Label(isOn ? "标签显示" : "标签隐藏", systemImage: isOn ? "tag.fill" : "tag")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .orbGlassSurface(cornerRadius: 21)
        }
        .buttonStyle(.plain)
    }
}

private struct MapStyleSegmentedButton: View {
    @Binding var selectedStyle: OrbHomeMapStyle

    var body: some View {
        HStack(spacing: 4) {
            ForEach(OrbHomeMapStyle.allCases) { style in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.86)) {
                        selectedStyle = style
                    }
                } label: {
                    Label(style.title, systemImage: style.systemImage)
                        .font(.system(size: 13, weight: .medium))
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(selectedStyle == style ? .black : .white.opacity(0.82))
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background {
                            if selectedStyle == style {
                                Capsule()
                                    .fill(.white.opacity(0.88))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .orbGlassSurface(cornerRadius: 23)
    }
}
