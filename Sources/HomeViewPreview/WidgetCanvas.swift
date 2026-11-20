import SwiftUI

enum CanvasWidget: String, CaseIterable, Identifiable {
    case thermostat = "Thermostat", clock = "Analog Clock", night = "Good Night", intercom = "Intercom", door = "Door Lock", bedroom = "Bedroom Lights"
    case lamp = "Floor Lamp", music = "Music"
    var id: Self { self }
    var size: CGSize {
        switch self {
        case .thermostat: CGSize(width: 344, height: 344)
        case .lamp, .music: CGSize(width: 202, height: 200)
        default: CGSize(width: 167, height: 167)
        }
    }
    var initial: CGPoint {
        switch self {
        case .thermostat: CGPoint(x: 184, y: 184)
        case .clock: CGPoint(x: 449, y: 95)
        case .night: CGPoint(x: 449, y: 272)
        case .intercom: CGPoint(x: 95, y: 449)
        case .door: CGPoint(x: 272, y: 449)
        case .bedroom: CGPoint(x: 449, y: 449)
        case .lamp: CGPoint(x: 162, y: 388)
        case .music: CGPoint(x: 382, y: 388)
        }
    }
}

final class CanvasLayout: ObservableObject {
    @Published var positions: [CanvasWidget: CGPoint] = Dictionary(uniqueKeysWithValues:
        CanvasWidget.allCases.filter { $0 != .lamp && $0 != .music }.map { ($0, $0.initial) })
    @Published var temperature = 68
    @Published var doorLocked = true
    @Published var intercomActive = false
    func place(_ kind: CanvasWidget, at point: CGPoint) {
        let x = kind.size.width / 2 + 11, y = kind.size.height / 2 + 11
        positions[kind] = CGPoint(x: min(544-x, max(x, point.x)), y: min(544-y, max(y, point.y)))
    }
}

struct WidgetLibrary: View {
    @ObservedObject var layout: CanvasLayout
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drag a widget onto the display").font(.headline)
            ForEach(CanvasWidget.allCases) { kind in
                HStack {
                    Text(kind.rawValue).frame(maxWidth: .infinity, alignment: .leading)
                    Button(layout.positions[kind] == nil ? "Add" : "Remove") {
                        if layout.positions[kind] == nil { layout.place(kind, at: kind.initial) }
                        else { layout.positions.removeValue(forKey: kind) }
                    }
                }
                .padding(8).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .draggable(kind.rawValue)
            }
        }.padding(18).frame(width: 275)
    }
}

