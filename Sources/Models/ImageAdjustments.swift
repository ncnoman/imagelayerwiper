import Foundation

/// All adjustable image filter parameters for a single layer.
/// Default values represent "no adjustment" (identity).
struct ImageAdjustments: Codable, Equatable {
    /// Brightness offset. Range: -1.0 to 1.0. Default: 0 (no change).
    var brightness: Double = 0.0

    /// Contrast multiplier. Range: 0.25 to 4.0. Default: 1 (no change).
    var contrast: Double = 1.0

    /// Saturation multiplier. Range: 0.0 to 3.0. Default: 1 (no change).
    var saturation: Double = 1.0

    /// Hue rotation in degrees. Range: 0 to 360. Default: 0 (no change).
    var hueRotation: Double = 0.0

    /// Exposure value (EV). Range: -3.0 to 3.0. Default: 0 (no change).
    var exposure: Double = 0.0

    /// Highlight recovery. Range: 0.0 to 1.0. Default: 1.0 (no change).
    var highlights: Double = 1.0

    /// Shadow boost. Range: -1.0 to 1.0. Default: 0.0 (no change).
    var shadows: Double = 0.0

    /// Sharpness intensity. Range: 0.0 to 2.0. Default: 0 (no sharpening).
    var sharpness: Double = 0.0

    /// Gaussian blur radius. Range: 0.0 to 20.0. Default: 0 (no blur).
    var blur: Double = 0.0

    /// Vibrance (selective saturation). Range: -1.0 to 1.0. Default: 0.
    var vibrance: Double = 0.0

    /// Colour temperature in Kelvin. Range: 2000 to 10000. Default: 6500.
    var temperature: Double = 6500.0

    // MARK: - Helpers

    static let `default` = ImageAdjustments()

    /// Returns `true` when every parameter equals its identity default.
    var isDefault: Bool { self == Self.default }

    /// Resets all adjustments to identity values.
    mutating func reset() { self = .default }
}
