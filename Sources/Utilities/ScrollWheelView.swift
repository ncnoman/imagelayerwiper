#if os(macOS)
import SwiftUI
import AppKit

/// Captures scroll-wheel and right-click events via NSEvent local monitors.
/// This avoids interfering with SwiftUI's gesture system.
struct ScrollWheelModifier: ViewModifier {
    let onScroll: (_ deltaX: CGFloat, _ deltaY: CGFloat) -> Void
    var onRightClick: (() -> Void)?

    @State private var scrollMonitor: Any?
    @State private var rightClickMonitor: Any?
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
            }
            .onAppear {
                scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    guard isHovering else { return event }

                    let dx: CGFloat
                    let dy: CGFloat

                    if event.hasPreciseScrollingDeltas {
                        dx = event.scrollingDeltaX
                        dy = event.scrollingDeltaY
                    } else {
                        dx = event.deltaX * 10
                        dy = event.deltaY * 10
                    }

                    if abs(dx) > 0.5 || abs(dy) > 0.5 {
                        onScroll(dx, dy)
                        return nil
                    }
                    return event
                }

                if onRightClick != nil {
                    rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
                        guard isHovering else { return event }
                        onRightClick?()
                        return nil // consume the event
                    }
                }
            }
            .onDisappear {
                if let scrollMonitor {
                    NSEvent.removeMonitor(scrollMonitor)
                }
                if let rightClickMonitor {
                    NSEvent.removeMonitor(rightClickMonitor)
                }
                scrollMonitor = nil
                rightClickMonitor = nil
            }
    }
}

extension View {
    func onScrollWheel(
        onRightClick: (() -> Void)? = nil,
        _ handler: @escaping (_ deltaX: CGFloat, _ deltaY: CGFloat) -> Void
    ) -> some View {
        modifier(ScrollWheelModifier(onScroll: handler, onRightClick: onRightClick))
    }
}
#else
import SwiftUI

extension View {
    /// No-op on iOS — scroll-wheel events are macOS-only.
    func onScrollWheel(
        onRightClick: (() -> Void)? = nil,
        _ handler: @escaping (_ deltaX: CGFloat, _ deltaY: CGFloat) -> Void
    ) -> some View {
        self
    }
}
#endif
