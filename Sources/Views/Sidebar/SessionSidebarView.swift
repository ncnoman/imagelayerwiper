import SwiftUI

/// Sidebar listing all saved sessions with create, rename, duplicate, and delete actions.
struct SessionSidebarView: View {
    @Bindable var viewModel: CanvasViewModel
    @Environment(SessionStore.self) private var sessionStore
    @State private var renamingSessionId: UUID?
    @State private var renameText: String = ""
    @State private var showDeleteConfirmation = false
    @State private var sessionToDelete: Session?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sessions")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    createNewSession()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.controlAccent)
                }
                .buttonStyle(.plain)
                .help("New Session")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Session list
            if sessionStore.sessions.isEmpty {
                emptyState
            } else {
                List(selection: Binding(
                    get: { sessionStore.selectedSessionId },
                    set: { newId in
                        if let id = newId,
                           let session = sessionStore.sessions.first(where: { $0.id == id }) {
                            selectSession(session)
                        }
                    }
                )) {
                    ForEach(sessionStore.sessions) { session in
                        SessionRowView(
                            session: session,
                            isRenaming: renamingSessionId == session.id,
                            renameText: renamingSessionId == session.id ? $renameText : .constant(""),
                            onCommitRename: { commitRename(for: session) }
                        )
                        .tag(session.id)
                        .contextMenu {
                            sessionContextMenu(for: session)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    sessionStore.delete(session)
                    if sessionStore.selectedSessionId == session.id {
                        viewModel.newSession()
                    }
                }
            }
        } message: {
            Text("This will permanently delete \"\(sessionToDelete?.name ?? "")\" and its images.")
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No Sessions")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Create a new session to start comparing images.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button("New Session") {
                createNewSession()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            Spacer()
        }
        .padding()
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func sessionContextMenu(for session: Session) -> some View {
        Button {
            renamingSessionId = session.id
            renameText = session.name
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button {
            let dup = sessionStore.duplicate(session)
            selectSession(dup)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            sessionToDelete = session
            showDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Actions

    private func createNewSession() {
        // Auto-save current session if dirty
        if viewModel.isDirty, viewModel.currentSessionId != nil {
            viewModel.saveToStore(sessionStore)
        }

        let newSession = Session.newSession()
        sessionStore.save(newSession)
        viewModel.newSession()
        viewModel.currentSessionId = newSession.id
        viewModel.currentSessionName = newSession.name
        sessionStore.selectedSessionId = newSession.id
    }

    private func selectSession(_ session: Session) {
        // Auto-save current session if dirty
        if viewModel.isDirty, viewModel.currentSessionId != nil {
            viewModel.saveToStore(sessionStore)
        }

        sessionStore.selectedSessionId = session.id
        viewModel.loadSession(session, sessionStore: sessionStore)
    }

    private func commitRename(for session: Session) {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            sessionStore.rename(session, to: trimmed)
            if viewModel.currentSessionId == session.id {
                viewModel.currentSessionName = trimmed
            }
        }
        renamingSessionId = nil
    }
}
