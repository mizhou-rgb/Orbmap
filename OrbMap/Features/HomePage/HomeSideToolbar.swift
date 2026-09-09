import SwiftUI

// MARK: - 首页右侧工具栏

struct HomeSideToolbar: View {
    let onArchive: () -> Void
    let onSettings: () -> Void
    let onLocation: () -> Void

    var body: some View {
        OrbGlassPanel(cornerRadius: 28) {
            VStack(spacing: 12) {
                OrbGlassIconButton(
                    title: "Archive",
                    systemImage: "archivebox.fill",
                    action: onArchive
                )

                Divider()
                    .overlay(.white.opacity(0.18))
                    .frame(width: 26)

                OrbGlassIconButton(
                    title: "定位",
                    systemImage: "location.fill",
                    action: onLocation
                )

                OrbGlassIconButton(
                    title: "设置",
                    systemImage: "gearshape.fill",
                    action: onSettings
                )
            }
        }
    }
}
