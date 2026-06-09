#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI



// MARK: - URL Helpers

extension URL {
    /// Returns `true` if the file at this URL is a supported image format.
    var isImageFile: Bool {
        let imageExtensions: Set<String> = [
            "jpg", "jpeg", "png", "tiff", "tif", "bmp",
            "gif", "heic", "heif", "webp", "raw", "cr2",
            "nef", "arw", "dng"
        ]
        return imageExtensions.contains(pathExtension.lowercased())
    }
}

// MARK: - Color Helpers

extension Color {
    #if os(macOS)
    static let canvasBackground = Color(nsColor: NSColor(
        calibratedRed: 0.11, green: 0.11, blue: 0.12, alpha: 1.0
    ))
    static let panelBackground = Color(nsColor: NSColor(
        calibratedRed: 0.15, green: 0.15, blue: 0.16, alpha: 1.0
    ))
    static let controlAccent = Color(nsColor: NSColor(
        calibratedRed: 0.40, green: 0.55, blue: 1.0, alpha: 1.0
    ))
    static let dropZoneBorder = Color(nsColor: NSColor(
        calibratedRed: 0.35, green: 0.35, blue: 0.38, alpha: 1.0
    ))
    static let dropZoneActive = Color(nsColor: NSColor(
        calibratedRed: 0.40, green: 0.55, blue: 1.0, alpha: 0.6
    ))
    #else
    static let canvasBackground = Color(uiColor: UIColor(
        red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0
    ))
    static let panelBackground = Color(uiColor: UIColor(
        red: 0.15, green: 0.15, blue: 0.16, alpha: 1.0
    ))
    static let controlAccent = Color(uiColor: UIColor(
        red: 0.40, green: 0.55, blue: 1.0, alpha: 1.0
    ))
    static let dropZoneBorder = Color(uiColor: UIColor(
        red: 0.35, green: 0.35, blue: 0.38, alpha: 1.0
    ))
    static let dropZoneActive = Color(uiColor: UIColor(
        red: 0.40, green: 0.55, blue: 1.0, alpha: 0.6
    ))
    #endif
}

// MARK: - Adjustment Slider

/// A reusable labeled slider row with value display and reset button.
struct AdjustmentSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let defaultValue: Double
    var step: Double = 0.01
    var format: String = "%.2f"

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Slider(value: $value, in: range, step: step)
                .controlSize(.small)

            Text(String(format: format, value))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            Button {
                value = defaultValue
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(value == defaultValue ? 0.3 : 1.0)
            .disabled(value == defaultValue)
        }
    }
}

// MARK: - View Extension (compatibility shim)

extension View {
    /// Convenience to create an AdjustmentSlider. Returns the slider, ignoring `self`.
    func adjustmentSlider(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        defaultValue: Double,
        step: Double = 0.01,
        format: String = "%.2f"
    ) -> some View {
        AdjustmentSlider(
            label: label,
            value: value,
            range: range,
            defaultValue: defaultValue,
            step: step,
            format: format
        )
    }
}
