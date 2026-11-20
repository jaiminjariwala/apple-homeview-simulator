# Apple HomeView Simulator

An independent macOS simulator for prototyping smart-home experiences on Apple HomeView, a compact home display. The simulator runs in SwiftUI and uses simulated device state.

## Why I'm building it

[Xcode offers simulators](https://developer.apple.com/documentation/xcode/building-and-running-an-app) for iPhone, iPad, Apple Watch, Apple TV, and Apple Vision Pro. HomeView doesn’t have a dedicated Xcode simulator. I’m building a place to try HomeView interactions with the same familiar edit, run, and test loop.

## For developers and designers

Open the Swift package in Xcode, edit a SwiftUI view, and run it on **My Mac** to try it inside the HomeView display. Use the dashboard and widget library to test layout, readable labels, and tap targets at device scale.

## For people using HomeView

Find a light by where it sits in the room. In the Bedroom demo, tap the hanging light or the desk lamp in the photo to switch it. The room updates to show the new lighting, and one button switches both lights.

## Demo

![HomeView simulator demo showing the dashboard, the two Bedroom lights toggling, and a return to the dashboard](Demo/homeview-demo.webp)

## What works today

- SwiftUI dashboard with a clock, simulated thermostat, door lock, intercom, and Good Night scene.
- Widget library for adding and repositioning controls.
- Bedroom photo with two independent light controls and four prepared lighting states.

## Proposed

- Import a room photo, suggest fixture locations, and generate lighting previews for review.
- Turn LiDAR scans into floor-by-floor home maps with controls at each fixture’s location.
- Package the simulator components as a reusable SDK for custom rooms, devices, and scenes.

## Run locally

Open `Package.swift` in Xcode, select **HomeViewPreview** and **My Mac**, and press **⌘R**. Requires macOS 15 or later and a Swift 6 toolchain.
