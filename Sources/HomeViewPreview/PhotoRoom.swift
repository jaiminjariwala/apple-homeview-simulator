import ImageIO
import CoreImage
import SwiftUI

enum PhotoRoomKind {
    case bedroomTwo, bathroomOne, kitchen, livingRoom

    var name: String {
        switch self {
        case .bedroomTwo: "Bedroom 2"
        case .bathroomOne: "Bathroom 1"
        case .kitchen: "Kitchen"
        case .livingRoom: "Living Room"
        }
    }

    var resource: String {
        switch self {
        case .bedroomTwo: "BedroomTwo"
        case .bathroomOne: "BathroomOne"
        case .kitchen: "Kitchen"
        case .livingRoom: "LivingRoom"
        }
    }
    var visibleWidth: CGFloat { self == .bedroomTwo ? 0.80 : 1 }

    var groups: [RoomLightGroup] {
        switch self {
        case .bedroomTwo: [.init("Ceiling", 0..<1), .init("Lamps", 1..<4)]
        case .bathroomOne: [.init("Ceiling", 0..<1), .init("Vanity", 1..<3)]
        case .kitchen: [.init("Pendants", 0..<2), .init("Recessed", 2..<3), .init("Lamp", 3..<4)]
        case .livingRoom: [.init("Sconce", 0..<1), .init("Lamps", 1..<3), .init("Recessed", 3..<4)]
        }
    }

    var fixtures: [(name: String, x: CGFloat, y: CGFloat)] {
        switch self {
        case .bedroomTwo:
            [("Ceiling light", 0.45, 0.10), ("Left bedside lamp", 0.03, 0.43),
             ("Right bedside lamp", 0.23, 0.33), ("Dresser lamp", 0.75, 0.34)]
        case .bathroomOne:
            [("Ceiling light", 0.352, 0.089), ("Left vanity sconce", 0.682, 0.336),
             ("Right vanity sconce", 0.945, 0.243)]
        case .kitchen:
            [("Left pendant", 0.204, 0.273), ("Right pendant", 0.369, 0.232),
             ("Recessed lights", 0.775, 0.027), ("Counter lamp", 0.359, 0.458)]
        case .livingRoom:
            [("Wall sconce", 0.428, 0.267), ("Reading lamp", 0.531, 0.365),
             ("Table lamp", 0.905, 0.446), ("Recessed lights", 0.852, 0.062)]
        }
    }
}

struct PhotoRoom: View {
    let kind: PhotoRoomKind
    @ObservedObject var room: RoomLights
    let onBack: () -> Void

    @State private var displayedPhoto: NSImage?

