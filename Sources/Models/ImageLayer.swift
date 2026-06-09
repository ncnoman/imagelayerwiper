import Foundation

/// Represents one image layer in a comparison session.
/// Holds the filename reference, 2D transforms, 3D perspective, and filter adjustments.
struct ImageLayer: Codable, Identifiable, Equatable {
    var id = UUID()

    /// Filename of the stored image (relative to the session directory). `nil` if no image loaded.
    var imageFileName: String?

    // MARK: - 2D Transforms

    /// Rotation angle in degrees (0–360).
    var rotation: Double = 0.0

    /// Uniform scale factor (0.1–5.0, where 1.0 = original size).
    var scale: Double = 1.0

    /// Horizontal offset in points.
    var offsetX: Double = 0.0

    /// Vertical offset in points.
    var offsetY: Double = 0.0

    /// Layer opacity (0.0–1.0, where 1.0 = fully opaque).
    var opacity: Double = 1.0

    /// Mirror the image horizontally.
    var flipH: Bool = false

    /// Mirror the image vertically.
    var flipV: Bool = false

    // MARK: - 3D Perspective

    /// Perspective rotation around the X axis in degrees (-60 to 60).
    var perspectiveX: Double = 0.0

    /// Perspective rotation around the Y axis in degrees (-60 to 60).
    var perspectiveY: Double = 0.0

    /// Perspective rotation around the Z axis in degrees (-180 to 180).
    var perspectiveZ: Double = 0.0

    /// Perspective depth strength (0.1 to 1.0). Lower = subtler foreshortening.
    var perspectiveStrength: Double = 0.5

    // MARK: - Image Adjustments

    var adjustments: ImageAdjustments = .init()

    // MARK: - Convenience

    var hasImage: Bool { imageFileName != nil }

    var hasPerspective: Bool {
        perspectiveX != 0 || perspectiveY != 0 || perspectiveZ != 0
    }

    var hasTransforms: Bool {
        rotation != 0 || scale != 1.0 || offsetX != 0 || offsetY != 0 || flipH || flipV || opacity != 1.0
    }

    mutating func resetTransforms() {
        rotation = 0
        scale = 1.0
        offsetX = 0
        offsetY = 0
        opacity = 1.0
        flipH = false
        flipV = false
    }

    mutating func resetPerspective() {
        perspectiveX = 0
        perspectiveY = 0
        perspectiveZ = 0
        perspectiveStrength = 0.5
    }

    mutating func resetAdjustments() {
        adjustments.reset()
    }

    mutating func resetAll() {
        resetTransforms()
        resetPerspective()
        resetAdjustments()
    }
}
