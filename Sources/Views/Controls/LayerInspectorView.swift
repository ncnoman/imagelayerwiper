import SwiftUI

/// Composite inspector panel for a single image layer.
/// Contains Transform, 3D Perspective, and Adjustment sections
/// all bound to the specified layer.
struct LayerInspectorView: View {
    @Bindable var viewModel: CanvasViewModel
    let layer: LayerSelection

    private var hasImage: Bool {
        layer == .image1 ? viewModel.image1 != nil : viewModel.image2 != nil
    }

    private var layerModel: ImageLayer {
        layer == .image1 ? viewModel.layer1 : viewModel.layer2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            if hasImage {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        TransformControlsView(viewModel: viewModel, layer: layer)
                        PerspectiveControlsView(viewModel: viewModel, layer: layer)

                        Divider().padding(.horizontal, 4)

                        AdjustmentPanelView(viewModel: viewModel, layer: layer)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            } else {
                emptyState
            }
        }
        .background(Color.panelBackground)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(layer == .image1 ? Color.blue.opacity(0.7) : Color.orange.opacity(0.7))
                .frame(width: 8, height: 8)

            Text(layer.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            if viewModel.activeLayer == layer {
                Text("Active")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.controlAccent.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(Color.controlAccent)
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text("Drop an image")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
