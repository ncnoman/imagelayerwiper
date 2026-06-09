import SwiftUI

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#else
import UIKit
public typealias PlatformImage = UIImage
#endif

// MARK: - Unified PlatformImage extensions

extension PlatformImage {
    /// Returns the pixel dimensions of the image.
    var pixelSize: CGSize {
        #if os(macOS)
        guard let rep = representations.first else { return size }
        return CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        #else
        guard let cg = cgImage else { return size }
        return CGSize(width: cg.width, height: cg.height)
        #endif
    }

    /// Returns PNG data for the image.
    func pngImageData() -> Data? {
        #if os(macOS)
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return pngData()
        #endif
    }

    /// Returns JPEG data for the image.
    func jpegImageData(quality: Double = 0.9) -> Data? {
        #if os(macOS)
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        #else
        return jpegData(compressionQuality: quality)
        #endif
    }

    /// Resizes the image to fit within `maxDimension` while preserving aspect ratio.
    func resizedToFit(maxDimension: CGFloat) -> PlatformImage {
        let currentMax = max(size.width, size.height)
        guard currentMax > maxDimension else { return self }

        let ratio = maxDimension / currentMax
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )

        #if os(macOS)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
        #else
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        #endif
    }

    /// Load an image from a URL.
    static func fromURL(_ url: URL) -> PlatformImage? {
        #if os(macOS)
        return NSImage(contentsOf: url)
        #else
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
        #endif
    }
}

// MARK: - SwiftUI Image bridge

extension Image {
    init(platformImage: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}
