import Testing
@testable import MonitorCore

struct StatusEvaluatorTests {
    @Test
    func defaultThresholdsKeepUsageNormalBelowWarningLine() {
        let evaluator = StatusEvaluator()
        let snapshot = SystemSnapshot(
            cpuUsage: 0.89,
            usedMemoryBytes: 89 * 1024 * 1024,
            totalMemoryBytes: 100 * 1024 * 1024
        )

        let statuses = evaluator.evaluate(snapshot)

        #expect(statuses.cpu == .normal)
        #expect(statuses.memory == .normal)
        #expect(evaluator.hasCriticalPressure(snapshot) == false)
    }

    @Test
    func cpuAndMemoryTurnWarningAfterWarningThreshold() {
        let evaluator = StatusEvaluator(
            thresholds: AlertThresholds(
                cpuWarningUsage: 0.75,
                cpuCriticalUsage: 0.99,
                memoryWarningUsage: 0.75,
                memoryCriticalUsage: 0.99
            )
        )
        let snapshot = SystemSnapshot(
            cpuUsage: 0.80,
            usedMemoryBytes: 13 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )

        let statuses = evaluator.evaluate(snapshot)

        #expect(statuses.cpu == .warning)
        #expect(statuses.memory == .warning)
        #expect(evaluator.hasCriticalPressure(snapshot) == false)
    }

    @Test
    func cpuTurnsCriticalWhenUsageCrossesFullLoadThreshold() {
        let evaluator = StatusEvaluator(
            thresholds: AlertThresholds(
                cpuWarningUsage: 0.75,
                cpuCriticalUsage: 0.99,
                memoryWarningUsage: 0.75,
                memoryCriticalUsage: 0.99
            )
        )
        let snapshot = SystemSnapshot(
            cpuUsage: 0.995,
            usedMemoryBytes: 10 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )

        let statuses = evaluator.evaluate(snapshot)

        #expect(statuses.cpu == .critical)
        #expect(statuses.memory == .normal)
        #expect(evaluator.hasCriticalPressure(snapshot))
    }

    @Test
    func memoryTurnsCriticalWhenUsageCrossesFullLoadThreshold() {
        let evaluator = StatusEvaluator(
            thresholds: AlertThresholds(
                cpuWarningUsage: 0.75,
                cpuCriticalUsage: 0.99,
                memoryWarningUsage: 0.75,
                memoryCriticalUsage: 0.99
            )
        )
        let snapshot = SystemSnapshot(
            cpuUsage: 0.52,
            usedMemoryBytes: 16 * 1024 * 1024 * 1024,
            totalMemoryBytes: 16 * 1024 * 1024 * 1024
        )

        let statuses = evaluator.evaluate(snapshot)

        #expect(statuses.cpu == .normal)
        #expect(statuses.memory == .critical)
        #expect(evaluator.hasCriticalPressure(snapshot))
    }
}
