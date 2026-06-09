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

## Usage

### Modes

ImageLayerWiper has two modes:

- 🔵 **View Mode** (default) — Navigate and zoom the canvas
- 🔴 **Edit Mode** — Manipulate individual image layers

Toggle between them by **right-clicking** anywhere on the canvas, or clicking the **Edit** button in the toolbar.

### Mouse & Trackpad Controls

| Action | View Mode | Edit Mode |
|---|---|---|
| **Click** on image | Select layer (Image 1 or 2) | Select layer |
| **Drag** | Pan the entire canvas | Move the active layer |
| **Scroll wheel ↕** (vertical) | Zoom canvas in/out | Scale the active layer |
| **Scroll wheel ↔** (horizontal) | Adjust active layer opacity | Rotate the active layer |
| **Right-click** | Toggle View ↔ Edit mode | Toggle View ↔ Edit mode |
| **Pinch** (trackpad) | Zoom canvas | — |
| **Rotate** (two-finger twist) | — | Rotate active layer |

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘Z` | Undo |
| `⌘⇧Z` | Redo |

### Swiper Pill & Divider Line

Drag the **pill** at the bottom of the canvas to control the wipe-reveal position. The vertical **divider line** follows the pill.

> 💡 **Tip:** Customize the divider line's color and thickness by clicking the **▼** chevron next to the Line button in the toolbar.

### Loading Images

**Drag & drop** image files onto the canvas. Drop one image to load it into the active slot, or drop two images at once to load both. Use the **Swap** button to switch Image 1 and Image 2.

### Toolbar

| Button | Function |
|---|---|
| **Edit** | Toggle edit mode on/off |
| **Line ▼** | Toggle divider line / open color & thickness settings |
| **↩ ↪** | Undo / Redo |
| **Swap** | Swap Image 1 ↔ Image 2 |
| **Save** | Save current session |
| **Export** | Export composite as PNG, JPEG, or TIFF |

### Inspector Panels (Left & Right Sidebars)

| Section | Controls |
|---|---|
| **Transform** | Scale, rotation, offset, flip, opacity |
| **Adjustments** | Brightness, contrast, saturation, exposure, highlights, shadows, sharpness, blur, vibrance, temperature, hue |
| **3D Perspective** | X/Y/Z rotation with adjustable depth |

> 📄 A printable **[Quick Start Guide (PDF)](https://github.com/ncnoman/imagelayerwiper/releases/latest/download/ImageLayerWiper_QuickStart.pdf)** is also available in Releases.

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

---

## 💜 Support This Project

If ImageLayerWiper is useful to you, consider supporting development:

[![Sponsor on GitHub](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github)](https://github.com/sponsors/ncnoman)

Even a ⭐ on the repo helps! Thank you 🙏
