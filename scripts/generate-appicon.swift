#!/usr/bin/env swift
import AppKit

let size = 1024
let image = NSImage(size: NSSize(width: CGFloat(size), height: CGFloat(size)))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))
NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.15, alpha: 1).setFill()
rect.fill()

// Draw a stylized metronome body
let margin: CGFloat = 140
let path = NSBezierPath()
let bottomY: CGFloat = 160
let topY: CGFloat = CGFloat(size) - margin
let midX: CGFloat = CGFloat(size) / 2
let halfWidth: CGFloat = 260

path.move(to: NSPoint(x: midX - halfWidth, y: bottomY))
path.line(to: NSPoint(x: midX, y: topY))
path.line(to: NSPoint(x: midX + halfWidth, y: bottomY))
path.close()

NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.75, alpha: 1).setFill()
path.fill()

// Inner face
let inner = NSBezierPath()
inner.move(to: NSPoint(x: midX - halfWidth + 40, y: bottomY + 40))
inner.line(to: NSPoint(x: midX, y: topY - 40))
inner.line(to: NSPoint(x: midX + halfWidth - 40, y: bottomY + 40))
inner.close()
NSColor(calibratedWhite: 1.0, alpha: 0.12).setFill()
inner.fill()

// Pendulum arm
let arm = NSBezierPath()
let armTop = NSPoint(x: midX + 140, y: topY - 120)
let armBottom = NSPoint(x: midX - 80, y: bottomY + 200)
arm.move(to: armBottom)
arm.line(to: armTop)
arm.lineWidth = 28
NSColor.white.setStroke()
arm.stroke()

// Weight
let weightRect = NSRect(x: armTop.x - 36, y: armTop.y - 36, width: 72, height: 72)
let weightPath = NSBezierPath(roundedRect: weightRect, xRadius: 12, yRadius: 12)
NSColor(calibratedRed: 0.95, green: 0.75, blue: 0.20, alpha: 1).setFill()
weightPath.fill()

// Title subtle glyph
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 120, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.10),
    .paragraphStyle: paragraph
]
let title = NSString(string: "GA")
title.draw(in: NSRect(x: 0, y: 40, width: size, height: 200), withAttributes: attrs)

image.unlockFocus()

func writePNG(_ img: NSImage, url: URL) {
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to encode PNG\n", stderr)
        exit(1)
    }
    try! data.write(to: url)
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath + "/macos/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png")
writePNG(image, url: out)
print("Wrote \(out.path)")
