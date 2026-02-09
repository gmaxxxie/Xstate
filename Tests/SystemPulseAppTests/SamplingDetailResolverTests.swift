import XCTest
@testable import SystemPulseApp

final class SamplingDetailResolverTests: XCTestCase {
    func testMenuClosedUsesSummarySamplingForStateMode() {
        let detail = SamplingDetailResolver.resolve(
            displayMode: .state,
            isMenuOpen: false
        )

        XCTAssertEqual(detail, .summary)
    }

    func testMenuClosedUsesSummarySamplingForNumericMode() {
        let detail = SamplingDetailResolver.resolve(
            displayMode: .numeric,
            isMenuOpen: false
        )

        XCTAssertEqual(detail, .summary)
    }

    func testMenuOpenAlwaysUsesFullSampling() {
        let detail = SamplingDetailResolver.resolve(
            displayMode: .state,
            isMenuOpen: true
        )

        XCTAssertEqual(detail, .full)
    }
}
