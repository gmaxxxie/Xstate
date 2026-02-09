import AppKit
import MonitorCore

enum StatusItemTitleBuilder {
    private static let iconSize = NSSize(width: 12, height: 12)

    static func build(
        cpuValue: String,
        memoryValue: String,
        cpuStatus: ResourceStatus,
        memoryStatus: ResourceStatus,
        mode: StatusItemDisplayMode
    ) -> NSAttributedString {
        let title = NSMutableAttributedString()
        title.append(iconAttachment(cpu: true, status: cpuStatus, mode: mode))

        switch mode {
        case .numeric:
            title.append(NSAttributedString(string: " \(cpuValue)  "))
            title.append(iconAttachment(cpu: false, status: memoryStatus, mode: mode))
            title.append(NSAttributedString(string: " \(memoryValue)"))
            applyValueColor(to: title, value: cpuValue, status: cpuStatus, backwards: false)
            applyValueColor(to: title, value: memoryValue, status: memoryStatus, backwards: true)
        case .state:
            title.append(NSAttributedString(string: "  "))
            title.append(iconAttachment(cpu: false, status: memoryStatus, mode: mode))
        }

        return title
    }

    private static func applyValueColor(
        to title: NSMutableAttributedString,
        value: String,
        status: ResourceStatus,
        backwards: Bool
    ) {
        guard let color = valueColor(for: status) else { return }
        let options: NSString.CompareOptions = backwards ? [.backwards] : []
        let range = (title.string as NSString).range(of: value, options: options)
        guard range.location != NSNotFound else { return }
        title.addAttribute(.foregroundColor, value: color, range: range)
    }

    private static func iconAttachment(
        cpu: Bool,
        status: ResourceStatus,
        mode: StatusItemDisplayMode
    ) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = cpu ? cpuIconImage(for: status) : memoryIconImage(for: status)
        attachment.bounds = NSRect(x: 0, y: -1, width: iconSize.width, height: iconSize.height)

        let attributed = NSMutableAttributedString(attachment: attachment)
        if mode == .state {
            attributed.addAttribute(.foregroundColor, value: iconColor(for: status), range: NSRange(location: 0, length: attributed.length))
        }
        return attributed
    }

    private static let cpuNormalIconImage: NSImage = makeChipIcon(memory: false, strokeColor: .white)
    private static let cpuWarningIconImage: NSImage = makeChipIcon(memory: false, strokeColor: .systemYellow)
    private static let cpuCriticalIconImage: NSImage = makeChipIcon(memory: false, strokeColor: .systemRed)
    private static let memoryNormalIconImage: NSImage = makeChipIcon(memory: true, strokeColor: .white)
    private static let memoryWarningIconImage: NSImage = makeChipIcon(memory: true, strokeColor: .systemYellow)
    private static let memoryCriticalIconImage: NSImage = makeChipIcon(memory: true, strokeColor: .systemRed)

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

    private static func valueColor(for status: ResourceStatus) -> NSColor? {
        switch status {
        case .normal:
            return nil
        case .warning:
            return .systemYellow
        case .critical:
            return .systemRed
        }
    }

    private static func iconColor(for status: ResourceStatus) -> NSColor {
        switch status {
        case .normal:
            return .white
        case .warning:
            return .systemYellow
        case .critical:
            return .systemRed
        }
    }

    private static func makeChipIcon(memory: Bool, strokeColor: NSColor) -> NSImage {
        let image = NSImage(size: iconSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        strokeColor.setStroke()
        NSColor.clear.setFill()
        if memory {
            let module = NSRect(x: 1.2, y: 3.0, width: 9.6, height: 5.6)
            let modulePath = NSBezierPath(roundedRect: module, xRadius: 1.0, yRadius: 1.0)
            modulePath.lineWidth = 1.0
            modulePath.stroke()

            for x in [2.3, 5.0, 7.7] {
                let slot = NSBezierPath(roundedRect: NSRect(x: x, y: 4.1, width: 1.4, height: 2.6), xRadius: 0.4, yRadius: 0.4)
                slot.lineWidth = 0.7
                slot.stroke()
            }

            for x in [2.2, 4.0, 5.8, 7.6, 9.4] {
                let pin = NSBezierPath()
                pin.move(to: NSPoint(x: x, y: module.minY))
                pin.line(to: NSPoint(x: x, y: module.minY - 1.2))
                pin.lineWidth = 0.7
                pin.stroke()
            }
        } else {
            let body = NSRect(x: 1.8, y: 2.0, width: 8.4, height: 8.0)
            let bodyPath = NSBezierPath(roundedRect: body, xRadius: 1.2, yRadius: 1.2)
            bodyPath.lineWidth = 1.0
            bodyPath.stroke()

            let core = NSBezierPath(ovalIn: NSRect(x: 4.4, y: 4.4, width: 3.0, height: 3.0))
            core.lineWidth = 0.8
            core.stroke()

            let pinLength: CGFloat = 1.1
            let pinY: [CGFloat] = [3.4, 6.0, 8.6]
            for y in pinY {
                let left = NSBezierPath()
                left.move(to: NSPoint(x: body.minX, y: y))
                left.line(to: NSPoint(x: body.minX - pinLength, y: y))
                left.lineWidth = 0.8
                left.stroke()

                let right = NSBezierPath()
                right.move(to: NSPoint(x: body.maxX, y: y))
                right.line(to: NSPoint(x: body.maxX + pinLength, y: y))
                right.lineWidth = 0.8
                right.stroke()
            }
        }

        image.isTemplate = false
        return image
    }
}
