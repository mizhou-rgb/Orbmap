import Foundation

// MARK: - 首页地图风格

enum OrbHomeMapStyle: String, CaseIterable, Identifiable {
    case satellite
    case standard2D

    var id: String {
        rawValue
    }

    // 展示给用户看的按钮标题。
    var title: String {
        switch self {
        case .satellite:
            "卫星"
        case .standard2D:
            "2D"
        }
    }

    // 每种地图风格对应一个清晰的 SF Symbol，方便后续统一替换图标。
    var systemImage: String {
        switch self {
        case .satellite:
            "globe.asia.australia.fill"
        case .standard2D:
            "map.fill"
        }
    }
}
