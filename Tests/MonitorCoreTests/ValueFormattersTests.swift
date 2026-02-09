import Testing
@testable import MonitorCore

struct ValueFormattersTests {
    @Test
    func percentRoundsToNearestInteger() {
        #expect(ValueFormatters.percent(0.0) == "0%")
        #expect(ValueFormatters.percent(0.836) == "84%")
        #expect(ValueFormatters.percent(1.0) == "100%")
    }

    @Test
    func memorySummaryShowsUsedTotalAndPercentage() {
        let summary = ValueFormatters.memorySummary(
            usedBytes: 8 * 1024 * 1024 * 1024,
            totalBytes: 16 * 1024 * 1024 * 1024
        )

        #expect(summary == "8.0 / 16.0 GB (50%)")
    }

    @Test
    func statusBarTitleShowsCpuAndMemoryPercentages() {
        let snapshot = SystemSnapshot(
            cpuUsage: 0.42,
            usedMemoryBytes: 12 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )

        #expect(ValueFormatters.statusBarTitle(from: snapshot) == "CPU 42% | MEM 75%")
    }
}
