# ImageLayerWiper

A native macOS & iOS image comparison app built with SwiftUI. Drop in two images and compare them side-by-side with a wipe-reveal slider, per-layer transforms, image adjustments, and full undo/redo.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![iOS 17+](https://img.shields.io/badge/iOS-17%2B-green) ![Swift](https://img.shields.io/badge/Swift-6-orange) ![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

- **Wipe-Reveal Comparison** — Drag the slider pill to reveal differences between two images
- **Drag & Drop** — Drop one or two images at once; supports all common formats
- **Per-Layer Transforms** — Scale, rotate, offset, and flip each image independently
- **Image Adjustments** — Brightness, contrast, saturation, exposure, highlights, shadows, sharpness, blur, vibrance, temperature, and hue rotation
- **3D Perspective** — Rotate images in 3D space (X/Y/Z axes with adjustable depth)
- **Layer Opacity** — Control each layer's opacity via scroll wheel or slider
- **Customizable Divider** — Toggle the divider line on/off, pick a color, adjust thickness
- **Undo/Redo** — Full undo history (⌘Z / ⌘⇧Z) with 50-entry stack
- **Edit Mode** — Toggle between view mode (pan/zoom canvas) and edit mode (manipulate layers)
- **Session Management** — Save and restore comparison sessions
- **Export** — Save composites as PNG, JPEG, or TIFF at 1x/2x/3x scale
- **Cross-Platform** — Runs on macOS 14+ and iOS 17+

## Controls

| Action | View Mode | Edit Mode |
|---|---|---|
| **Scroll wheel (vertical)** | Zoom canvas | Scale active layer |
| **Scroll wheel (horizontal)** | Active layer opacity | Rotate active layer |
| **Right-click** | Toggle edit mode | Toggle edit mode |
| **Click on image** | Select layer | Select layer |
| **Drag** | Pan canvas | Move active layer |
| **Pinch (trackpad)** | Zoom canvas | — |

## Install

### Download
Grab the latest DMG from [**Releases**](https://github.com/ncnoman/imagelayerwiper/releases).

### Build from Source
Requires Xcode or Swift toolchain on macOS 14+:

```bash
swift build -c release
bash package-app.sh    # → /Applications/ImageLayerWiper.app
bash create-dmg.sh     # → dist/ImageLayerWiper.dmg
```

## Project Structure

```
Sources/
├── ImageLayerWiperApp.swift        # App entry point + ⌘Z commands
├── Models/                         # ImageLayer, ImageAdjustments, Session
├── ViewModels/                     # CanvasViewModel, SessionStore
├── Views/
│   ├── Canvas/                     # ComparisonCanvasView, SwiperOverlay, ImageLayerView
│   ├── Controls/                   # Inspector panels, toolbar, adjustment sliders
│   ├── Export/                     # Export sheet
│   └── Sidebar/                   # Session sidebar
├── Services/                       # ImageFilterService (Core Image), ExportService
└── Utilities/                      # UndoHistory, PlatformTypes, Extensions
```

## License

MIT — free to use, modify, and distribute.

## Support

If you find this useful, consider [sponsoring](https://github.com/sponsors/ncnoman) the project.
