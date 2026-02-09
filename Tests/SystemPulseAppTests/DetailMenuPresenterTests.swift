import AppKit
import XCTest
import MonitorCore
@testable import SystemPulseApp

final class DetailMenuPresenterTests: XCTestCase {
    func testAttachAddsDetailNodesOnlyOnce() {
        let menu = NSMenu()
        let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit", action: nil, keyEquivalent: "")
        menu.addItem(modeItem)
        menu.addItem(quitItem)
        let presenter = DetailMenuPresenter(menu: menu)

        presenter.attachIfNeeded()
        let firstAttachCount = menu.items.count
        presenter.attachIfNeeded()

        XCTAssertEqual(menu.items.count, firstAttachCount)
        XCTAssertGreaterThan(firstAttachCount, 2)
    }

    func testDetachRemovesDetailNodesAndRestoresBaseMenu() {
        let menu = NSMenu()
        let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit", action: nil, keyEquivalent: "")
        menu.addItem(modeItem)
        menu.addItem(quitItem)
        let presenter = DetailMenuPresenter(menu: menu)

        presenter.attachIfNeeded()
        presenter.detach()

        XCTAssertEqual(menu.items.count, 2)
        XCTAssertEqual(menu.items[0].title, "Mode")
        XCTAssertEqual(menu.items[1].title, "Quit")
    }

    func testRenderUpdatesCpuAndMemoryTitlesWhenAttached() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Mode", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: nil, keyEquivalent: ""))
        let presenter = DetailMenuPresenter(menu: menu)
        presenter.attachIfNeeded()

        let snapshot = SystemSnapshot(
            cpuUsage: 0.42,
            usedMemoryBytes: 6 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )
        presenter.render(snapshot: snapshot)

        XCTAssertTrue(menu.items.contains(where: { $0.title == "CPU: 42%" }))
        XCTAssertTrue(menu.items.contains(where: { $0.title.contains("Used Memory:") }))
    }
}
