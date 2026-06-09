import SwiftUI

/// Inspector section providing 2D spatial transform controls for a specific layer.
struct TransformControlsView: View {
    @Bindable var viewModel: CanvasViewModel
    let layer: LayerSelection

    @State private var isExpanded = true

    // MARK: - Layer binding helpers

    private var layerModel: ImageLayer {
        layer == .image1 ? viewModel.layer1 : viewModel.layer2
    }

    private func binding(_ keyPath: WritableKeyPath<ImageLayer, Double>) -> Binding<Double> {
        Binding(
            get: { (layer == .image1 ? viewModel.layer1 : viewModel.layer2)[keyPath: keyPath] },
            set: {
                switch layer {
                case .image1: viewModel.layer1[keyPath: keyPath] = $0
                case .image2: viewModel.layer2[keyPath: keyPath] = $0
                }
                viewModel.isDirty = true
            }
        )
    }

    private func boolBinding(_ keyPath: WritableKeyPath<ImageLayer, Bool>) -> Binding<Bool> {
        Binding(
            get: { (layer == .image1 ? viewModel.layer1 : viewModel.layer2)[keyPath: keyPath] },
            set: {
                switch layer {
                case .image1: viewModel.layer1[keyPath: keyPath] = $0
                case .image2: viewModel.layer2[keyPath: keyPath] = $0
                }
                viewModel.isDirty = true
            }
        )
    }

    private var opacityBinding: Binding<Double> {
        Binding(
            get: { (layer == .image1 ? viewModel.layer1 : viewModel.layer2).opacity * 100 },
            set: {
                switch layer {
                case .image1: viewModel.layer1.opacity = $0 / 100
                case .image2: viewModel.layer2.opacity = $0 / 100
                }
                viewModel.isDirty = true
            }
        )
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 6) {
                AdjustmentSlider(label: "Opacity", value: opacityBinding,
                                 range: 0...100, defaultValue: 100, step: 1, format: "%.0f%%")

                Divider().padding(.vertical, 2)

                AdjustmentSlider(label: "Rotation", value: binding(\.rotation),
                                 range: 0...360, defaultValue: 0, step: 1, format: "%.0f°")

                AdjustmentSlider(
                    label: "Scale",
                    value: Binding(
                        get: { layerModel.scale * 100 },
                        set: {
                            switch layer {
                            case .image1: viewModel.layer1.scale = $0 / 100
                            case .image2: viewModel.layer2.scale = $0 / 100
                            }
                            viewModel.isDirty = true
                        }
                    ),
                    range: 10...500, defaultValue: 100, step: 5, format: "%.0f%%"
                )

                AdjustmentSlider(label: "X Offset", value: binding(\.offsetX),
                                 range: -500...500, defaultValue: 0, step: 1, format: "%.0f")

                AdjustmentSlider(label: "Y Offset", value: binding(\.offsetY),
                                 range: -500...500, defaultValue: 0, step: 1, format: "%.0f")

                Divider().padding(.vertical, 2)

                // Flip toggles
                HStack(spacing: 12) {
                    Text("Flip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)

                    Toggle(isOn: boolBinding(\.flipH)) {
                        Label("H", systemImage: "arrow.left.arrow.right")
                            .font(.caption)
                    }
                    .toggleStyle(.button)
                    .controlSize(.small)

                    Spacer()
                }

                Button {
                    viewModel.resetTransforms(for: layer)
                } label: {
                    Label("Reset Transform", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!layerModel.hasTransforms)
                .padding(.top, 2)
            }
            .padding(.top, 4)
        } label: {
            Label("Transform", systemImage: "move.3d")
                .font(.subheadline.weight(.semibold))
        }
        .controlSize(.small)
    }
}
