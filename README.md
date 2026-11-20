# HomeView Preview

HomeView Preview is a macOS simulator for trying out smart-home controls on a small touch display. The dashboard and room interactions are built in SwiftUI.

## Why I'm building it

I want to test how quickly someone can find and control the right device in a room. Seeing a lamp where it sits makes it easier to recognize than remembering a device name like “Bedroom Light 2.”

## What works today

- An interactive dashboard with a clock, thermostat, door lock, intercom, and Good Night scene. The device controls use simulated state.
- An edge-to-edge bedroom photo with two clickable lights. Switch the hanging light or desk lamp individually, or use the bulb button to switch both. Four prepared images show the lighting combinations.
- A widget library for adding and repositioning widgets.

## Demo

[Watch the HomeView demo](Demo/homeview-demo.mp4). It shows the dashboard, opens the Bedroom, switches each light, and returns to the dashboard.

To run it locally, open `Package.swift` in Xcode, select **HomeViewPreview** and **My Mac**, and press **⌘R**. The package targets macOS 15 or later and uses Swift 6 tooling.

## Proposed

- Import a room photo, suggest the fixtures it contains, and let the user confirm their placement and prepare lighting previews.
- Import a LiDAR scan to build a floor-by-floor map with direct fixture controls.
- Give developers a reusable SDK for adding their own rooms, devices, and scenes.
