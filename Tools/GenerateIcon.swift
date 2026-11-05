// Purpose: Draw the original Clippit icon and generate every macOS AppIcon PNG size.
import AppKit

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: red, green: green, blue: blue, alpha: alpha)
}

func roundRect(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawIcon(pixels: Int, to url: URL) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let context = NSGraphicsContext.current!.cgContext
    context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    context.clear(CGRect(x: 0, y: 0, width: 1024, height: 1024))

    let tile = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 192, yRadius: 192)
    NSGradient(starting: color(0.16, 0.23, 0.40), ending: color(0.055, 0.09, 0.18))!.draw(in: tile, angle: -75)
    color(1, 1, 1, 0.12).setStroke()
    tile.lineWidth = 3
    tile.stroke()

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0, 0, 0, 0.32)
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.shadowBlurRadius = 24
    shadow.set()
    roundRect(NSRect(x: 268, y: 194, width: 488, height: 612), radius: 64, fill: color(0.95, 0.98, 1))
    NSGraphicsContext.restoreGraphicsState()

    roundRect(NSRect(x: 396, y: 756, width: 232, height: 100), radius: 30, fill: color(0.22, 0.83, 0.72))
    roundRect(NSRect(x: 451, y: 797, width: 122, height: 15), radius: 7.5, fill: color(0.06, 0.31, 0.34))

    let vault = NSBezierPath(ovalIn: NSRect(x: 374, y: 401, width: 276, height: 276))
    NSGradient(starting: color(0.20, 0.78, 0.69), ending: color(0.08, 0.54, 0.55))!.draw(in: vault, angle: -90)
    color(0.75, 0.97, 0.92).setStroke()
    vault.lineWidth = 10
    vault.stroke()
    color(0.07, 0.19, 0.28).setFill()
    NSBezierPath(ovalIn: NSRect(x: 480, y: 540, width: 64, height: 64)).fill()
    let keyhole = NSBezierPath()
    keyhole.move(to: NSPoint(x: 499, y: 552))
    keyhole.line(to: NSPoint(x: 525, y: 552))
    keyhole.line(to: NSPoint(x: 540, y: 481))
    keyhole.line(to: NSPoint(x: 484, y: 481))
    keyhole.close()
    keyhole.fill()
    roundRect(NSRect(x: 365, y: 311, width: 294, height: 20), radius: 10, fill: color(0.69, 0.76, 0.83))
    roundRect(NSRect(x: 365, y: 265, width: 198, height: 20), radius: 10, fill: color(0.79, 0.84, 0.89))
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: url, options: .atomic)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Clippit/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let iconset = root.appendingPathComponent(".build/Clippit.iconset", isDirectory: true)
let artwork = root.appendingPathComponent("Artwork", isDirectory: true)
for directory in [assets, iconset, artwork] {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
}
var entries: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try drawIcon(pixels: size * scale, to: assets.appendingPathComponent(name))
        try Data(contentsOf: assets.appendingPathComponent(name)).write(to: iconset.appendingPathComponent(name))
        entries.append(["idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": name])
    }
}
let info: [String: Any] = ["author": "Clippit", "version": 1]
try JSONSerialization.data(withJSONObject: ["images": entries, "info": info], options: [.prettyPrinted, .sortedKeys])
    .write(to: assets.appendingPathComponent("Contents.json"))
try JSONSerialization.data(withJSONObject: ["info": info], options: [.prettyPrinted, .sortedKeys])
    .write(to: assets.deletingLastPathComponent().appendingPathComponent("Contents.json"))
try drawIcon(pixels: 1024, to: artwork.appendingPathComponent("Clippit-1024.png"))
print("Generated all ten macOS app-icon representations.")
