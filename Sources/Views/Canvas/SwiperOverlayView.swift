import SwiftUI

/// Draggable handle for the wipe-reveal comparison mode.
/// Shows a thin white divider line and a compact pill at the bottom.
/// Hit area is limited to the pill and a thin vertical strip so canvas gestures work elsewhere.
/// Accounts for canvas zoom and pan so the pill always aligns with the actual image divider.
struct SwiperOverlayView: View {
    @Binding var swiperPosition: Double
    let containerWidth: CGFloat
    var showDividerLine: Bool = true
    var lineColor: Color = .white
    var lineThickness: Double = 1.0
    var canvasZoom: Double = 1.0
    var canvasPanX: Double = 0.0

    @State private var isDragging = false

    private let handleWidth: CGFloat = 36
    private let hitStripWidth: CGFloat = 24

    /// Convert logical swiper position (0-1) to screen X, accounting for zoom + pan.
    /// scaleEffect scales from center, so: screenX = (pos - 0.5) * width * zoom + width/2 + panX
    private var screenX: CGFloat {
        (swiperPosition - 0.5) * containerWidth * canvasZoom + containerWidth / 2.0 + canvasPanX
    }

    /// Convert a screen X coordinate back to logical swiper position (0-1).
    private func screenToPosition(_ x: CGFloat) -> Double {
        let pos = (x - containerWidth / 2.0 - canvasPanX) / (containerWidth * canvasZoom) + 0.5
        return max(0.005, min(0.995, pos))
    }

    var body: some View {
        let xOff = screenX

        ZStack(alignment: .leading) {
            // Thin white divider line
            if showDividerLine {
                Rectangle()
                    .fill(lineColor.opacity(0.8))
                    .frame(width: lineThickness)
                    .offset(x: xOff - lineThickness / 2)
                    .allowsHitTesting(false)
            }

            // Invisible thin hit strip along the divider
            Color.clear
                .frame(width: hitStripWidth)
                .contentShape(Rectangle())
                .offset(x: xOff - hitStripWidth / 2)

            // Pill handle pinned near the bottom
            handle
                .offset(x: xOff - handleWidth / 2)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Only the pill and strip are hittable — NOT the full view
        .contentShape(.rect.subtracting(.rect))
        .overlay {
            gestureOverlay(xOffset: xOff)
        }
    }

    /// The actual gesture target — only covers the thin strip area
    @ViewBuilder
    private func gestureOverlay(xOffset: CGFloat) -> some View {
        Color.clear
            .frame(width: hitStripWidth)
            .contentShape(Rectangle())
            .offset(x: xOffset - hitStripWidth / 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        swiperPosition = screenToPosition(value.location.x)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            #if os(macOS)
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    NSCursor.resizeLeftRight.set()
                case .ended:
                    NSCursor.arrow.set()
                }
            }
            #endif
    }

    @ViewBuilder
    private var handle: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
                .font(.system(size: 9, weight: .bold))
            Rectangle()
                .frame(width: 1, height: 16)
                .opacity(0.3)
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.black.opacity(0.55))
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.2), value: isDragging)
    }
}
