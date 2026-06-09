#if os(macOS)
import AppKit
#else
import UIKit
#endif
import CoreImage
import CoreImage.CIFilterBuiltins

/// Applies Core Image filter chains to PlatformImage based on ImageAdjustments.
/// Maintains a single CIContext for GPU/Metal efficiency.
final class ImageFilterService {
    static let shared = ImageFilterService()

    private let context: CIContext

    private init() {
        // A single CIContext is expensive to create (GPU setup) — reuse always.
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }

    /// Applies the given adjustments to a PlatformImage and returns the result.
    /// Only applies filters whose values differ from their identity defaults (optimization).
    func apply(_ adjustments: ImageAdjustments, to image: PlatformImage) -> PlatformImage {
        guard !adjustments.isDefault else { return image }

        #if os(macOS)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return image
        }
        #else
        guard let cgImage = image.cgImage else {
            return image
        }
        #endif

        var ciImage = CIImage(cgImage: cgImage)

        // 1. Exposure
        if adjustments.exposure != 0 {
            let filter = CIFilter.exposureAdjust()
            filter.inputImage = ciImage
            filter.ev = Float(adjustments.exposure)
            if let output = filter.outputImage { ciImage = output }
        }

        // 2. Colour controls: brightness, contrast, saturation
        if adjustments.brightness != 0 || adjustments.contrast != 1.0 || adjustments.saturation != 1.0 {
            let filter = CIFilter.colorControls()
            filter.inputImage = ciImage
            filter.brightness = Float(adjustments.brightness)
            filter.contrast = Float(adjustments.contrast)
            filter.saturation = Float(adjustments.saturation)
            if let output = filter.outputImage { ciImage = output }
        }

        // 3. Vibrance
        if adjustments.vibrance != 0 {
            let filter = CIFilter.vibrance()
            filter.inputImage = ciImage
            filter.amount = Float(adjustments.vibrance)
            if let output = filter.outputImage { ciImage = output }
        }

        // 4. Hue rotation (degrees → radians)
        if adjustments.hueRotation != 0 {
            let filter = CIFilter.hueAdjust()
            filter.inputImage = ciImage
            filter.angle = Float(adjustments.hueRotation * .pi / 180.0)
            if let output = filter.outputImage { ciImage = output }
        }

        // 5. Temperature (approximate via colour matrix shift)
        if adjustments.temperature != 6500 {
            let filter = CIFilter.temperatureAndTint()
            filter.inputImage = ciImage
            filter.neutral = CIVector(x: CGFloat(adjustments.temperature), y: 0)
            filter.targetNeutral = CIVector(x: 6500, y: 0)
            if let output = filter.outputImage { ciImage = output }
        }

        // 6. Highlights & Shadows
        if adjustments.highlights != 1.0 || adjustments.shadows != 0 {
            let filter = CIFilter.highlightShadowAdjust()
            filter.inputImage = ciImage
            filter.highlightAmount = Float(adjustments.highlights)
            filter.shadowAmount = Float(adjustments.shadows)
            if let output = filter.outputImage { ciImage = output }
        }

        // 7. Sharpness
        if adjustments.sharpness > 0 {
            let filter = CIFilter.sharpenLuminance()
            filter.inputImage = ciImage
            filter.sharpness = Float(adjustments.sharpness)
            filter.radius = 1.69 // Apple's default
            if let output = filter.outputImage { ciImage = output }
        }

        // 8. Gaussian blur (applied last to avoid blurring then sharpening)
        if adjustments.blur > 0 {
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = ciImage
            filter.radius = Float(adjustments.blur)
            if let output = filter.outputImage {
                // Gaussian blur extends image bounds — crop back to original.
                ciImage = output.cropped(to: CIImage(cgImage: cgImage).extent)
            }
        }

        // Render the final CIImage → CGImage → PlatformImage
        let outputExtent = ciImage.extent
        guard let renderedCG = context.createCGImage(ciImage, from: outputExtent) else {
            return image
        }
        #if os(macOS)
        let result = NSImage(cgImage: renderedCG, size: image.size)
        #else
        let result = UIImage(cgImage: renderedCG)
        #endif
        return result
    }
}
