import XCTest
import MonitorCore
@testable import SystemPulseApp

final class StateModeRefreshCadenceControllerTests: XCTestCase {
    func testStateModeNormalSkipsEveryOtherTick() {
        var controller = StateModeRefreshCadenceController()

        let statuses = ResourceStatuses(cpu: .normal, memory: .normal)
        let firstSkip = controller.shouldSkipTimerTick(
            displayMode: .state,
            isMenuOpen: false,
            latestStatuses: statuses,
            latestError: false
        )
        let secondSkip = controller.shouldSkipTimerTick(
            displayMode: .state,
            isMenuOpen: false,
            latestStatuses: statuses,
            latestError: false
        )

        XCTAssertFalse(firstSkip)
        XCTAssertTrue(secondSkip)
    }

    func testStateModeWarningAlwaysRefreshesEveryTick() {
        var controller = StateModeRefreshCadenceController()

        let statuses = ResourceStatuses(cpu: .warning, memory: .normal)
        let firstSkip = controller.shouldSkipTimerTick(
            displayMode: .state,
            isMenuOpen: false,
            latestStatuses: statuses,
            latestError: false
        )
        let secondSkip = controller.shouldSkipTimerTick(
            displayMode: .state,
            isMenuOpen: false,
            latestStatuses: statuses,
            latestError: false
        )

        XCTAssertFalse(firstSkip)
        XCTAssertFalse(secondSkip)
    }

    func testNumericModeAlwaysRefreshesEveryTick() {
        var controller = StateModeRefreshCadenceController()

        let statuses = ResourceStatuses(cpu: .normal, memory: .normal)
        let firstSkip = controller.shouldSkipTimerTick(
            displayMode: .numeric,
            isMenuOpen: false,
            latestStatuses: statuses,
            latestError: false
        )
        let secondSkip = controller.shouldSkipTimerTick(
            displayMode: .numeric,
            isMenuOpen: false,
            latestStatuses: statuses,
            latestError: false
        )

        XCTAssertFalse(firstSkip)
        XCTAssertFalse(secondSkip)
    }
}
