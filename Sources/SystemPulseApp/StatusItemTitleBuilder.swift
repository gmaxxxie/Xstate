import AppKit
import MonitorCore

@MainActor
enum StatusItemTitleBuilder {
    private static let iconDesignSize: CGFloat = 12
    private static let iconSize = NSSize(width: 14, height: 14)
    private static let iconScale = min(iconSize.width, iconSize.height) / iconDesignSize

    static func build(
        cpuValue: String,
        memoryValue: String,
        cpuStatus: ResourceStatus,
        memoryStatus: ResourceStatus,
        mode: StatusItemDisplayMode
    ) -> NSAttributedString {
        if mode == .state {
            return prebuiltStateTitles[stateTitleKey(cpuStatus: cpuStatus, memoryStatus: memoryStatus)]!
        }

        let title = NSMutableAttributedString()
        title.append(iconAttachment(cpu: true, status: cpuStatus))

        title.append(NSAttributedString(string: " \(cpuValue)  "))
        title.append(iconAttachment(cpu: false, status: memoryStatus))
        title.append(NSAttributedString(string: " \(memoryValue)"))

        return title
    }

    private static let prebuiltStateTitles: [Int: NSAttributedString] = {
        var map: [Int: NSAttributedString] = [:]
        for cpuStatus in allStatuses {
            for memoryStatus in allStatuses {
                map[stateTitleKey(cpuStatus: cpuStatus, memoryStatus: memoryStatus)] = buildStateTitle(
                    cpuStatus: cpuStatus,
                    memoryStatus: memoryStatus
                )
            }
        }
        return map
    }()

    private static let allStatuses: [ResourceStatus] = [.normal, .warning, .critical]

    private static func buildStateTitle(
        cpuStatus: ResourceStatus,
        memoryStatus: ResourceStatus
    ) -> NSAttributedString {
        let title = NSMutableAttributedString()
        title.append(iconAttachment(cpu: true, status: cpuStatus))
        title.append(NSAttributedString(string: "  "))
        title.append(iconAttachment(cpu: false, status: memoryStatus))
        return title
    }

    private static func stateTitleKey(cpuStatus: ResourceStatus, memoryStatus: ResourceStatus) -> Int {
        statusIndex(cpuStatus) * allStatuses.count + statusIndex(memoryStatus)
    }

    private static func statusIndex(_ status: ResourceStatus) -> Int {
        switch status {
        case .normal:
            return 0
        case .warning:
            return 1
        case .critical:
            return 2
        }
    }

