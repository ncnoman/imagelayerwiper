import SwiftUI

/// A single row in the session sidebar showing name, date, and thumbnail previews.
struct SessionRowView: View {
    let session: Session
    let isRenaming: Bool
    @Binding var renameText: String
    var onCommitRename: () -> Void

    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail previews
            HStack(spacing: 3) {
                thumbnail(for: .image1)
                thumbnail(for: .image2)
            }

            // Name and date
            VStack(alignment: .leading, spacing: 2) {
                if isRenaming {
                    TextField("Session name", text: $renameText)
                        .textFieldStyle(.plain)
                        .font(.callout.weight(.medium))
                        .onSubmit { onCommitRename() }
                } else {
                    Text(session.name)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text(session.modifiedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func thumbnail(for layer: LayerSelection) -> some View {
        let layerModel = (layer == .image1) ? session.layer1 : session.layer2

        if layerModel.hasImage, let image = sessionStore.loadImage(for: session, layer: layer) {
            Image(platformImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "photo")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
        }
    }
}
