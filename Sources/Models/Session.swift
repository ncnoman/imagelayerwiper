import Foundation

/// How the two images are visually compared.
enum ComparisonMode: String, Codable, CaseIterable, Identifiable {
    case swiper
    case opacity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .swiper: return "Swiper"
        case .opacity: return "Opacity"
        }
    }

    var icon: String {
        switch self {
        case .swiper: return "rectangle.split.2x1"
        case .opacity: return "square.on.square"
        }
    }
}

/// Which image layer is currently selected for editing.
enum LayerSelection: String, CaseIterable, Identifiable {
    case image1 = "Image 1"
    case image2 = "Image 2"

    var id: String { rawValue }
}

/// A saved comparison session containing two image layers and all associated state.
struct Session: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var layer1 = ImageLayer()
    var layer2 = ImageLayer()

    var comparisonMode: ComparisonMode = .swiper
    var swiperPosition: Double = 0.5
    var opacityValue: Double = 0.5

    /// Creates a new session with a default name.
    static func newSession() -> Session {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let name = "Session \(formatter.string(from: Date()))"
        return Session(name: name)
    }
}
