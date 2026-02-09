import AppKit
import XCTest
@testable import SystemPulseApp

final class StatusItemTitleBuilderTests: XCTestCase {
    func testBuildInNumericModeUsesTwoIconsAndNoPipeSeparator() {
        let title = StatusItemTitleBuilder.build(
            cpuValue: "42%",
            memoryValue: "75%",
            cpuStatus: .normal,
            memoryStatus: .normal,
            mode: .numeric
        )

        XCTAssertEqual(title.string, "\u{FFFC} 42%  \u{FFFC} 75%")
        XCTAssertFalse(title.string.contains("|"))
        XCTAssertFalse(title.string.contains("\n"))

        var attachmentCount = 0
        title.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: title.length), options: []) { value, _, _ in
            if value is NSTextAttachment {
                attachmentCount += 1
            }
        }
        XCTAssertEqual(attachmentCount, 2)
    }

    func testBuildInNumericModeMarksWarningAndCriticalValuesWithExpectedColors() {
        let title = StatusItemTitleBuilder.build(
            cpuValue: "91%",
            memoryValue: "45%",
            cpuStatus: .warning,
            memoryStatus: .critical,
            mode: .numeric
        )

        let full = title.string as NSString
        let cpuRange = full.range(of: "91%")
        let memRange = full.range(of: "45%")

        let cpuColor = title.attribute(NSAttributedString.Key.foregroundColor, at: cpuRange.location, effectiveRange: nil) as? NSColor
        let memColor = title.attribute(NSAttributedString.Key.foregroundColor, at: memRange.location, effectiveRange: nil) as? NSColor

        XCTAssertEqual(cpuColor, NSColor.systemYellow)
        XCTAssertEqual(memColor, NSColor.systemRed)
    }

    func testBuildInStateModeShowsOnlyIconsAndColorsTheIconsByStatus() {
        let title = StatusItemTitleBuilder.build(
            cpuValue: "42%",
            memoryValue: "75%",
            cpuStatus: .warning,
            memoryStatus: .critical,
            mode: .state
        )

        XCTAssertEqual(title.string, "\u{FFFC}  \u{FFFC}")
        XCTAssertFalse(title.string.contains("%"))

        var iconColors: [NSColor?] = []
        title.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: title.length), options: []) { value, range, _ in
            guard value is NSTextAttachment else { return }
            let color = title.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
            iconColors.append(color)
        }

        XCTAssertEqual(iconColors.count, 2)
        XCTAssertEqual(iconColors[0], NSColor.systemYellow)
        XCTAssertEqual(iconColors[1], NSColor.systemRed)
    }

    func testBuildDoesNotSetCustomFontAttributes() {
        let title = StatusItemTitleBuilder.build(
            cpuValue: "42%",
            memoryValue: "75%",
            cpuStatus: .normal,
            memoryStatus: .warning,
            mode: .numeric
        )

        let baseFont = title.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil)
        XCTAssertNil(baseFont)
    }
}
