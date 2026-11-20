# HomeView Preview

A native macOS prototype that runs a SwiftUI dashboard and interactive bedroom lighting demo inside a HomeView-style device enclosure.

## Run in Xcode

Open `Package.swift`, select the **HomeViewPreview** scheme and **My Mac**, and press **⌘R**. The package targets macOS 15 or later and requires a Swift 6 toolchain.

1. Click **Lights · Bedroom** to open the bedroom.
2. Click the hanging light or the desk lamp to switch it independently. The bulb button in the lower-right corner switches both lights.
3. Click the back arrow or press **Esc** to return to the dashboard.

The bedroom uses a fixed, photo-based view with four lighting states. The demo controls simulate device state. The dashboard and bedroom share the same light state.

## Project layout

- `HomeViewPreviewApp.swift` defines the app and fits its interactive canvas to the device enclosure.
- `WidgetCanvas.swift` renders the dashboard and widget library.
- `RoomPrototype.swift` maps each fixture to a click area and selects the room image for the current lighting state.
