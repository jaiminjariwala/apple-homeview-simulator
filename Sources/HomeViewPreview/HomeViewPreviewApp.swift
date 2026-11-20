import SwiftUI

@main
struct HomeViewPreviewApp: App {
    @State private var showingBedroom = false
    @StateObject private var room = RoomLights()
    @StateObject private var layout = CanvasLayout()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            FixedHomeView {
                if showingBedroom {
                    RoomPrototype(room: room) { showingBedroom = false }
                } else {
                    WidgetCanvas(layout: layout, room: room) { showingBedroom = true }
                }
            }
            .frame(minWidth: 380, minHeight: 440)
            .background(.white)
            .background(WindowAppearance())
        }
        .defaultSize(width: 780, height: 860)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Prototype") {
                Button("Bedroom") { showingBedroom = true }.keyboardShortcut("5")
                Button("Dashboard") { showingBedroom = false }.keyboardShortcut("1")
                Button("Widget Library…") { openWindow(id: "widget-library") }
                    .keyboardShortcut("w", modifiers: [.command, .shift])
            }
        }
        Window("Widget Library", id: "widget-library") { WidgetLibrary(layout: layout) }
            .windowResizability(.contentSize)
    }
}

private struct WindowAppearance: NSViewRepresentable {
    final class Anchor: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.titlebarAppearsTransparent = true
            window?.backgroundColor = .white
            window?.titlebarSeparatorStyle = .none
        }
    }
    func makeNSView(context: Context) -> Anchor { Anchor() }
    func updateNSView(_ view: Anchor, context: Context) {}
}

private struct FixedHomeView<Screen: View>: View {
    @ViewBuilder var screen: () -> Screen

    // Coordinates in the front reference. A single transform keeps the screen,
    // its hit targets and the enclosure aligned across window sizes and zoom.
    private static var reference: NSImage? {
        Bundle.module.url(forResource: "HomeViewFront", withExtension: "png", subdirectory: "Resources")
            .flatMap(NSImage.init(contentsOf:))
    }

    private static var aperture: NSImage? {
        Bundle.module.url(forResource: "DisplayAperture", withExtension: "png", subdirectory: "Resources").flatMap(NSImage.init(contentsOf:))
    }

    var body: some View {
        GeometryReader { proxy in
            let fit = min(proxy.size.width / 946, proxy.size.height / 1042)
            ZStack(alignment: .topLeading) {
                if let reference = Self.reference {
                    Image(nsImage: reference).resizable()
                        .frame(width: 946, height: 1042)
                        .accessibilityHidden(true)
                }
                Group {
                    RoundedRectangle(cornerRadius: 87, style: .continuous)
                        .fill(.black).frame(width: 678, height: 678)
                        .offset(x: 150, y: 109).allowsHitTesting(false)
                }
                screen()
                    .frame(width: 544, height: 544)
                    .mask {
                        if let aperture = Self.aperture { Image(nsImage: aperture).resizable() }
                    }
                    .scaleEffect(664.0 / 544, anchor: .topLeading)
                    .offset(x: 157, y: 116)
            }
            .frame(width: 946, height: 1042, alignment: .topLeading)
            .scaleEffect(fit)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .background(.white)
        .clipped()
    }
}
