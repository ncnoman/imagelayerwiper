import SwiftUI

/// Toolbar content — labeled buttons with proper spacing.
struct ToolbarControls: ToolbarContent {
    @Bindable var viewModel: CanvasViewModel
    @Environment(SessionStore.self) private var sessionStore
    var showExport: Binding<Bool>
    @State private var showLineSettings = false

    private let lineColorOptions: [(String, Color)] = [
        ("White", .white),
        ("Black", .black),
        ("Red", Color(hue: 0.0, saturation: 0.8, brightness: 0.95)),
        ("Orange", Color(hue: 0.08, saturation: 0.85, brightness: 0.95)),
        ("Yellow", Color(hue: 0.15, saturation: 0.8, brightness: 0.95)),
        ("Green", Color(hue: 0.35, saturation: 0.75, brightness: 0.85)),
        ("Blue", Color(hue: 0.6, saturation: 0.7, brightness: 0.95)),
        ("Purple", Color(hue: 0.78, saturation: 0.65, brightness: 0.9)),
    ]

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            HStack(spacing: 0) {
                Spacer().frame(width: 12)

                // Edit mode toggle
                Button {
                    viewModel.isEditMode.toggle()
                } label: {
                    Label("Edit", systemImage: viewModel.isEditMode ? "pencil.circle.fill" : "pencil.circle")
                        .font(.subheadline)
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.isEditMode ? Color.controlAccent : .secondary)
                .fixedSize()

                Spacer().frame(width: 20)

                // Divider line toggle + settings
                HStack(spacing: 4) {
                    Button {
                        viewModel.showDividerLine.toggle()
                    } label: {
                        Label("Line", systemImage: "line.diagonal")
                            .font(.subheadline)
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(viewModel.showDividerLine ? Color.controlAccent : .secondary)

                    Button {
                        showLineSettings.toggle()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .popover(isPresented: $showLineSettings, arrowEdge: .bottom) {
                        lineSettingsPopover
                    }
                }
                .fixedSize()

                Divider().frame(height: 18).padding(.horizontal, 10)

                // Undo / Redo
                tbIcon(icon: "arrow.uturn.backward", disabled: !viewModel.canUndo) { viewModel.undo() }
                    .padding(.trailing, 6)
                tbIcon(icon: "arrow.uturn.forward", disabled: !viewModel.canRedo) { viewModel.redo() }

                Divider().frame(height: 18).padding(.horizontal, 10)

                // Swap layers
                tbLabeledButton(icon: "arrow.left.arrow.right", label: "Swap", disabled: !viewModel.hasBothImages) {
                    viewModel.swapLayers()
                }

                Spacer().frame(width: 20)

                // Save
                tbLabeledButton(icon: "square.and.arrow.down", label: "Save", disabled: !viewModel.isDirty) {
                    viewModel.saveToStore(sessionStore)
                }

                Spacer().frame(width: 20)

                // Export
                tbLabeledButton(icon: "square.and.arrow.up", label: "Export", disabled: !viewModel.hasAnyImage) {
                    showExport.wrappedValue = true
                }
                .padding(.trailing, 16)
            }
        }
    }

    // MARK: - Line Settings Popover

    @ViewBuilder
    private var lineSettingsPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Divider Line")
                .font(.headline)

            // Color palette
            Text("Color")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(lineColorOptions, id: \.0) { name, color in
                    Circle()
                        .fill(color)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    viewModel.dividerLineColor == color ? Color.controlAccent : .clear,
                                    lineWidth: 2
                                )
                                .frame(width: 26, height: 26)
                        }
                        .overlay {
                            if color == .black {
                                Circle().strokeBorder(.gray.opacity(0.5), lineWidth: 0.5)
                            }
                        }
                        .onTapGesture {
                            viewModel.dividerLineColor = color
                        }
                        .help(name)
                }
            }

            // Thickness slider
            Text("Thickness")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Slider(value: $viewModel.dividerLineThickness, in: 0.5...6.0, step: 0.5)
                    .frame(width: 140)

                Text("\(viewModel.dividerLineThickness, specifier: "%.1f")px")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 40)
            }
        }
        .padding(16)
        .frame(width: 260)
    }

    /// Icon-only button
    private func tbIcon(
        icon: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.35 : 1.0)
        .disabled(disabled)
    }

    /// Labeled button with icon + text side by side
    private func tbLabeledButton(
        icon: String,
        label: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.35 : 1.0)
        .disabled(disabled)
        .fixedSize()
    }
}
