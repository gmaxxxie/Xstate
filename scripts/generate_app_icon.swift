#!/usr/bin/env swift

import AppKit
import Foundation

func drawIcon(size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    defer { image.unlockFocus() }

    let bounds = NSRect(origin: .zero, size: size)
    let cornerRadius = min(size.width, size.height) * 0.24
    let backgroundPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)

    let startColor = NSColor(calibratedRed: 0.16, green: 0.52, blue: 0.82, alpha: 1.0)
    let endColor = NSColor(calibratedRed: 0.10, green: 0.32, blue: 0.64, alpha: 1.0)

    if let gradient = NSGradient(starting: startColor, ending: endColor) {
        gradient.draw(in: backgroundPath, angle: -90)
    } else {
        startColor.setFill()
        backgroundPath.fill()
    }

    let inset = min(size.width, size.height) * 0.20
    let symbolRect = bounds.insetBy(dx: inset, dy: inset)
    let stroke = min(size.width, size.height) * 0.11

    let xPath = NSBezierPath()
    xPath.move(to: NSPoint(x: symbolRect.minX, y: symbolRect.minY))
    xPath.line(to: NSPoint(x: symbolRect.maxX, y: symbolRect.maxY))
    xPath.move(to: NSPoint(x: symbolRect.maxX, y: symbolRect.minY))
    xPath.line(to: NSPoint(x: symbolRect.minX, y: symbolRect.maxY))
    xPath.lineWidth = stroke
    xPath.lineCapStyle = .round
    xPath.lineJoinStyle = .round

    NSColor.white.withAlphaComponent(0.96).setStroke()
    xPath.stroke()

    let accentHeight = min(size.width, size.height) * 0.06
    let accentWidth = min(size.width, size.height) * 0.30
    let accentRect = NSRect(
        x: (size.width - accentWidth) / 2,
        y: min(size.width, size.height) * 0.12,
        width: accentWidth,
        height: accentHeight
    )
    let accentPath = NSBezierPath(roundedRect: accentRect, xRadius: accentHeight / 2, yRadius: accentHeight / 2)
    NSColor.white.withAlphaComponent(0.85).setFill()
    accentPath.fill()

    return image
}

func savePNG(image: NSImage, to outputPath: String) throws {
    let fileURL = URL(fileURLWithPath: outputPath)
    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
    }

    try pngData.write(to: fileURL)
}

let outputPath: String
if CommandLine.arguments.count >= 2 {
    outputPath = CommandLine.arguments[1]
} else {
    fputs("Usage: generate_app_icon.swift <output_png_path>\n", stderr)
    exit(2)
}

do {
    let image = drawIcon(size: CGSize(width: 1024, height: 1024))
    try savePNG(image: image, to: outputPath)
} catch {
    fputs("Error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
