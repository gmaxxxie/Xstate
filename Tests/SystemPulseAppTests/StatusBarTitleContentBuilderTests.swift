import XCTest
import MonitorCore
@testable import SystemPulseApp

final class StatusBarTitleContentBuilderTests: XCTestCase {
    func testStateModeCacheKeyIgnoresPercentageChangesWhenStatusUnchanged() {
        let snapshotA = SystemSnapshot(
            cpuUsage: 0.22,
            usedMemoryBytes: 5 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )
        let snapshotB = SystemSnapshot(
            cpuUsage: 0.68,
            usedMemoryBytes: 7 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )
        let statuses = ResourceStatuses(cpu: .normal, memory: .normal)

        let contentA = StatusBarTitleContentBuilder.build(
            mode: .state,
            snapshot: snapshotA,
            statuses: statuses
        )
        let contentB = StatusBarTitleContentBuilder.build(
            mode: .state,
            snapshot: snapshotB,
            statuses: statuses
        )

        XCTAssertEqual(contentA.cacheKey, contentB.cacheKey)
        XCTAssertEqual(contentA.cpuValue, "")
        XCTAssertEqual(contentA.memoryValue, "")
    }

    func testNumericModeCacheKeyTracksPercentageChanges() {
        let snapshotA = SystemSnapshot(
            cpuUsage: 0.22,
            usedMemoryBytes: 5 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )
        let snapshotB = SystemSnapshot(
            cpuUsage: 0.68,
            usedMemoryBytes: 7 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )
        let statuses = ResourceStatuses(cpu: .normal, memory: .normal)

        let contentA = StatusBarTitleContentBuilder.build(
            mode: .numeric,
            snapshot: snapshotA,
            statuses: statuses
        )
        let contentB = StatusBarTitleContentBuilder.build(
            mode: .numeric,
            snapshot: snapshotB,
            statuses: statuses
        )

        XCTAssertNotEqual(contentA.cacheKey, contentB.cacheKey)
        XCTAssertNotEqual(contentA.cpuValue, contentB.cpuValue)
        XCTAssertNotEqual(contentA.memoryValue, contentB.memoryValue)
    }
}
