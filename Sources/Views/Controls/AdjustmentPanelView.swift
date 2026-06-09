import SwiftUI

/// Inspector panel containing all image adjustment sliders for a specific layer.
///
/// Organises controls into three collapsible sections — Light, Color,
/// and Detail. Changes are immediately applied by calling
/// `reprocessImage(for:)` on the view model.
struct AdjustmentPanelView: View {
    @Bindable var viewModel: CanvasViewModel
    let layer: LayerSelection

    @State private var lightExpanded = true
    @State private var colorExpanded = true
    @State private var detailExpanded = true

    // MARK: - Layer-specific binding helper

    private var adjustments: ImageAdjustments {
        layer == .image1 ? viewModel.layer1.adjustments : viewModel.layer2.adjustments
    }

    private func adjBinding(_ keyPath: WritableKeyPath<ImageAdjustments, Double>) -> Binding<Double> {
        Binding(
            get: {
                let adj = layer == .image1 ? viewModel.layer1.adjustments : viewModel.layer2.adjustments
                return adj[keyPath: keyPath]
            },
            set: { newValue in
                switch layer {
                case .image1: viewModel.layer1.adjustments[keyPath: keyPath] = newValue
                case .image2: viewModel.layer2.adjustments[keyPath: keyPath] = newValue
                }
                viewModel.reprocessImage(for: layer)
                viewModel.isDirty = true
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            lightSection
            Divider().padding(.horizontal, 4)
            colorSection
            Divider().padding(.horizontal, 4)
            detailSection
            resetButton
        }
        .controlSize(.small)
    }

    // MARK: - Light Section

    private var lightSection: some View {
        DisclosureGroup(isExpanded: $lightExpanded) {
            VStack(spacing: 6) {
                AdjustmentSlider(label: "Exposure", value: adjBinding(\.exposure),
                                 range: -3...3, defaultValue: 0, step: 0.05, format: "%+.2f")
                AdjustmentSlider(label: "Brightness", value: adjBinding(\.brightness),
                                 range: -1...1, defaultValue: 0, step: 0.01, format: "%+.2f")
                AdjustmentSlider(label: "Contrast", value: adjBinding(\.contrast),
                                 range: 0.25...4.0, defaultValue: 1, step: 0.05, format: "%.2f")
                AdjustmentSlider(label: "Highlights", value: adjBinding(\.highlights),
                                 range: 0...1, defaultValue: 1, step: 0.01, format: "%.2f")
                AdjustmentSlider(label: "Shadows", value: adjBinding(\.shadows),
                                 range: -1...1, defaultValue: 0, step: 0.01, format: "%+.2f")
            }
            .padding(.top, 4)
        } label: {
            Label("Light", systemImage: "sun.max")
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Color Section

    private var colorSection: some View {
        DisclosureGroup(isExpanded: $colorExpanded) {
            VStack(spacing: 6) {
                AdjustmentSlider(label: "Saturation", value: adjBinding(\.saturation),
                                 range: 0...3, defaultValue: 1, step: 0.05, format: "%.2f")
                AdjustmentSlider(label: "Vibrance", value: adjBinding(\.vibrance),
                                 range: -1...1, defaultValue: 0, step: 0.01, format: "%+.2f")
                AdjustmentSlider(label: "Hue", value: adjBinding(\.hueRotation),
                                 range: 0...360, defaultValue: 0, step: 1, format: "%.0f°")
                AdjustmentSlider(label: "Temperature", value: adjBinding(\.temperature),
                                 range: 2000...10000, defaultValue: 6500, step: 100, format: "%.0fK")
            }
            .padding(.top, 4)
        } label: {
            Label("Color", systemImage: "paintpalette")
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Detail Section

    private var detailSection: some View {
        DisclosureGroup(isExpanded: $detailExpanded) {
            VStack(spacing: 6) {
                AdjustmentSlider(label: "Sharpness", value: adjBinding(\.sharpness),
                                 range: 0...2, defaultValue: 0, step: 0.05, format: "%.2f")
                AdjustmentSlider(label: "Blur", value: adjBinding(\.blur),
                                 range: 0...20, defaultValue: 0, step: 0.5, format: "%.1f")
            }
            .padding(.top, 4)
        } label: {
            Label("Detail", systemImage: "circle.hexagongrid")
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            viewModel.resetAdjustments(for: layer)
        } label: {
            Label("Reset Adjustments", systemImage: "arrow.counterclockwise")
                .font(.caption)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(adjustments.isDefault)
        .padding(.top, 2)
    }
}
