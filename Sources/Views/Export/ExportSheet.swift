import SwiftUI
import AppKit

/// Modal sheet presenting export options for the comparison canvas.
///
/// Allows the user to choose an image format, resolution scale, and JPEG
/// quality before saving to disk or copying to the system clipboard.
struct ExportSheet: View {
    @Bindable var viewModel: CanvasViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Local State

    @State private var exportFormat: ExportFormat = .png
    @State private var exportScale: CGFloat = 2.0
    @State private var jpegQuality: Double = 0.9
    @State private var isExporting = false
    @State private var exportData: Data?
    @State private var exportError: String?

    // Available render scales
    private let scaleOptions: [(label: String, value: CGFloat)] = [
        ("1×", 1.0),
        ("2×", 2.0),
        ("3×", 3.0),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: - Title

            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(Color.controlAccent)
                Text("Export Image")
                    .font(.title2.weight(.semibold))
                Spacer()
            }

            Divider()

            // MARK: - Format Picker

            VStack(alignment: .leading, spacing: 8) {
                Text("Format")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            // MARK: - JPEG Quality

            if exportFormat == .jpeg {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quality")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Slider(value: $jpegQuality, in: 0.1...1.0, step: 0.05)

                        Text("\(Int(jpegQuality * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }

            // MARK: - Scale Picker

            VStack(alignment: .leading, spacing: 8) {
                Text("Resolution Scale")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Picker("Scale", selection: $exportScale) {
                    ForEach(scaleOptions, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(.segmented)
            }

            // MARK: - Summary

            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Output: \(exportFormat.rawValue) at \(Int(exportScale))× scale")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = exportError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // MARK: - Action Buttons

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                }
                .disabled(isExporting)

                Button {
                    saveToFile()
                } label: {
                    Label("Save to File…", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isExporting)
            }
        }
        .padding(24)
        .frame(minWidth: 400)
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    ProgressView("Exporting…")
                        .controlSize(.large)
                }
            }
        }
    }

    // MARK: - Export Actions

    /// Builds the composite view that matches what the user sees on canvas.
    @ViewBuilder
    private var compositeView: some View {
        // Render at a fixed frame matching the canvas aspect;
        // ImageRenderer will capture exactly this.
        ComparisonCanvasView(viewModel: viewModel)
            .frame(width: 1200, height: 800)
    }

    private func renderExportData() -> Data? {
        return ExportService.renderToData(
            view: compositeView,
            scale: exportScale,
            format: exportFormat,
            jpegQuality: jpegQuality
        )
    }

    private func saveToFile() {
        isExporting = true
        exportError = nil

        guard let data = renderExportData() else {
            exportError = "Failed to render image."
            isExporting = false
            return
        }

        Task {
            let url = await ExportService.saveToFile(data: data, format: exportFormat)
            isExporting = false
            if url != nil {
                dismiss()
            } else {
                exportError = "Save was cancelled or failed."
            }
        }
    }

    private func copyToClipboard() {
        isExporting = true
        exportError = nil

        let renderer = ImageRenderer(content: compositeView)
        renderer.scale = exportScale

        if let nsImage = renderer.nsImage {
            ExportService.copyToClipboard(nsImage)
            isExporting = false
            dismiss()
        } else {
            exportError = "Failed to render image for clipboard."
            isExporting = false
        }
    }
}
