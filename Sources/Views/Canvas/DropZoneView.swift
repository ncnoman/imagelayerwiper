import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import PhotosUI
#endif

/// Initial drag-and-drop landing zones shown when no images are loaded.
struct DropZoneView: View {
    @Bindable var viewModel: CanvasViewModel

    @State private var isTargeted1 = false
    @State private var isTargeted2 = false

    #if os(iOS)
    @State private var selectedItem1: PhotosPickerItem?
    @State private var selectedItem2: PhotosPickerItem?
    #endif

    var body: some View {
        HStack(spacing: 24) {
            #if os(macOS)
            dropTarget(
                label: "Image 1",
                sublabel: "Drag & drop your first photo",
                isTargeted: isTargeted1,
                layer: .image1,
                image: viewModel.image1
            )
            .dropDestination(for: URL.self) { urls, _ in
                handleDrop(urls, into: .image1)
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTargeted1 = targeted
                }
            }

            dropTarget(
                label: "Image 2",
                sublabel: "Drag & drop your second photo",
                isTargeted: isTargeted2,
                layer: .image2,
                image: viewModel.image2
            )
            .dropDestination(for: URL.self) { urls, _ in
                handleDrop(urls, into: .image2)
            } isTargeted: { targeted in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTargeted2 = targeted
                }
            }
            #else
            PhotosPicker(selection: $selectedItem1, matching: .images) {
                dropTarget(
                    label: "Image 1",
                    sublabel: "Tap to choose your first photo",
                    isTargeted: isTargeted1,
                    layer: .image1,
                    image: viewModel.image1
                )
            }
            .buttonStyle(.plain)
            .onChange(of: selectedItem1) { _, newItem in
                loadTransferable(from: newItem, into: .image1)
            }

            PhotosPicker(selection: $selectedItem2, matching: .images) {
                dropTarget(
                    label: "Image 2",
                    sublabel: "Tap to choose your second photo",
                    isTargeted: isTargeted2,
                    layer: .image2,
                    image: viewModel.image2
                )
            }
            .buttonStyle(.plain)
            .onChange(of: selectedItem2) { _, newItem in
                loadTransferable(from: newItem, into: .image2)
            }
            #endif
        }
        .padding(40)
    }

    // MARK: - Drop Target

    @ViewBuilder
    private func dropTarget(
        label: String,
        sublabel: String,
        isTargeted: Bool,
        layer: LayerSelection,
        image: PlatformImage?
    ) -> some View {
        VStack(spacing: 16) {
            if let image {
                // Show loaded image with a "replace" overlay
                ZStack {
                    Image(platformImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if isTargeted {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dropZoneActive.opacity(0.4))
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title)
                                    Text("Replace")
                                        .font(.callout.weight(.medium))
                                }
                                .foregroundStyle(.white)
                            }
                    }
                }
            } else {
                // Empty drop zone
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(isTargeted ? Color.controlAccent : .secondary)
                        .symbolEffect(.bounce, value: isTargeted)

                    Text(label)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(sublabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isTargeted ? Color.controlAccent : Color.dropZoneBorder,
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isTargeted ? Color.controlAccent.opacity(0.05) : Color.clear)
                        )
                }
                .scaleEffect(isTargeted ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: isTargeted)
            }
        }
    }

    // MARK: - Drop Handling

    #if os(macOS)
    private func handleDrop(_ urls: [URL], into layer: LayerSelection) -> Bool {
        let imageURLs = urls.filter { $0.isImageFile }
        guard !imageURLs.isEmpty else { return false }

        if imageURLs.count >= 2 {
            // Two+ images dropped — load both slots
            viewModel.loadImage(from: imageURLs[0], into: .image1)
            viewModel.loadImage(from: imageURLs[1], into: .image2)
        } else {
            viewModel.loadImage(from: imageURLs[0], into: layer)
        }
        return true
    }
    #endif

    #if os(iOS)
    private func loadTransferable(from item: PhotosPickerItem?, into layer: LayerSelection) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { result in
            if case .success(let data) = result, let data, let image = PlatformImage(data: data) {
                Task { @MainActor in
                    switch layer {
                    case .image1:
                        viewModel.image1 = image
                    case .image2:
                        viewModel.image2 = image
                    }
                }
            }
        }
    }
    #endif
}
