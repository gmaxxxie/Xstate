import Darwin
import Testing
@testable import MonitorCore

struct CPUTicksTests {
    @Test
    func initFromHostCPULoadInfoMapsTicksAndTotals() {
        var info = host_cpu_load_info_data_t()
        // Darwin order: USER, SYSTEM, IDLE, NICE.
        info.cpu_ticks = (120, 80, 285, 15)

        let ticks = CPUTicks(loadInfo: info)

        #expect(ticks.user == 120)
        #expect(ticks.nice == 15)
        #expect(ticks.system == 80)
        #expect(ticks.idle == 285)
        #expect(ticks.active == 215)
        #expect(ticks.total == 500)
    }

    @Test
    func computeCPUUsageUsesTickDeltas() {
        let previous = CPUTicks(user: 100, nice: 20, system: 80, idle: 300)
        let current = CPUTicks(user: 140, nice: 20, system: 120, idle: 340)

        let usage = MachSystemSampler.computeCPUUsage(previousTicks: previous, currentTicks: current)

        #expect(usage == (2.0 / 3.0))
    }
}
