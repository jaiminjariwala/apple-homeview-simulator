import SwiftUI
import Combine

final class RoomLights: ObservableObject {
    @Published var lights: [Bool]

    init(count: Int = 2, initiallyOn: Bool = true) {
        lights = Array(repeating: initiallyOn, count: count)
    }

    var count: Int { lights.filter { $0 }.count }
    func isOn(in fixtures: Range<Int>) -> Bool {
        lights[fixtures].contains(true)
    }

    func toggle(_ fixtures: Range<Int>) {
        let on = !isOn(in: fixtures)
        lights.replaceSubrange(fixtures, with: repeatElement(on, count: fixtures.count))
    }

    func toggleAll() { toggle(lights.indices) }
}

struct RoomPrototype: View {
    @ObservedObject var room: RoomLights
    var onBack: () -> Void

    private let controlInset: CGFloat = 34

    private static let photos: [NSImage?] = ["00", "01", "10", "11"].map { state in
        Bundle.module.url(forResource: "BedroomPhoto" + state, withExtension: "png", subdirectory: "Resources")
            .flatMap(NSImage.init(contentsOf:))
    }

    var body: some View {
        GeometryReader { proxy in
            // Keep the top of the portrait crop visible so both fixture controls
            // stay inside the square display.
            let width = max(proxy.size.width, proxy.size.height * 2 / 3)
            let height = width * 1.5
            ZStack(alignment: .topLeading) {
                photo
                    .frame(width: width, height: height)
                let photoSize = CGSize(width: width, height: height)
                fixture(0, name: "Hanging light",
                        bounds: CGRect(x: 0.56, y: 0, width: 0.23, height: 0.16),
                        indicator: CGPoint(x: 0.673, y: 0.096), photoSize: photoSize)
                fixture(1, name: "Desk lamp",
                        bounds: CGRect(x: 0.28, y: 0.36, width: 0.18, height: 0.17),
                        indicator: CGPoint(x: 0.367, y: 0.402), photoSize: photoSize)
            }
            .frame(width: width, height: height)
            .position(x: proxy.size.width / 2, y: height / 2)
        }
        .background(.black)
        .clipped()
        .overlay(alignment: .topLeading) {
            RoomBackButton(label: "Back to dashboard", action: onBack).padding(controlInset)
        }
        .overlay(alignment: .bottomTrailing) {
            RoomLightControls(room: room, groups: [.init("Ceiling", 0..<1), .init("Lamps", 1..<2)])
                .padding(controlInset)
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder private var photo: some View {
        let state = (room.lights[0] ? 2 : 0) + (room.lights[1] ? 1 : 0)
        if let image = Self.photos[state] ?? Self.photos[3] {
            Image(nsImage: image).resizable().accessibilityHidden(true)
        }
    }

    private func fixture(_ index: Int, name: String, bounds: CGRect,
                         indicator: CGPoint, photoSize: CGSize) -> some View {
        Button { room.lights[index].toggle() } label: {
            Color.clear
                .frame(width: bounds.width * photoSize.width, height: bounds.height * photoSize.height)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(.black.opacity(0.16))
                        .overlay { Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1.5) }
                        .overlay { Circle().fill(room.lights[index] ? .yellow : .white).frame(width: 5, height: 5) }
                        .frame(width: 17, height: 17)
                        .position(x: (indicator.x - bounds.minX) * photoSize.width,
                                  y: (indicator.y - bounds.minY) * photoSize.height)
                        .allowsHitTesting(false)
                }
                .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityValue(room.lights[index] ? "On" : "Off")
        .help(name)
        .position(x: bounds.midX * photoSize.width, y: bounds.midY * photoSize.height)
    }
}

struct RoomLightGroup: Identifiable {
    let name: String
    let fixtures: Range<Int>
    var id: String { name }

    init(_ name: String, _ fixtures: Range<Int>) {
        self.name = name
        self.fixtures = fixtures
    }
}

struct RoomLightControls: View {
    @ObservedObject var room: RoomLights
    let groups: [RoomLightGroup]

    var body: some View {
        HStack(spacing: 7) {
            ForEach(groups) { group in
                let on = room.isOn(in: group.fixtures)
                Button {
                    room.toggle(group.fixtures)
                } label: {
                    Text(group.name)
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 13)
                        .frame(height: 42)
                        .modifier(RoomGlass())
                        .contentShape(.interaction, Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityValue(on ? "On" : "Off")
                .help(on ? "Turn off \(group.name.lowercased())" : "Turn on \(group.name.lowercased())")
            }
            Button { room.toggleAll() } label: {
                Image(systemName: room.count == 0 ? "lightbulb" : "lightbulb.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .modifier(RoomGlass())
                    .contentShape(.interaction, Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(room.count == 0 ? "Turn all lights on" : "Turn all lights off")
            .accessibilityValue("\(room.count) of \(room.lights.count) on")
        }
    }
}

struct RoomGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content.background(.regularMaterial, in: Capsule())
        }
    }
}

struct RoomBackButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 42, height: 42)
                .modifier(RoomGlass())
                .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
        .accessibilityLabel(label)
    }
}
