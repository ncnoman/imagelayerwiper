import SwiftUI

/// Renders a single image with all 2D transforms, 3D perspective, and filter effects applied.
struct ImageLayerView: View {
    let image: PlatformImage
    let layer: ImageLayer
    let containerSize: CGSize

    var body: some View {
        Image(platformImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            // 2D Transforms
            .scaleEffect(
                x: (layer.flipH ? -1 : 1) * layer.scale,
                y: (layer.flipV ? -1 : 1) * layer.scale
            )
            .rotationEffect(.degrees(layer.rotation))
            .offset(x: layer.offsetX, y: layer.offsetY)
            // 3D Perspective
            .rotation3DEffect(
                .degrees(layer.perspectiveX),
                axis: (x: 1, y: 0, z: 0),
                perspective: layer.perspectiveStrength
            )
            .rotation3DEffect(
                .degrees(layer.perspectiveY),
                axis: (x: 0, y: 1, z: 0),
                perspective: layer.perspectiveStrength
            )
            .rotation3DEffect(
                .degrees(layer.perspectiveZ),
                axis: (x: 0, y: 0, z: 1),
                perspective: layer.perspectiveStrength
            )
            // Per-layer opacity
            .opacity(layer.opacity)
    }
}
