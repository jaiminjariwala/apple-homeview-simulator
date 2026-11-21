import SwiftUI

@main
struct HomeViewPreviewApp: App {
    private enum Screen { case dashboard, bedroom, bedroomTwo, bathroomOne, kitchen, livingRoom }

    @State private var screen: Screen = .dashboard
    @State private var dashboardPage: Int? = 0
    @StateObject private var room = RoomLights()
    @StateObject private var bedroomTwo = RoomLights(count: PhotoRoomKind.bedroomTwo.fixtures.count)
    @StateObject private var bathroomOne = RoomLights(count: PhotoRoomKind.bathroomOne.fixtures.count, initiallyOn: false)
    @StateObject private var kitchen = RoomLights(count: PhotoRoomKind.kitchen.fixtures.count)
    @StateObject private var livingRoom = RoomLights(count: PhotoRoomKind.livingRoom.fixtures.count)

    var body: some Scene {
        WindowGroup {
            FixedHomeView {
                ZStack {
                    WidgetCanvas(room: room, bedroomTwo: bedroomTwo, bathroomOne: bathroomOne, kitchen: kitchen,
                                 livingRoom: livingRoom,
                                 page: $dashboardPage,
                                 openRoom: { screen = .bedroom }, openBedroomTwo: { screen = .bedroomTwo },
                                 openBathroomOne: { screen = .bathroomOne }, openKitchen: { screen = .kitchen },
                                 openLivingRoom: { screen = .livingRoom })
                        .opacity(screen == .dashboard ? 1 : 0)
                        .allowsHitTesting(screen == .dashboard)
                        .accessibilityHidden(screen != .dashboard)
                    switch screen {
                    case .dashboard:
                        EmptyView()
                    case .bedroom:
                        RoomPrototype(room: room) { screen = .dashboard }
                    case .bedroomTwo:
                        PhotoRoom(kind: .bedroomTwo, room: bedroomTwo) { screen = .dashboard }
                    case .bathroomOne:
                        PhotoRoom(kind: .bathroomOne, room: bathroomOne) { screen = .dashboard }
                    case .kitchen:
                        PhotoRoom(kind: .kitchen, room: kitchen) { screen = .dashboard }
                    case .livingRoom:
                        PhotoRoom(kind: .livingRoom, room: livingRoom) { screen = .dashboard }
                    }
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
                Button("Bedroom") { dashboardPage = 0; screen = .bedroom }.keyboardShortcut("5")
                Button("Bedroom 2") { dashboardPage = 1; screen = .bedroomTwo }.keyboardShortcut("6")
                Button("Bathroom 1") { dashboardPage = 1; screen = .bathroomOne }.keyboardShortcut("7")
                Button("Kitchen") { dashboardPage = 1; screen = .kitchen }.keyboardShortcut("8")
                Button("Living Room") { dashboardPage = 1; screen = .livingRoom }.keyboardShortcut("9")
                Button("Dashboard") { screen = .dashboard }.keyboardShortcut("1")
            }
        }
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
    private let referenceSize = CGSize(width: 946, height: 1042)
    private let displayFrame = CGRect(x: 157, y: 116, width: 664, height: 664)
    private static var reference: NSImage? {
        Bundle.module.url(forResource: "HomeViewFront", withExtension: "png", subdirectory: "Resources")
            .flatMap(NSImage.init(contentsOf:))
    }

    private static var aperture: NSImage? {
        Bundle.module.url(forResource: "DisplayAperture", withExtension: "png", subdirectory: "Resources").flatMap(NSImage.init(contentsOf:))
    }

    var body: some View {
        GeometryReader { proxy in
            let fit = min(proxy.size.width / referenceSize.width, proxy.size.height / referenceSize.height)
            // The display and bezel share an axis that is right of the PNG's midpoint.
            let horizontalOffset = (referenceSize.width / 2 - displayFrame.midX) * fit
            ZStack(alignment: .topLeading) {
                if let reference = Self.reference {
                    Image(nsImage: reference).resizable()
                        .frame(width: referenceSize.width, height: referenceSize.height)
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
                    .scaleEffect(displayFrame.width / 544, anchor: .topLeading)
                    .offset(x: displayFrame.minX, y: displayFrame.minY)
            }
            .frame(width: referenceSize.width, height: referenceSize.height, alignment: .topLeading)
            .scaleEffect(fit)
            .position(x: proxy.size.width / 2 + horizontalOffset, y: proxy.size.height / 2)
        }
        .background(.white)
        .clipped()
    }
}
