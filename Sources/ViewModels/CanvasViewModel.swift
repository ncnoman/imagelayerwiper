import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Combine

/// Central view model managing the canvas state for the active comparison session.
/// Handles image loading, layer state, comparison mode, and auto-save.
@Observable
@MainActor
final class CanvasViewModel {
    // MARK: - Loaded images (not persisted — loaded from disk)
    var image1: PlatformImage?
    var image2: PlatformImage?

    // MARK: - Processed images (after filter application)
    var processedImage1: PlatformImage?
    var processedImage2: PlatformImage?

    // MARK: - Layer state
    var layer1 = ImageLayer()
    var layer2 = ImageLayer()

    // MARK: - Canvas state
    var activeLayer: LayerSelection = .image1
    var comparisonMode: ComparisonMode = .swiper
    var swiperPosition: Double = 0.5
    var opacityValue: Double = 0.0
    var isEditMode: Bool = false
    var showDividerLine: Bool = true
    var dividerLineColor: Color = .white
    var dividerLineThickness: Double = 1.0
    var canvasZoom: Double = 1.0
    var canvasPanX: Double = 0.0
    var canvasPanY: Double = 0.0

    /// Saved pill position for swiper mode (so switching modes doesn't lose it).
    private var savedSwiperPosition: Double = 0.5

    /// Switch comparison mode, resetting pill position appropriately.
    func setComparisonMode(_ mode: ComparisonMode) {
        if comparisonMode == .swiper {
            savedSwiperPosition = swiperPosition
        }
        comparisonMode = mode
        if mode == .opacity {
            swiperPosition = 0.0
        } else {
            swiperPosition = savedSwiperPosition
        }
    }

    // MARK: - Session reference
    var currentSessionId: UUID?
    var currentSessionName: String = ""
    var isDirty: Bool = false

    // MARK: - Filter service
    private let filterService = ImageFilterService.shared

    // MARK: - Undo/Redo
    private let undoHistory = UndoHistory()

    var canUndo: Bool { undoHistory.canUndo }
    var canRedo: Bool { undoHistory.canRedo }

    /// Save a snapshot of the current layer state before a mutation.
    func saveUndoSnapshot() {
        undoHistory.saveSnapshot(layer1: layer1, layer2: layer2)
    }

    /// Undo the last layer mutation.
    func undo() {
        guard let snapshot = undoHistory.undo(currentLayer1: layer1, currentLayer2: layer2) else { return }
        layer1 = snapshot.layer1
        layer2 = snapshot.layer2
        reprocessImage(for: .image1)
        reprocessImage(for: .image2)
        isDirty = true
    }

    /// Redo the last undone mutation.
    func redo() {
        guard let snapshot = undoHistory.redo(currentLayer1: layer1, currentLayer2: layer2) else { return }
        layer1 = snapshot.layer1
        layer2 = snapshot.layer2
        reprocessImage(for: .image1)
        reprocessImage(for: .image2)
        isDirty = true
    }

    // MARK: - Computed properties

    /// The currently active layer model (for reading).
    var activeLayerModel: ImageLayer {
        get {
            activeLayer == .image1 ? layer1 : layer2
        }
    }

    /// The currently active image (for display).
    var activeImage: PlatformImage? {
        activeLayer == .image1 ? image1 : image2
    }

    /// Whether both images are loaded.
    var hasBothImages: Bool {
        image1 != nil && image2 != nil
    }

    /// Whether any image is loaded.
    var hasAnyImage: Bool {
        image1 != nil || image2 != nil
    }

    /// Swaps Image 1 and Image 2 (images, layers, and processed results).
    func swapLayers() {
        saveUndoSnapshot()
        swap(&image1, &image2)
        swap(&processedImage1, &processedImage2)
        swap(&layer1, &layer2)
        isDirty = true
    }

    // MARK: - Active layer binding helpers

    var activeRotation: Double {
        get { activeLayerModel.rotation }
        set { updateActiveLayer { $0.rotation = newValue } }
    }

    var activeScale: Double {
        get { activeLayerModel.scale }
        set { updateActiveLayer { $0.scale = newValue } }
    }

    var activeOffsetX: Double {
        get { activeLayerModel.offsetX }
        set { updateActiveLayer { $0.offsetX = newValue } }
    }

    var activeOffsetY: Double {
        get { activeLayerModel.offsetY }
        set { updateActiveLayer { $0.offsetY = newValue } }
    }

    var activeFlipH: Bool {
        get { activeLayerModel.flipH }
        set { updateActiveLayer { $0.flipH = newValue } }
    }

    var activeFlipV: Bool {
        get { activeLayerModel.flipV }
        set { updateActiveLayer { $0.flipV = newValue } }
    }

    var activePerspectiveX: Double {
        get { activeLayerModel.perspectiveX }
        set { updateActiveLayer { $0.perspectiveX = newValue } }
    }

    var activePerspectiveY: Double {
        get { activeLayerModel.perspectiveY }
        set { updateActiveLayer { $0.perspectiveY = newValue } }
    }

    var activePerspectiveZ: Double {
        get { activeLayerModel.perspectiveZ }
        set { updateActiveLayer { $0.perspectiveZ = newValue } }
    }

    var activePerspectiveStrength: Double {
        get { activeLayerModel.perspectiveStrength }
        set { updateActiveLayer { $0.perspectiveStrength = newValue } }
    }

    var activeAdjustments: ImageAdjustments {
        get { activeLayerModel.adjustments }
        set { updateActiveLayer { $0.adjustments = newValue } }
    }

    // MARK: - Image Loading

    /// Loads an image from a file URL into the specified layer.
    func loadImage(from url: URL, into layer: LayerSelection) {
        guard url.isImageFile || PlatformImage.fromURL(url) != nil else { return }
        guard let image = PlatformImage.fromURL(url) else { return }

        // Resize for viewport performance (keep original for export)
        let viewportImage = image.resizedToFit(maxDimension: 4000)

        switch layer {
        case .image1:
            self.image1 = viewportImage
            self.layer1.imageFileName = url.lastPathComponent
            reprocessImage(for: .image1)
        case .image2:
            self.image2 = viewportImage
            self.layer2.imageFileName = url.lastPathComponent
            reprocessImage(for: .image2)
        }
        isDirty = true
    }

    // MARK: - Filter Processing

    /// Reprocesses the image for the given layer through the filter pipeline.
    func reprocessImage(for layer: LayerSelection) {
        switch layer {
        case .image1:
            if let img = image1 {
                processedImage1 = filterService.apply(layer1.adjustments, to: img)
            }
        case .image2:
            if let img = image2 {
                processedImage2 = filterService.apply(layer2.adjustments, to: img)
            }
        }
    }

    /// Reprocesses the active layer's image.
    func reprocessActiveImage() {
        reprocessImage(for: activeLayer)
    }

    // MARK: - Reset Methods

    func resetTransforms() {
        saveUndoSnapshot()
        updateActiveLayer { $0.resetTransforms() }
    }

    func resetAdjustments() {
        saveUndoSnapshot()
        updateActiveLayer { $0.resetAdjustments() }
        reprocessActiveImage()
    }

    func resetPerspective() {
        saveUndoSnapshot()
        updateActiveLayer { $0.resetPerspective() }
    }

    func resetAll() {
        saveUndoSnapshot()
        updateActiveLayer { $0.resetAll() }
        reprocessActiveImage()
    }

    // MARK: - Direct Canvas Manipulation (Mouse Edit Mode)

    /// Selects the layer under the given point in the canvas.
    /// In swiper mode, uses the swiper position as the boundary.
    /// In opacity mode, toggles between layers on click.
    func selectLayerAtPoint(_ point: CGPoint, canvasSize: CGSize) {
        switch comparisonMode {
        case .swiper:
            let boundary = canvasSize.width * swiperPosition
            activeLayer = point.x < boundary ? .image1 : .image2
        case .opacity:
            // Toggle active layer on click
            activeLayer = activeLayer == .image1 ? .image2 : .image1
        }
    }

    /// Adjusts the offset of a specific layer by a delta.
    func adjustOffset(for layer: LayerSelection, dx: CGFloat, dy: CGFloat) {
        switch layer {
        case .image1:
            layer1.offsetX += Double(dx)
            layer1.offsetY += Double(dy)
        case .image2:
            layer2.offsetX += Double(dx)
            layer2.offsetY += Double(dy)
        }
        isDirty = true
    }

    /// Adjusts the scale of the active layer by a multiplicative delta.
    func adjustScale(delta: CGFloat) {
        let scaleFactor = 1.0 + Double(delta) * 0.005
        updateActiveLayer { layer in
            layer.scale = max(0.1, min(5.0, layer.scale * scaleFactor))
        }
    }

    /// Adjusts the rotation of the active layer by a delta in degrees.
    func adjustRotation(deltaDegrees: CGFloat) {
        updateActiveLayer { layer in
            layer.rotation = (layer.rotation + Double(deltaDegrees)).truncatingRemainder(dividingBy: 360)
            if layer.rotation < 0 { layer.rotation += 360 }
        }
    }

    /// Adjusts the opacity of the active layer by a delta.
    func adjustActiveLayerOpacity(delta: Double) {
        updateActiveLayer { layer in
            layer.opacity = max(0, min(1, layer.opacity + delta))
        }
    }

    /// Gradually adjusts the hue rotation of the active layer.
    func adjustActiveHueRotation(delta: CGFloat) {
        updateActiveLayer { layer in
            var hue = layer.adjustments.hueRotation + Double(delta)
            // Wrap around 0–360
            hue = hue.truncatingRemainder(dividingBy: 360)
            if hue < 0 { hue += 360 }
            layer.adjustments.hueRotation = hue
        }
        reprocessActiveImage()
    }

    // MARK: - Canvas Zoom

    func zoomIn() {
        canvasZoom = min(4.0, canvasZoom * 1.25)
    }

    func zoomOut() {
        canvasZoom = max(0.1, canvasZoom / 1.25)
    }

    func resetZoom() {
        canvasZoom = 1.0
        canvasPanX = 0.0
        canvasPanY = 0.0
    }

    // MARK: - Layer-Specific Resets

    func resetTransforms(for layer: LayerSelection) {
        switch layer {
        case .image1: layer1.resetTransforms()
        case .image2: layer2.resetTransforms()
        }
        isDirty = true
    }

    func resetAdjustments(for layer: LayerSelection) {
        switch layer {
        case .image1: layer1.resetAdjustments()
        case .image2: layer2.resetAdjustments()
        }
        reprocessImage(for: layer)
        isDirty = true
    }

    func resetPerspective(for layer: LayerSelection) {
        switch layer {
        case .image1: layer1.resetPerspective()
        case .image2: layer2.resetPerspective()
        }
        isDirty = true
    }

    // MARK: - Session Serialisation

    /// Creates a Session from the current canvas state.
    func toSession() -> Session {
        var session = Session(name: currentSessionName.isEmpty ? "Untitled" : currentSessionName)
        if let existingId = currentSessionId {
            session.id = existingId
        }
        session.layer1 = layer1
        session.layer2 = layer2
        session.comparisonMode = comparisonMode
        session.swiperPosition = swiperPosition
        session.opacityValue = opacityValue
        return session
    }

    /// Restores canvas state from a saved session.
    func loadSession(_ session: Session, sessionStore: SessionStore) {
        currentSessionId = session.id
        currentSessionName = session.name
        layer1 = session.layer1
        layer2 = session.layer2
        comparisonMode = session.comparisonMode
        swiperPosition = 0.5
        opacityValue = session.opacityValue

        // Load images from disk
        image1 = sessionStore.loadImage(for: session, layer: .image1)
        image2 = sessionStore.loadImage(for: session, layer: .image2)

        // Apply filters
        reprocessImage(for: .image1)
        reprocessImage(for: .image2)

        isDirty = false
    }

    /// Saves the current state to a session store.
    func saveToStore(_ store: SessionStore) {
        let session = toSession()
        store.save(session, image1: image1, image2: image2)
        currentSessionId = session.id
        isDirty = false
    }

    /// Resets the canvas to a clean state for a new session.
    func newSession() {
        currentSessionId = nil
        currentSessionName = ""
        image1 = nil
        image2 = nil
        processedImage1 = nil
        processedImage2 = nil
        layer1 = ImageLayer()
        layer2 = ImageLayer()
        activeLayer = .image1
        comparisonMode = .swiper
        swiperPosition = 0.5
        opacityValue = 0.5
        canvasZoom = 1.0
        isDirty = false
    }

    // MARK: - Private Helpers

    private func updateActiveLayer(_ mutation: (inout ImageLayer) -> Void) {
        switch activeLayer {
        case .image1: mutation(&layer1)
        case .image2: mutation(&layer2)
        }
        isDirty = true
    }
}
