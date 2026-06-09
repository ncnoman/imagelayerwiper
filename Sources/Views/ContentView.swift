import SwiftUI

/// Main application layout.
/// macOS: `[Session Sidebar] | [Inspector 1] | [Canvas] | [Inspector 2]`
/// iOS: Full-screen canvas with bottom sheet inspector and navigation toolbar.
struct ContentView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Bindable var viewModel: CanvasViewModel
    @State private var showExportSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    #if os(iOS)
    @State private var showInspector = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SessionSidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 280)
        } detail: {
            HStack(spacing: 0) {
                // Left inspector — Image 1
                LayerInspectorView(viewModel: viewModel, layer: .image1)
                    .frame(width: 250)

                Divider()

                // Center — Canvas or drop zone
                canvasArea

                Divider()

                // Right inspector — Image 2
                LayerInspectorView(viewModel: viewModel, layer: .image2)
                    .frame(width: 250)
            }
            .toolbar {
                ToolbarControls(
                    viewModel: viewModel,
                    showExport: $showExportSheet
                )
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(viewModel: viewModel)
            }
        }
        .navigationTitle(viewModel.currentSessionName.isEmpty ? "ImageLayerWiper" : viewModel.currentSessionName)
        .onAppear { loadFirstSession() }
    }
    #endif

    // MARK: - iOS Layout

    #if os(iOS)
    private var iOSLayout: some View {
        NavigationStack {
            canvasArea
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        // Mode toggle
                        Picker("Mode", selection: $viewModel.comparisonMode) {
                            ForEach(ComparisonMode.allCases) { mode in
                                Label(mode.label, systemImage: mode.icon).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 140)

                        Spacer()

                        // Layer picker
                        Picker("Layer", selection: $viewModel.activeLayer) {
                            ForEach(LayerSelection.allCases) { layer in
                                Text(layer.rawValue).tag(layer)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 160)

                        Spacer()

                        Button {
                            showInspector = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            viewModel.saveToStore(sessionStore)
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .disabled(!viewModel.isDirty)

                        Button {
                            showExportSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(!viewModel.hasAnyImage)
                    }
                }
                .sheet(isPresented: $showInspector) {
                    MobileInspectorView(viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showExportSheet) {
                    ExportSheet(viewModel: viewModel)
                }
        }
        .navigationTitle(viewModel.currentSessionName.isEmpty ? "ImageLayerWiper" : viewModel.currentSessionName)
        .onAppear { loadFirstSession() }
    }
    #endif

    // MARK: - Shared Canvas Area

    private var canvasArea: some View {
        ZStack {
            Color.canvasBackground.ignoresSafeArea()

            if viewModel.hasAnyImage {
                ComparisonCanvasView(viewModel: viewModel)
            } else {
                DropZoneView(viewModel: viewModel)
            }

            // Bottom-center zoom badge
            VStack {
                Spacer()
                zoomBadge
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func loadFirstSession() {
        if let first = sessionStore.sessions.first {
            viewModel.loadSession(first, sessionStore: sessionStore)
            sessionStore.selectedSessionId = first.id
        }
    }

    // MARK: - Zoom Badge

    @ViewBuilder
    private var zoomBadge: some View {
        if viewModel.canvasZoom != 1.0 {
            Text("\(Int(viewModel.canvasZoom * 100))%")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(.black.opacity(0.5))
                        .overlay {
                            Capsule()
                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.resetZoom()
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.2), value: viewModel.canvasZoom)
        }
    }
}
