import Testing
@testable import MonitorCore

struct MemoryMetricsTests {
    @Test
    func usedMemoryExcludesCachedPages() {
        let counters = MemoryPageCounters(
            active: 30,
            inactive: 40,
            wired: 20,
            compressed: 10,
            internalPages: 35,
            purgeablePages: 5,
            free: 10,
            speculative: 5
        )

        let metrics = MemoryMetrics.from(
            pageSizeBytes: 1,
            totalBytes: 200,
            counters: counters
        )

        #expect(metrics.appBytes == 30)
        #expect(metrics.wiredBytes == 20)
        #expect(metrics.compressedBytes == 10)
        #expect(metrics.cachedBytes == 40)
        #expect(metrics.usedBytes == 60)
    }

    @Test
    func usageRatioUsesUsedOverPhysicalMemory() {
        let counters = MemoryPageCounters(
            active: 0,
            inactive: 20,
            wired: 40,
            compressed: 10,
            internalPages: 30,
            purgeablePages: 0,
            free: 5,
            speculative: 5
        )

        let metrics = MemoryMetrics.from(
            pageSizeBytes: 1,
            totalBytes: 100,
            counters: counters
        )

        #expect(metrics.usedBytes == 80)
        #expect(metrics.usage == 0.8)
    }
}
