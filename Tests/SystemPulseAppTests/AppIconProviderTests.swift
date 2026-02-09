import AppKit
import XCTest
@testable import SystemPulseApp

final class AppIconProviderTests: XCTestCase {
    func testMakeIconDefaultsToCompactRuntimeSize() {
        let icon = AppIconProvider.makeIcon()

        XCTAssertEqual(icon.size.width, 64)
        XCTAssertEqual(icon.size.height, 64)
    }

    func testMakeIconUsesRequestedSize() {
        let size = CGSize(width: 128, height: 128)

        let icon = AppIconProvider.makeIcon(size: size)

        XCTAssertEqual(icon.size.width, size.width)
        XCTAssertEqual(icon.size.height, size.height)
    }

    func testMakeIconProvidesBitmapRepresentation() {
        let icon = AppIconProvider.makeIcon(size: CGSize(width: 128, height: 128))

        let bitmap = NSBitmapImageRep(data: icon.tiffRepresentation ?? Data())
        XCTAssertNotNil(bitmap)
    }
}
