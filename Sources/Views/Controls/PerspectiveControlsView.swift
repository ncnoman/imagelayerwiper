import SwiftUI

/// Inspector section for 3D perspective rotation controls on a specific layer.
struct PerspectiveControlsView: View {
    @Bindable var viewModel: CanvasViewModel
    let layer: LayerSelection

    @State private var isExpanded = true

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

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 6) {
                AdjustmentSlider(label: "X Rotation", value: binding(\.perspectiveX),
                                 range: -60...60, defaultValue: 0, step: 1, format: "%.1f°")

                AdjustmentSlider(label: "Y Rotation", value: binding(\.perspectiveY),
                                 range: -60...60, defaultValue: 0, step: 1, format: "%.1f°")

                AdjustmentSlider(label: "Z Rotation", value: binding(\.perspectiveZ),
                                 range: -180...180, defaultValue: 0, step: 1, format: "%.1f°")

                AdjustmentSlider(label: "Strength", value: binding(\.perspectiveStrength),
                                 range: 0.1...1.0, defaultValue: 0.5, step: 0.05, format: "%.2f")

                Button {
                    viewModel.resetPerspective(for: layer)
                } label: {
                    Label("Reset Perspective", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!layerModel.hasPerspective)
                .padding(.top, 2)
            }
            .padding(.top, 4)
        } label: {
            Label("3D Perspective", systemImage: "cube")
                .font(.subheadline.weight(.semibold))
        }
        .controlSize(.small)
    }
}
