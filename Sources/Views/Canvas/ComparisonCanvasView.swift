import SwiftUI

/// Main comparison viewport that renders both images with swiper or opacity blending.
/// In non-edit mode, the entire composite can be zoomed and panned as a single view.
/// In edit mode, individual layers can be repositioned, scaled, and rotated.
struct ComparisonCanvasView: View {
    @Bindable var viewModel: CanvasViewModel

    // Edit-mode per-layer drag state
    @State private var dragLayer: LayerSelection = .image1
    @State private var dragStartOffset: CGPoint = .zero
    @State private var isDragging = false

    // Non-edit mode canvas pan drag state
    @State private var panStartOffset: CGPoint = .zero

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack(alignment: .leading) {
                // Checkerboard background
                checkerboard
                    .frame(width: size.width, height: size.height)

                // Image layers (zoomed + panned)
                swiperContentView(size: size)
                    .scaleEffect(viewModel.canvasZoom)
                    .offset(x: viewModel.canvasPanX, y: viewModel.canvasPanY)

                // Swiper pill + divider on top (not zoomed, tracks zoom position)
                SwiperOverlayView(
                    swiperPosition: $viewModel.swiperPosition,
                    containerWidth: size.width,
                    showDividerLine: viewModel.showDividerLine,
                    lineColor: viewModel.dividerLineColor,
                    lineThickness: viewModel.dividerLineThickness,
                    canvasZoom: viewModel.canvasZoom,
                    canvasPanX: viewModel.canvasPanX
                )
            }
            .clipped()
            .contentShape(Rectangle())
            // Click to select layer
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        viewModel.selectLayerAtPoint(value.location, canvasSize: size)
                    }
            )
            // Drag gesture — behavior depends on edit mode
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        if viewModel.isEditMode {
                            handleEditModeDrag(value: value, size: size)
                        } else {
                            handleViewModeDrag(value: value)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            // Trackpad pinch
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        if viewModel.isEditMode {
                            let delta = (value - 1.0) * 4.0
                            viewModel.adjustScale(delta: delta)
                        } else {
                            // Zoom the whole canvas
                            let delta = (value - 1.0) * 2.0
                            viewModel.canvasZoom = max(0.1, min(4.0, viewModel.canvasZoom + delta))
                        }
                    }
            )
            // Trackpad two-finger rotate (edit mode only)
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { angle in
                        if viewModel.isEditMode {
                            viewModel.adjustRotation(deltaDegrees: angle.degrees * 0.1)
                        }
                    }
            )
            #if os(macOS)
            // Scroll wheel + right-click
            .onScrollWheel(onRightClick: {
                // Right-click toggles edit mode
                viewModel.isEditMode.toggle()
            }) { deltaX, deltaY in
                if viewModel.isEditMode {
                    handleEditModeScroll(deltaX: deltaX, deltaY: deltaY)
                } else {
                    handleViewModeScroll(deltaX: deltaX, deltaY: deltaY)
                }
            }
            #endif
            // Accept file drops
            .dropDestination(for: URL.self) { urls, location in
                handleDrop(urls: urls, at: location, in: size)
            }
        }
        .background(Color.canvasBackground)
    }

    // MARK: - Edit Mode Drag (per-layer)

    private func handleEditModeDrag(value: DragGesture.Value, size: CGSize) {
        if !isDragging {
            isDragging = true
            viewModel.saveUndoSnapshot()
            viewModel.selectLayerAtPoint(value.startLocation, canvasSize: size)
            dragLayer = viewModel.activeLayer
            dragStartOffset = CGPoint(
                x: dragLayer == .image1 ? viewModel.layer1.offsetX : viewModel.layer2.offsetX,
                y: dragLayer == .image1 ? viewModel.layer1.offsetY : viewModel.layer2.offsetY
            )
        }

        let newX = dragStartOffset.x + value.translation.width / viewModel.canvasZoom
        let newY = dragStartOffset.y + value.translation.height / viewModel.canvasZoom

        switch dragLayer {
        case .image1:
            viewModel.layer1.offsetX = newX
            viewModel.layer1.offsetY = newY
        case .image2:
            viewModel.layer2.offsetX = newX
            viewModel.layer2.offsetY = newY
        }
        viewModel.isDirty = true
    }

    // MARK: - View Mode Drag (canvas pan)

    private func handleViewModeDrag(value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            panStartOffset = CGPoint(x: viewModel.canvasPanX, y: viewModel.canvasPanY)
        }

        viewModel.canvasPanX = panStartOffset.x + value.translation.width
        viewModel.canvasPanY = panStartOffset.y + value.translation.height
    }

    // MARK: - Edit Mode Scroll

    private func handleEditModeScroll(deltaX: CGFloat, deltaY: CGFloat) {
        // Vertical = scale active layer, horizontal = rotate active layer
        if abs(deltaY) > 0.5 {
            viewModel.adjustScale(delta: deltaY)
        }
        if abs(deltaX) > 0.5 {
            viewModel.adjustRotation(deltaDegrees: deltaX * 0.3)
        }
    }

    // MARK: - View Mode Scroll (canvas zoom + opacity)

    private func handleViewModeScroll(deltaX: CGFloat, deltaY: CGFloat) {
        if abs(deltaY) > 0.5 {
            let zoomDelta = deltaY * 0.005
            viewModel.canvasZoom = max(0.1, min(4.0, viewModel.canvasZoom + zoomDelta))
        }
        if abs(deltaX) > 0.5 {
            let delta = deltaX * 0.003
            viewModel.adjustActiveLayerOpacity(delta: delta)
        }
    }

    // MARK: - Swiper Mode

    @ViewBuilder
    private func swiperContentView(size: CGSize) -> some View {
        ZStack(alignment: .leading) {
            if let img = viewModel.processedImage2 ?? viewModel.image2 {
                ImageLayerView(image: img, layer: viewModel.layer2, containerSize: size)
                    .frame(width: size.width, height: size.height)
            }
            if let img = viewModel.processedImage1 ?? viewModel.image1 {
                ImageLayerView(image: img, layer: viewModel.layer1, containerSize: size)
                    .frame(width: size.width, height: size.height)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: size.width * viewModel.swiperPosition)
                    }
            }
        }
    }

    // MARK: - Drop Handling

    private func handleDrop(urls: [URL], at location: CGPoint, in size: CGSize) -> Bool {
        let imageURLs = urls.filter { $0.isImageFile }
        guard !imageURLs.isEmpty else { return false }

        if viewModel.image1 == nil {
            viewModel.loadImage(from: imageURLs[0], into: .image1)
            if imageURLs.count > 1 {
                viewModel.loadImage(from: imageURLs[1], into: .image2)
            }
        } else if viewModel.image2 == nil {
            viewModel.loadImage(from: imageURLs[0], into: .image2)
        } else {
            viewModel.loadImage(from: imageURLs[0], into: viewModel.activeLayer)
        }
        return true
    }

    // MARK: - Checkerboard

    @ViewBuilder
    private var checkerboard: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 12
            let cols = Int(ceil(size.width / tileSize))
            let rows = Int(ceil(size.height / tileSize))
            let light = Color(white: 0.18)
            let dark = Color(white: 0.14)

            for row in 0..<rows {
                for col in 0..<cols {
                    let rect = CGRect(
                        x: CGFloat(col) * tileSize, y: CGFloat(row) * tileSize,
                        width: tileSize, height: tileSize
                    )
                    context.fill(Path(rect), with: .color((row + col) % 2 == 0 ? light : dark))
                }
            }
        }
    }
}
