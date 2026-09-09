import SwiftUI

// MARK: - Liquid Glass 基础组件

struct OrbGlassPanel<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .orbGlassSurface(cornerRadius: cornerRadius)
    }
}

struct OrbGlassIconButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    init(
        title: String,
        systemImage: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 46, height: 46)
                .foregroundStyle(isActive ? .black : .white)
                .background {
                    if isActive {
                        Circle()
                            .fill(.white.opacity(0.88))
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

extension View {
    // 对外提供统一的玻璃表面接口；iOS 26 使用 Liquid Glass，旧系统使用暗色材质兜底。
    @ViewBuilder
    func orbGlassSurface(cornerRadius: CGFloat = 22) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(.regular.tint(.white.opacity(0.16)).interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                }
        }
    }
}
