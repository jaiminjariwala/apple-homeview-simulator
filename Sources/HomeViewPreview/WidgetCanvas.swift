import SwiftUI

enum CanvasWidget: String, CaseIterable, Identifiable {
    case thermostat = "Thermostat", clock = "Analog Clock", night = "Good Night"
    case intercom = "Intercom", door = "Door Lock", bedroom = "Bedroom Lights"
    case bedroomTwo = "Bedroom 2", bathroomOne = "Bathroom 1", kitchen = "Kitchen", livingRoom = "Living Room"

    var page: Int {
        switch self {
        case .bedroomTwo, .bathroomOne, .kitchen, .livingRoom: 1
        default: 0
        }
    }

    var id: Self { self }
    var size: CGSize {
        switch self {
        case .thermostat: CGSize(width: 344, height: 344)
        default: CGSize(width: 167, height: 167)
        }
    }
    var center: CGPoint {
        switch self {
        case .thermostat: CGPoint(x: 184, y: 184)
        case .clock: CGPoint(x: 449, y: 95)
        case .night: CGPoint(x: 449, y: 272)
        case .intercom: CGPoint(x: 95, y: 449)
        case .door: CGPoint(x: 272, y: 449)
        case .bedroom: CGPoint(x: 449, y: 449)
        case .bedroomTwo: CGPoint(x: 95, y: 95)
        case .bathroomOne: CGPoint(x: 272, y: 95)
        case .kitchen: CGPoint(x: 449, y: 95)
        case .livingRoom: CGPoint(x: 95, y: 272)
        }
    }
}

struct WidgetCanvas: View {
    @State private var temperature = 68
    @State private var doorLocked = true
    @State private var intercomActive = false

