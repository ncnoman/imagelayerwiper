import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Manages persistence of comparison sessions to disk.
///
/// Storage layout:
/// ```
/// ~/Library/Application Support/ImageLayerWiper/Sessions/
///   <session-uuid>/
///     session.json       — serialised Session struct
///     image1.png         — copy of the first image
///     image2.png         — copy of the second image
/// ```
@Observable
final class SessionStore {
    var sessions: [Session] = []
    var selectedSessionId: UUID?

    private let baseDirectory: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        self.baseDirectory = appSupport
            .appendingPathComponent("ImageLayerWiper", isDirectory: true)
            .appendingPathComponent("Sessions", isDirectory: true)

        ensureDirectoryExists(baseDirectory)
        loadAll()
    }

    // MARK: - Public API

    func loadAll() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            sessions = []
            return
        }

        sessions = contents.compactMap { dir -> Session? in
            let jsonURL = dir.appendingPathComponent("session.json")
            guard FileManager.default.fileExists(atPath: jsonURL.path) else { return nil }
            guard let data = try? Data(contentsOf: jsonURL) else { return nil }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try? decoder.decode(Session.self, from: data)
        }.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    func save(_ session: Session, image1: PlatformImage? = nil, image2: PlatformImage? = nil) {
        var session = session
        session.modifiedAt = Date()

        let sessionDir = directory(for: session)
        ensureDirectoryExists(sessionDir)

        // Save images if provided
        if let img = image1 {
            saveImage(img, to: sessionDir.appendingPathComponent("image1.png"))
            session.layer1.imageFileName = "image1.png"
        }
        if let img = image2 {
            saveImage(img, to: sessionDir.appendingPathComponent("image2.png"))
            session.layer2.imageFileName = "image2.png"
        }

        // Save session JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(session) {
            try? data.write(to: sessionDir.appendingPathComponent("session.json"), options: .atomic)
        }

        // Update in-memory list
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
    }

    func delete(_ session: Session) {
        let sessionDir = directory(for: session)
        try? FileManager.default.removeItem(at: sessionDir)
        sessions.removeAll { $0.id == session.id }
        if selectedSessionId == session.id {
            selectedSessionId = sessions.first?.id
        }
    }

    func duplicate(_ session: Session) -> Session {
        var newSession = session
        newSession.id = UUID()
        newSession.name = "\(session.name) (Copy)"
        newSession.createdAt = Date()
        newSession.modifiedAt = Date()

        let sourceDir = directory(for: session)
        let destDir = directory(for: newSession)
        ensureDirectoryExists(destDir)

        // Copy image files
        for fileName in ["image1.png", "image2.png"] {
            let src = sourceDir.appendingPathComponent(fileName)
            let dst = destDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: src.path) {
                try? FileManager.default.copyItem(at: src, to: dst)
            }
        }

        // Save the new session JSON
        save(newSession)
        return newSession
    }

    func rename(_ session: Session, to name: String) {
        guard var updated = sessions.first(where: { $0.id == session.id }) else { return }
        updated.name = name
        save(updated)
    }

    // MARK: - Image Loading

    func loadImage(for session: Session, layer: LayerSelection) -> PlatformImage? {
        let layerModel = (layer == .image1) ? session.layer1 : session.layer2
        guard let fileName = layerModel.imageFileName else { return nil }
        let fileURL = directory(for: session).appendingPathComponent(fileName)
        return PlatformImage.fromURL(fileURL)
    }

    func imageURL(for session: Session, layer: LayerSelection) -> URL? {
        let layerModel = (layer == .image1) ? session.layer1 : session.layer2
        guard let fileName = layerModel.imageFileName else { return nil }
        return directory(for: session).appendingPathComponent(fileName)
    }

    // MARK: - Private

    private func directory(for session: Session) -> URL {
        baseDirectory.appendingPathComponent(session.id.uuidString, isDirectory: true)
    }

    private func ensureDirectoryExists(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func saveImage(_ image: PlatformImage, to url: URL) {
        guard let pngData = image.pngImageData() else { return }
        try? pngData.write(to: url, options: .atomic)
    }
}
