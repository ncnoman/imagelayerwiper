import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Supported export image formats.
enum ExportFormat: String, CaseIterable, Identifiable {
    case png  = "PNG"
    case jpeg = "JPEG"
    #if os(macOS)
    case tiff = "TIFF"
    #endif

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .png:  return "png"
        case .jpeg: return "jpg"
        #if os(macOS)
        case .tiff: return "tiff"
        #endif
        }
    }

    var utType: String {
        switch self {
        case .png:  return "public.png"
        case .jpeg: return "public.jpeg"
        #if os(macOS)
        case .tiff: return "public.tiff"
        #endif
        }
    }
}

/// Handles rendering SwiftUI views to image data and saving/copying results.
@MainActor
enum ExportService {

    /// Renders a SwiftUI view to image Data in the specified format.
    static func renderToData<V: View>(
        view: V,
        scale: CGFloat = 2.0,
        format: ExportFormat = .png,
        jpegQuality: Double = 0.9
    ) -> Data? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        #if os(macOS)
        guard let nsImage = renderer.nsImage else { return nil }
        guard let tiffData = nsImage.tiffRepresentation else { return nil }
        guard let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        switch format {
        case .png:
            return bitmap.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmap.representation(using: .jpeg, properties: [
                .compressionFactor: NSNumber(value: jpegQuality)
            ])
        case .tiff:
            return bitmap.representation(using: .tiff, properties: [:])
        }
        #else
        guard let uiImage = renderer.uiImage else { return nil }

        switch format {
        case .png:
            return uiImage.pngData()
        case .jpeg:
            return uiImage.jpegData(compressionQuality: jpegQuality)
        }
        #endif
    }

    /// Saves image data to a file. On macOS presents NSSavePanel; on iOS writes to Documents directory.
    static func saveToFile(data: Data, format: ExportFormat) async -> URL? {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
        panel.nameFieldStringValue = "ImageLayerWiper Export.\(format.fileExtension)"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        let response = await panel.begin()
        guard response == .OK, let url = panel.url else { return nil }

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Export error: \(error)")
            return nil
        }
        #else
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileName = "ImageLayerWiper Export.\(format.fileExtension)"
        let url = docsDir.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Export error: \(error)")
            return nil
        }
        #endif
    }

    /// Copies an image to the system clipboard.
    static func copyToClipboard(_ image: PlatformImage) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        #else
        UIPasteboard.general.image = image
        #endif
    }
}