    @ObservedObject var room: RoomLights
    @ObservedObject var bedroomTwo: RoomLights
    @ObservedObject var bathroomOne: RoomLights
    @ObservedObject var kitchen: RoomLights
    @ObservedObject var livingRoom: RoomLights
    @Binding var page: Int?
    let openRoom: () -> Void
    let openBedroomTwo: () -> Void
    let openBathroomOne: () -> Void
    let openKitchen: () -> Void
    let openLivingRoom: () -> Void
    private static let wallpaper = Bundle.module.url(forResource: "FamilyWallpaper", withExtension: "png", subdirectory: "Resources").flatMap(NSImage.init(contentsOf:))

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let wallpaper = Self.wallpaper {
                Image(nsImage: wallpaper).resizable().scaledToFill().frame(width: 544,height: 544).clipped().accessibilityHidden(true)
            }
            Color.black.opacity(0.12).allowsHitTesting(false)
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    dashboardPage(0).id(0)
                    dashboardPage(1).id(1)
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $page)
            .simultaneousGesture(
                DragGesture(minimumDistance: 28).onEnded { gesture in
                    let delta = gesture.translation
                    guard abs(delta.width) > 1.5 * abs(delta.height) else { return }
                    goToPage(delta.width < 0 ? 1 : 0)
                }
            )
            HStack(spacing: 2) {
                pageButton(0)
                pageButton(1)
            }
            .position(x: 272, y: 537)
        }
        .frame(width: 544, height: 544)
    }

    private func dashboardPage(_ index: Int) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(CanvasWidget.allCases.filter { $0.page == index }) { kind in
                widget(kind)
                    .frame(width: kind.size.width, height: kind.size.height)
                    .position(kind.center)
            }
        }
        .frame(width: 544, height: 544)
    }

    private func roomLightTile(_ shape: UnevenRoundedRectangle, icon: String, title: String, detail: String,
                               roomName: String, lights: RoomLights, open: @escaping () -> Void) -> some View {
        let on = lights.count > 0
        return Button { lights.toggleAll() } label: {
            face(shape, on ? icon + ".fill" : icon, title, detail)
        }
        .buttonStyle(.plain)
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 1, maximumDistance: 12)
                .exclusively(before: TapGesture())
                .onEnded { result in
                    switch result {
                    case .first: open()
                    case .second: lights.toggleAll()
                    }
                }
        )
        .accessibilityLabel("\(roomName) lights")
        .accessibilityValue("\(lights.count) of \(lights.lights.count) on")
        .accessibilityAction(named: Text("Open \(roomName)")) { open() }
    }

    private func goToPage(_ index: Int) {
        withAnimation(.easeInOut(duration: 0.23)) { page = index }
    }

    private func pageButton(_ index: Int) -> some View {
        Button { goToPage(index) } label: {
            Circle()
                .fill(.white.opacity((page ?? 0) == index ? 1 : 0.45))
                .frame(width: 5, height: 5)
                .shadow(color: .black.opacity(0.45), radius: 1)
                .frame(width: 16, height: 14)
                .contentShape(.interaction, Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dashboard page \(index + 1) of 2")
        .accessibilityAddTraits((page ?? 0) == index ? .isSelected : [])
    }

    @ViewBuilder private func widget(_ kind: CanvasWidget) -> some View {
        let center = kind.center
        let half = CGSize(width: kind.size.width / 2, height: kind.size.height / 2)
        // Keep the glass rim concentric with the display aperture.
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
                Text("\(temperature)").font(.system(size: 145, weight: .medium))
                    .monospacedDigit().frame(maxWidth: .infinity, maxHeight: .infinity).offset(y: -19)
                HStack {
                    playerButton("chevron.down", "Lower temperature") { temperature = max(50, temperature - 1) }
                    Spacer()
                    tileLabel("Thermostat", "Living Room")
                    Spacer()
                    playerButton("chevron.up", "Raise temperature") { temperature = min(90, temperature + 1) }
                }.font(.title.bold()).padding(24)
            }.modifier(DashboardGlass(shape: shape))
        case .bedroom:
            roomLightTile(shape, icon: "lamp.ceiling", title: "Lights", detail: "Bedroom",
                          roomName: "Bedroom", lights: room, open: openRoom)
        case .bedroomTwo:
            roomLightTile(shape, icon: "lamp.ceiling", title: kind.rawValue, detail: "Lights",
                          roomName: kind.rawValue, lights: bedroomTwo, open: openBedroomTwo)
        case .bathroomOne:
            roomLightTile(shape, icon: "lightbulb.2", title: kind.rawValue, detail: "Lights",
                          roomName: kind.rawValue, lights: bathroomOne, open: openBathroomOne)
        case .kitchen:
            roomLightTile(shape, icon: "lamp.ceiling", title: kind.rawValue, detail: "Lights",
                          roomName: kind.rawValue, lights: kitchen, open: openKitchen)
        case .livingRoom:
            roomLightTile(shape, icon: "lamp.table", title: kind.rawValue, detail: "Lights",
                          roomName: kind.rawValue, lights: livingRoom, open: openLivingRoom)
        case .night:
            Button {
                room.lights = Array(repeating: false, count: room.lights.count)
                doorLocked = true
            } label: { face(shape, "moon.stars.fill", "Good Night", "Scene") }.buttonStyle(.plain)
        case .door:
            Button { doorLocked.toggle() } label: {
                face(shape, doorLocked ? "lock.fill" : "lock.open.fill", "Door Lock", "Front Door")
            }.buttonStyle(.plain).accessibilityValue(doorLocked ? "Locked" : "Unlocked")
        case .intercom:
            Button { intercomActive.toggle() } label: {
                face(shape, "waveform", "Intercom", intercomActive ? "Active" : "Everywhere")
            }.buttonStyle(.plain)

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
            .contentShape(.interaction, Rectangle())
    }

    private func playerButton(_ icon: String,_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).frame(width: 30,height: 28) }
            .buttonStyle(.plain).accessibilityLabel(label)
    }
}

private struct DashboardGlass<S: Shape>: ViewModifier {
    let shape: S

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
