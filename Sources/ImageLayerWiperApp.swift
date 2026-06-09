import SwiftUI

@main
struct ImageLayerWiperApp: App {
    @State private var sessionStore = SessionStore()
    @State private var viewModel = CanvasViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(sessionStore)
                #if os(macOS)
                .frame(minWidth: 1200, minHeight: 800)
                #endif
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 1400, height: 900)
        .commands {
            // Replace the default Undo/Redo commands
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { viewModel.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!viewModel.canUndo)
                Button("Redo") { viewModel.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!viewModel.canRedo)
            }
        }
        #endif
    }
}
