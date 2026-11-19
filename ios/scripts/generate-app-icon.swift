#!/usr/bin/swift
import AppKit
import CoreGraphics
import ImageIO

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmap = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let bounds = CGRect(x: 0, y: 0, width: size, height: size)
bitmap.setFillColor(NSColor(calibratedRed: 0.035, green: 0.045, blue: 0.04, alpha: 1).cgColor)
bitmap.fill(bounds)
let colors = [NSColor(calibratedRed: 0.30, green: 0.055, blue: 0.025, alpha: 1).cgColor, NSColor(calibratedRed: 0.035, green: 0.045, blue: 0.04, alpha: 1).cgColor] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
bitmap.drawRadialGradient(gradient, startCenter: CGPoint(x: 512, y: 512), startRadius: 40, endCenter: CGPoint(x: 512, y: 512), endRadius: 760, options: [])
func polygon(_ points: [CGPoint], fill: CGColor, stroke: CGColor? = nil, width: CGFloat = 1) {
    let path = CGMutablePath(); path.addLines(between: points); path.closeSubpath()
    bitmap.addPath(path); bitmap.setFillColor(fill); bitmap.drawPath(using: .fill)
    if let stroke { bitmap.addPath(path); bitmap.setStrokeColor(stroke); bitmap.setLineWidth(width); bitmap.strokePath() }
}
let olive = NSColor(calibratedRed: 0.24, green: 0.29, blue: 0.17, alpha: 1).cgColor
let dark = NSColor(calibratedRed: 0.055, green: 0.065, blue: 0.06, alpha: 1).cgColor
let edge = NSColor(calibratedWhite: 0.64, alpha: 1).cgColor
polygon([CGPoint(x:512,y:105),CGPoint(x:890,y:310),CGPoint(x:890,y:714),CGPoint(x:512,y:920),CGPoint(x:134,y:714),CGPoint(x:134,y:310)], fill: dark, stroke: edge, width: 13)
polygon([CGPoint(x:512,y:125),CGPoint(x:850,y:315),CGPoint(x:512,y:500),CGPoint(x:174,y:315)], fill: olive)
polygon([CGPoint(x:174,y:337),CGPoint(x:496,y:520),CGPoint(x:496,y:870),CGPoint(x:174,y:690)], fill: dark)
polygon([CGPoint(x:850,y:337),CGPoint(x:528,y:520),CGPoint(x:528,y:870),CGPoint(x:850,y:690)], fill: olive)
bitmap.setStrokeColor(edge); bitmap.setLineWidth(34); bitmap.strokeEllipse(in: CGRect(x:270,y:270,width:484,height:484))
bitmap.setStrokeColor(NSColor(calibratedWhite:0.88,alpha:1).cgColor); bitmap.setLineWidth(48)
for (a,b) in [(CGPoint(x:512,y:170),CGPoint(x:512,y:335)),(CGPoint(x:512,y:689),CGPoint(x:512,y:854)),(CGPoint(x:170,y:512),CGPoint(x:335,y:512)),(CGPoint(x:689,y:512),CGPoint(x:854,y:512))] {
    bitmap.move(to:a); bitmap.addLine(to:b); bitmap.strokePath()
}
bitmap.setFillColor(NSColor(calibratedRed:1,green:0.19,blue:0.035,alpha:1).cgColor)
bitmap.fillEllipse(in:CGRect(x:472,y:472,width:80,height:80))
let image = bitmap.makeImage()!
let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not write app icon") }
let catalog = output.deletingLastPathComponent()
let json = """
{
  "images" : [
    { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
try json.write(to: catalog.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Generated 1024x1024 AssaultCube iOS app icon at \(output.path)")