    var body: some View {
        GeometryReader { proxy in
            // Bedroom 2 crops the right edge past the dresser. The other
            // rooms use square crops that retain every fixture.
            let photoSize = CGSize(width: proxy.size.width / kind.visibleWidth, height: proxy.size.height)
            if let image = displayedPhoto {
                ZStack {
                    Image(nsImage: image).resizable().accessibilityHidden(true)
                    ForEach(Array(kind.fixtures.enumerated()), id: \.offset) { index, fixture in
                        Button {
                            room.lights[index].toggle()
                        } label: {
                            Circle().fill(.black.opacity(0.18))
                                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                                .overlay {
                                    if room.lights[index] {
                                        Circle().fill(Color(red: 1, green: 0.87, blue: 0.57))
                                            .frame(width: 5, height: 5)
                                    }
                                }
                                .frame(width: 15, height: 15)
                                .frame(width: 44, height: 44)
                                .contentShape(.interaction, Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(fixture.name)
                        .accessibilityValue(room.lights[index] ? "On" : "Off")
                        .help(fixture.name)
                        .position(x: min(proxy.size.width - 22, max(22, fixture.x * photoSize.width)),
                                  y: max(22, fixture.y * photoSize.height))
                    }
                }
                .frame(width: photoSize.width, height: photoSize.height)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            }
        }
        .background(.black)
        .clipped()
        .overlay(alignment: .topLeading) {
            RoomBackButton(label: "Back to dashboard", action: onBack).padding(34)
        }
        .overlay(alignment: .bottomTrailing) {
            RoomLightControls(room: room, groups: kind.groups).padding(34)
        }
        .onChange(of: room.lights, initial: true) { _, lights in
            displayedPhoto = PhotoRoomImages.images(for: kind)?.image(lights: lights)
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

}

private final class PhotoRoomImages {
    private static let bedroomTwo = PhotoRoomImages(kind: .bedroomTwo)
    private static let bathroomOne = PhotoRoomImages(kind: .bathroomOne)
    private static let kitchen = PhotoRoomImages(kind: .kitchen)
    private static let livingRoom = PhotoRoomImages(kind: .livingRoom)

    static func images(for kind: PhotoRoomKind) -> PhotoRoomImages? {
        switch kind {
        case .bedroomTwo: bedroomTwo
        case .bathroomOne: bathroomOne
        case .kitchen: kitchen
        case .livingRoom: livingRoom
        }
    }

    private let kind: PhotoRoomKind
    private let size: CGSize
    private let onPhoto: NSImage
    private let offPhoto: NSImage
    private let on: CIImage
    private let off: CIImage
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!
    ])
    private lazy var masks = Self.makeMasks(for: kind, extent: on.extent)

    private init?(kind: PhotoRoomKind) {
        self.kind = kind
        func load(_ state: String) -> CGImage? {
            guard let url = Bundle.module.url(forResource: kind.resource + state,
                                              withExtension: "webp", subdirectory: "Resources"),
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            return CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
        guard let full = load("On"), let ambient = load("Off") else { return nil }
        size = CGSize(width: full.width, height: full.height)
        onPhoto = NSImage(cgImage: full, size: size)
        offPhoto = NSImage(cgImage: ambient, size: size)
        on = CIImage(cgImage: full)
        off = CIImage(cgImage: ambient).transformed(by: CGAffineTransform(
            scaleX: size.width / CGFloat(ambient.width), y: size.height / CGFloat(ambient.height)
        ))
    }

    func image(lights: [Bool]) -> NSImage {
        let enabled = lights.indices.filter { lights[$0] }
        let indices: [Int]
        let foreground: CIImage
        let background: CIImage
        switch kind {
        case .bedroomTwo:
            if enabled.count == lights.count { return onPhoto }
            if enabled.isEmpty { return offPhoto }
            (indices, foreground, background) = (enabled, on, off)
        case .bathroomOne:
            // The source photo was taken with the electrical lights off.
            if enabled.isEmpty { return offPhoto }
            (indices, foreground, background) = (enabled, on, off)
        case .kitchen, .livingRoom:
            if enabled.count == lights.count { return onPhoto }
            (indices, foreground, background) = (lights.indices.filter { !lights[$0] }, off, on)
        }

        let mask = indices.dropFirst().reduce(masks[indices[0]]) { sum, index in
            masks[index].applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: sum])
        }
        let blended = foreground.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: mask
        ])
        guard let result = context.createCGImage(blended, from: on.extent, format: .RGBA8, colorSpace: colorSpace)
        else { return offPhoto }
        return NSImage(cgImage: result, size: size)
    }

    private struct Spill {
        let x: Double, y: Double, width: Double, height: Double, gain: Double

        init(_ x: Double, _ y: Double, _ width: Double, _ height: Double, _ gain: Double) {
            (self.x, self.y, self.width, self.height, self.gain) = (x, y, width, height, gain)
        }

        func weight(x: Double, y: Double) -> Double {
            let dx = (x - self.x) / width
            let dy = (y - self.y) / height
            return gain * exp(-0.5 * (dx * dx + dy * dy))
        }
    }

    private static func makeMasks(for kind: PhotoRoomKind, extent: CGRect) -> [CIImage] {
        let spills: [[Spill]] = [
            [.init(0.449, 0.086, 0.067, 0.064, 7), .init(0.449, 0.045, 0.073, 0.035, 5.5), .init(0.54, 0.55, 0.30, 0.40, 1.1)],
            [.init(0.033, 0.423, 0.037, 0.048, 9), .init(0.062, 0.484, 0.13, 0.18, 2.2)],
            [.init(0.229, 0.333, 0.034, 0.037, 10), .init(0.216, 0.215, 0.067, 0.112, 6.1), .init(0.237, 0.461, 0.14, 0.17, 2)],
            [.init(0.752, 0.346, 0.044, 0.043, 10), .init(0.747, 0.159, 0.112, 0.10, 6), .init(0.80, 0.454, 0.13, 0.16, 2)]
        ]
        // Keep daylight and the unaffected parts of each source photo.
        // The left bathroom sconce also controls its reflection in the mirror.
        let bathroomAreas: [[Spill]] = [
            [.init(0.352, 0.089, 0.105, 0.096, 1.50)],
            [.init(0.682, 0.336, 0.055, 0.112, 1.45), .init(0.759, 0.337, 0.022, 0.042, 1.10)],
            [.init(0.947, 0.243, 0.092, 0.144, 1.48)]
        ]
        let kitchenAreas: [[Spill]] = [
            [.init(0.204, 0.263, 0.057, 0.059, 1.63)],
            [.init(0.369, 0.222, 0.070, 0.069, 1.63)],
            [.init(0.246, 0.117, 0.050, 0.039, 1.5), .init(0.775, 0.027, 0.062, 0.031, 1.5)],
            [.init(0.359, 0.455, 0.087, 0.048, 1.60)]
        ]
        let livingRoomAreas: [[Spill]] = [
            [.init(0.428, 0.276, 0.056, 0.069, 1.62)],
            [.init(0.531, 0.365, 0.047, 0.052, 1.59)],
            [.init(0.905, 0.445, 0.081, 0.089, 1.59)],
            [.init(0.531, 0.084, 0.055, 0.044, 1.54), .init(0.852, 0.062, 0.062, 0.042, 1.54)]
        ]
        let localAreas: [[Spill]]
        switch kind {
        case .bedroomTwo: localAreas = []
        case .bathroomOne: localAreas = bathroomAreas
        case .kitchen: localAreas = kitchenAreas
        case .livingRoom: localAreas = livingRoomAreas
        }
        func lobe(_ offset: Double, radius: Double) -> Double {
            let t = offset / radius
            let weight = max(0, 1 - t * t)
            return weight * weight
        }

        // The masks contain weights, so Core Image reads them without a color profile.
        let width = 240
        let height = Int((extent.height * CGFloat(width) / extent.width).rounded())
        var channels = kind.fixtures.map { _ in [Float](repeating: 0, count: width * height) }
        for row in 0..<height {
            let y = (Double(row) + 0.5) / Double(height)
            for column in 0..<width {
                let x = (Double(column) + 0.5) / Double(width)
                let pixel = row * width + column
                switch kind {
                case .bedroomTwo:
                    let weights = spills.map { areas in
                        areas.reduce(0.035) { $0 + $1.weight(x: x, y: y) }
                    }
                    let total = weights.reduce(0, +)
                    for index in channels.indices {
                        channels[index][pixel] = Float(weights[index] / total)
                    }
                case .bathroomOne, .kitchen, .livingRoom:
                    for (index, areas) in localAreas.enumerated() {
                        let weight = areas.reduce(0.0) { sum, area in
                            sum + area.gain * lobe(x - area.x, radius: 2 * area.width)
                                * lobe(y - area.y, radius: 1.7 * area.height)
                        }
                        channels[index][pixel] = Float(min(1, weight))
                    }
                }
            }
        }
        return channels.map { weights in
            let pixels = weights.withUnsafeBufferPointer { Data(buffer: $0) }
            return CIImage(bitmapData: pixels, bytesPerRow: width * MemoryLayout<Float>.size,
                           size: CGSize(width: width, height: height), format: .Rf, colorSpace: nil)
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                    "inputBVector": CIVector(x: 1, y: 0, z: 0, w: 0)
                ])
                .clampedToExtent()
                .transformed(by: CGAffineTransform(scaleX: extent.width / CGFloat(width),
                                                  y: extent.height / CGFloat(height)))
                .cropped(to: extent)
        }
    }
}