    private static func iconAttachment(
        cpu: Bool,
        status: ResourceStatus
    ) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = cpu ? cpuIconImage(for: status) : memoryIconImage(for: status)
        attachment.bounds = NSRect(x: 0, y: -iconScale, width: iconSize.width, height: iconSize.height)
        return NSAttributedString(attachment: attachment)
    }

    private static let cpuNormalIconImage: NSImage = makeChipIcon(memory: false, status: .normal)
    private static let cpuWarningIconImage: NSImage = makeChipIcon(memory: false, status: .warning)
    private static let cpuCriticalIconImage: NSImage = makeChipIcon(memory: false, status: .critical)
    private static let memoryNormalIconImage: NSImage = makeChipIcon(memory: true, status: .normal)
    private static let memoryWarningIconImage: NSImage = makeChipIcon(memory: true, status: .warning)
    private static let memoryCriticalIconImage: NSImage = makeChipIcon(memory: true, status: .critical)

    private static func cpuIconImage(for status: ResourceStatus) -> NSImage {
        switch status {
        case .normal:
            return cpuNormalIconImage
        case .warning:
            return cpuWarningIconImage
        case .critical:
            return cpuCriticalIconImage
        }
    }

    private static func memoryIconImage(for status: ResourceStatus) -> NSImage {
        switch status {
        case .normal:
            return memoryNormalIconImage
        case .warning:
            return memoryWarningIconImage
        case .critical:
            return memoryCriticalIconImage
        }
    }

    private static func makeChipIcon(memory: Bool, status: ResourceStatus) -> NSImage {
        let image = NSImage(size: iconSize)
        image.lockFocus()
        defer { image.unlockFocus() }
        let scale = iconScale
        func scaled(_ value: CGFloat) -> CGFloat { value * scale }

        NSColor.black.setStroke()
        NSColor.clear.setFill()
        if memory {
            let module = NSRect(x: scaled(1.2), y: scaled(3.0), width: scaled(9.6), height: scaled(5.6))
            let modulePath = NSBezierPath(roundedRect: module, xRadius: scaled(1.0), yRadius: scaled(1.0))
            modulePath.lineWidth = scaled(1.0)
            modulePath.stroke()

            for x in [2.3, 5.0, 7.7] {
                let slot = NSBezierPath(
                    roundedRect: NSRect(x: scaled(x), y: scaled(4.1), width: scaled(1.4), height: scaled(2.6)),
                    xRadius: scaled(0.4),
                    yRadius: scaled(0.4)
                )
                slot.lineWidth = scaled(0.7)
                slot.stroke()
            }

            for x in [2.2, 4.0, 5.8, 7.6, 9.4] {
                let pin = NSBezierPath()
                pin.move(to: NSPoint(x: scaled(x), y: module.minY))
                pin.line(to: NSPoint(x: scaled(x), y: module.minY - scaled(1.2)))
                pin.lineWidth = scaled(0.7)
                pin.stroke()
            }
        } else {
            let body = NSRect(x: scaled(1.8), y: scaled(2.0), width: scaled(8.4), height: scaled(8.0))
            let bodyPath = NSBezierPath(roundedRect: body, xRadius: scaled(1.2), yRadius: scaled(1.2))
            bodyPath.lineWidth = scaled(1.0)
            bodyPath.stroke()

            let core = NSBezierPath(ovalIn: NSRect(x: scaled(4.4), y: scaled(4.4), width: scaled(3.0), height: scaled(3.0)))
            core.lineWidth = scaled(0.8)
            core.stroke()

            let pinLength = scaled(1.1)
            let pinY: [CGFloat] = [3.4, 6.0, 8.6].map(scaled)
            for y in pinY {
                let left = NSBezierPath()
                left.move(to: NSPoint(x: body.minX, y: y))
                left.line(to: NSPoint(x: body.minX - pinLength, y: y))
                left.lineWidth = scaled(0.8)
                left.stroke()

                let right = NSBezierPath()
                right.move(to: NSPoint(x: body.maxX, y: y))
                right.line(to: NSPoint(x: body.maxX + pinLength, y: y))
                right.lineWidth = scaled(0.8)
                right.stroke()
            }
        }
        NSColor.black.setFill()
        drawStatusMarker(status: status, scale: scale)

        image.isTemplate = true
        return image
    }

    private static func drawStatusMarker(status: ResourceStatus, scale: CGFloat) {
        func scaled(_ value: CGFloat) -> CGFloat { value * scale }
        switch status {
        case .normal:
            return
        case .warning:
            let marker = NSBezierPath(
                roundedRect: NSRect(x: scaled(8.2), y: scaled(9.1), width: scaled(2.4), height: scaled(1.1)),
                xRadius: scaled(0.5),
                yRadius: scaled(0.5)
            )
            marker.fill()
        case .critical:
            let stem = NSBezierPath(
                roundedRect: NSRect(x: scaled(9.0), y: scaled(8.1), width: scaled(0.9), height: scaled(2.4)),
                xRadius: scaled(0.45),
                yRadius: scaled(0.45)
            )
            stem.fill()
            let dot = NSBezierPath(ovalIn: NSRect(x: scaled(9.0), y: scaled(7.0), width: scaled(0.9), height: scaled(0.9)))
            dot.fill()
        }
    }
}
