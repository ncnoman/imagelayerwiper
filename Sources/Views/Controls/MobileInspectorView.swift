#if os(iOS)
import SwiftUI

/// Bottom-sheet inspector for iOS with tabbed sections.
struct MobileInspectorView: View {
    @Bindable var viewModel: CanvasViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $selectedTab) {
                    Text("Transform").tag(0)
                    Text("Adjustments").tag(1)
                    Text("Perspective").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Active layer indicator
                HStack {
                    Image(systemName: "photo.stack")
                    Text("Editing: \(viewModel.activeLayer.rawValue)")
                        .font(.subheadline.weight(.medium))
                    Spacer()

                    Picker("Layer", selection: $viewModel.activeLayer) {
                        ForEach(LayerSelection.allCases) { layer in
                            Text(layer.rawValue).tag(layer)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 160)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Tab content
                ScrollView {
                    VStack(spacing: 12) {
                        switch selectedTab {
                        case 0:
                            TransformControlsView(viewModel: viewModel, layer: viewModel.activeLayer)
                        case 1:
                            AdjustmentPanelView(viewModel: viewModel, layer: viewModel.activeLayer)
                        case 2:
                            PerspectiveControlsView(viewModel: viewModel, layer: viewModel.activeLayer)
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif
