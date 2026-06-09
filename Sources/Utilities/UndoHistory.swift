import Foundation

/// Snapshot of both layer states at a point in time.
struct LayerSnapshot: Equatable {
    let layer1: ImageLayer
    let layer2: ImageLayer
}

/// Manages undo/redo history using a snapshot stack.
/// Captures (layer1, layer2) pairs. Capped at 50 entries.
@Observable
@MainActor
final class UndoHistory {
    private var undoStack: [LayerSnapshot] = []
    private var redoStack: [LayerSnapshot] = []
    private let maxEntries = 50

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Save current state before a mutation. Clears redo stack.
    func saveSnapshot(layer1: ImageLayer, layer2: ImageLayer) {
        let snapshot = LayerSnapshot(layer1: layer1, layer2: layer2)

        // Don't push duplicate snapshots
        if undoStack.last == snapshot { return }

        undoStack.append(snapshot)
        if undoStack.count > maxEntries {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    /// Undo: pops the last snapshot, pushes current state to redo.
    /// Returns the snapshot to restore, or nil if nothing to undo.
    func undo(currentLayer1: ImageLayer, currentLayer2: ImageLayer) -> LayerSnapshot? {
        guard let snapshot = undoStack.popLast() else { return nil }
        redoStack.append(LayerSnapshot(layer1: currentLayer1, layer2: currentLayer2))
        return snapshot
    }

    /// Redo: pops the last redo snapshot, pushes current state to undo.
    /// Returns the snapshot to restore, or nil if nothing to redo.
    func redo(currentLayer1: ImageLayer, currentLayer2: ImageLayer) -> LayerSnapshot? {
        guard let snapshot = redoStack.popLast() else { return nil }
        undoStack.append(LayerSnapshot(layer1: currentLayer1, layer2: currentLayer2))
        return snapshot
    }

    /// Clear all history (e.g., when loading a new session).
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
