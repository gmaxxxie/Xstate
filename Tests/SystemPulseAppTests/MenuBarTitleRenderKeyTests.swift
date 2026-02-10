import AppKit
import XCTest
@testable import SystemPulseApp

@MainActor
final class MenuBarTitleRenderKeyTests: XCTestCase {
    func testMakeUsesDifferentKeysForDarkAndLightAppearance() {
        let light = NSAppearance(named: .aqua)!
        let dark = NSAppearance(named: .darkAqua)!

        let lightKey = MenuBarTitleRenderKey.make(contentCacheKey: "state|0|0", appearance: light)
        let darkKey = MenuBarTitleRenderKey.make(contentCacheKey: "state|0|0", appearance: dark)

        XCTAssertNotEqual(lightKey, darkKey)
    }

    func testMakeUsesStableKeysForSameAppearanceTone() {
        let first = MenuBarTitleRenderKey.make(contentCacheKey: "numeric|42|68", appearance: NSAppearance(named: .darkAqua)!)
        let second = MenuBarTitleRenderKey.make(contentCacheKey: "numeric|42|68", appearance: NSAppearance(named: .vibrantDark)!)

        XCTAssertEqual(first, second)
    }
}