struct WidgetCanvas: View {
    @ObservedObject var layout: CanvasLayout
    @ObservedObject var room: RoomLights
    let openRoom: () -> Void
    @Environment(\.openWindow) private var openWindow
    @State private var lampOn = false
    @State private var playing = false
    @State private var track = 0
    private let titles = ["First Light", "Evening Walk", "Soft Focus"]
    private static let wallpaper = Bundle.module.url(forResource: "FamilyWallpaper", withExtension: "png", subdirectory: "Resources").flatMap(NSImage.init(contentsOf:))

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let wallpaper = Self.wallpaper {
                Image(nsImage: wallpaper).resizable().scaledToFill().frame(width: 544,height: 544).clipped().accessibilityHidden(true)
            }
            Color.black.opacity(0.12).allowsHitTesting(false)
            ForEach(CanvasWidget.allCases) { kind in
                if let center = layout.positions[kind] {
                    Group {
                        if kind == .bedroom { widget(kind, at: center) }
                        else { widget(kind, at: center).draggable(kind.rawValue) }
                    }.frame(width: kind.size.width, height: kind.size.height).position(center)
                }
            }
        }
        .frame(width: 544,height: 544)
        .dropDestination(for: String.self) { items, point in
            guard let value = items.first, let kind = CanvasWidget(rawValue: value) else { return false }
            layout.place(kind, at: point)
            return true
        }
        .contextMenu { Button("Widget Library…") { openWindow(id: "widget-library") } }
    }

    @ViewBuilder private func widget(_ kind: CanvasWidget, at center: CGPoint) -> some View {
        let half = CGSize(width: kind.size.width / 2, height: kind.size.height / 2)
        // Keep the glass rim concentric with the aperture as tiles move around the canvas.
        let radius = { (horizontalInset: CGFloat, verticalInset: CGFloat) in
            max(32, 77 - max(horizontalInset, verticalInset))
        }
        let left = center.x - half.width, right = 544 - center.x - half.width
        let top = center.y - half.height, bottom = 544 - center.y - half.height
        let shape = UnevenRoundedRectangle(topLeadingRadius: radius(left, top),
                                           bottomLeadingRadius: radius(left, bottom),
                                           bottomTrailingRadius: radius(right, bottom),
                                           topTrailingRadius: radius(right, top), style: .continuous)
        switch kind {
        case .clock:
            AnalogDial().modifier(DashboardGlass(shape: Circle()))
        case .thermostat:
            ZStack(alignment: .bottom) {
                Text("\(layout.temperature)").font(.system(size: 145, weight: .medium))
                    .monospacedDigit().frame(maxWidth: .infinity, maxHeight: .infinity).offset(y: -19)
                HStack {
                    playerButton("chevron.down", "Lower temperature") { layout.temperature = max(50, layout.temperature - 1) }
                    Spacer()
                    tileLabel("Thermostat", "Living Room")
                    Spacer()
                    playerButton("chevron.up", "Raise temperature") { layout.temperature = min(90, layout.temperature + 1) }
                }.font(.title.bold()).padding(24)
            }.modifier(DashboardGlass(shape: shape))
        case .bedroom:
            Button(action: openRoom) {
                face(shape, room.count > 0 ? "lamp.ceiling.fill" : "lamp.ceiling", "Lights", "Bedroom")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open bedroom lights")
            .accessibilityValue("\(room.count) of 2 on")
        case .night:
            Button {
                room.lights = Array(repeating: false, count: room.lights.count)
                layout.doorLocked = true
            } label: { face(shape, "moon.stars.fill", "Good Night", "Scene") }.buttonStyle(.plain)
        case .door:
            Button { layout.doorLocked.toggle() } label: {
                face(shape, layout.doorLocked ? "lock.fill" : "lock.open.fill", "Door Lock", "Front Door")
            }.buttonStyle(.plain).accessibilityValue(layout.doorLocked ? "Locked" : "Unlocked")
        case .intercom:
            Button { layout.intercomActive.toggle() } label: {
                face(shape, "waveform", "Intercom", layout.intercomActive ? "Active" : "Everywhere")
            }.buttonStyle(.plain)
        case .lamp:
            Button { lampOn.toggle() } label: {
                VStack(alignment: .leading) {
                    Image(systemName: lampOn ? "lightbulb.fill" : "lightbulb")
                        .foregroundStyle(lampOn ? .yellow : .white).font(.title)
                    Spacer()
                    Text("Hallway").bold()
                    Text("Floor Lamp").foregroundStyle(.white.opacity(0.8))
                }.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .leading).padding(21)
            }.buttonStyle(.plain).accessibilityValue(lampOn ? "On" : "Off").modifier(WidgetGlass())
        case .music:
            VStack(alignment: .leading,spacing: 6) {
                Image(systemName: "music.note").font(.title2).frame(width: 50,height: 50)
                    .background(.purple.gradient,in: RoundedRectangle(cornerRadius: 12))
                Spacer()
                Text(titles[track]).bold()
                Text("Demo playlist").foregroundStyle(.white.opacity(0.8))
                HStack {
                    playerButton("backward.fill","Previous") { track = (track + titles.count - 1) % titles.count }
                    Spacer()
                    playerButton(playing ? "pause.fill" : "play.fill",playing ? "Pause" : "Play") { playing.toggle() }
                    Spacer()
                    playerButton("forward.fill","Next") { track = (track + 1) % titles.count }
                }
            }.padding(19).modifier(WidgetGlass())
        }
    }

    private func tileLabel(_ title: String, _ detail: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.system(size: 17, weight: .semibold))
            Text(detail).font(.system(size: 16)).foregroundStyle(.white.opacity(0.85))
        }
    }

    private func face(_ shape: UnevenRoundedRectangle, _ symbol: String, _ title: String, _ detail: String) -> some View {
        VStack(spacing: 0) {
            Image(systemName: symbol).font(.system(size: 44, weight: .medium))
                .frame(maxHeight: .infinity)
            tileLabel(title, detail).padding(.bottom, 24)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(DashboardGlass(shape: shape))
            .background(Color.clear)
            .contentShape(.interaction, Rectangle())
    }

    private func playerButton(_ icon: String,_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).frame(width: 30,height: 28) }
            .buttonStyle(.plain).accessibilityLabel(label)
    }
}

private struct WidgetGlass: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 35, style: .continuous)
        if #available(macOS 26, *) {
            content.foregroundStyle(.white).glassEffect(.regular.tint(.black.opacity(0.29)), in: shape)
        } else {
            content.foregroundStyle(.white).background(.thinMaterial,in: shape).environment(\.colorScheme,.dark)
        }
    }
}

private struct DashboardGlass<S: Shape>: ViewModifier {
    let shape: S
    init(shape: S) { self.shape = shape }

    @ViewBuilder func body(content: Content) -> some View {
        let face = content.foregroundStyle(.white).shadow(color: .black.opacity(0.35), radius: 1)
        if #available(macOS 26, *) {
            face.glassEffect(.clear.tint(.black.opacity(0.23)), in: shape)
        } else {
            face.background(.ultraThinMaterial, in: shape).environment(\.colorScheme, .dark)
        }
    }
}

private struct AnalogDial: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(center.x, center.y)
                func stroke(_ turn: Double, from start: Double, to end: Double, width: CGFloat) {
                    let angle = turn * 2 * Double.pi
                    func point(_ distance: Double) -> CGPoint {
                        CGPoint(x: center.x + sin(angle) * radius * distance,
                                y: center.y - cos(angle) * radius * distance)
                    }
                    var line = Path()
                    line.move(to: point(start))
                    line.addLine(to: point(end))
                    context.stroke(line, with: .color(.white), style: StrokeStyle(lineWidth: width, lineCap: .round))
                }
                for tick in 0..<12 { stroke(Double(tick)/12, from: 0.72, to: 0.90, width: 4.6) }
                let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: timeline.date)
                let seconds = Double(parts.second ?? 0) / 60
                let minutes = (Double(parts.minute ?? 0) + seconds) / 60
                let hours = (Double(parts.hour ?? 0) + minutes) / 12
                for (turn, length) in [(hours, 0.51), (minutes, 0.86)] {
                    stroke(turn, from: 0.03, to: 0.18, width: 2)
                    stroke(turn, from: 0.17, to: length, width: 6)
                }
                stroke(seconds, from: -0.15, to: 0.94, width: 1)
                let hub = Path(ellipseIn: CGRect(x: center.x-3, y: center.y-3, width: 6, height: 6))
                context.fill(hub, with: .color(.gray))
                context.stroke(hub, with: .color(.white), lineWidth: 1.6)
            }.accessibilityLabel(timeline.date.formatted(date: .omitted, time: .shortened))
        }
    }
}
