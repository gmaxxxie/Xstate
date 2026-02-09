import Darwin
import Foundation

public enum SamplingDetail: Sendable, Equatable {
    case summary
    case full
}

public protocol SystemSampling: Sendable {
    func sample() throws -> SystemSnapshot
    func sample(detail: SamplingDetail) throws -> SystemSnapshot
}

public extension SystemSampling {
    func sample(detail: SamplingDetail) throws -> SystemSnapshot {
        try sample()
    }
}

struct CPUTicks: Sendable, Equatable {
    var user: UInt64
    var nice: UInt64
    var system: UInt64
    var idle: UInt64

    init(user: UInt64, nice: UInt64, system: UInt64, idle: UInt64) {
        self.user = user
        self.nice = nice
        self.system = system
        self.idle = idle
    }

    init(loadInfo: host_cpu_load_info_data_t) {
        // Darwin CPU tick order: USER, SYSTEM, IDLE, NICE.
        self.user = UInt64(loadInfo.cpu_ticks.0)
        self.system = UInt64(loadInfo.cpu_ticks.1)
        self.idle = UInt64(loadInfo.cpu_ticks.2)
        self.nice = UInt64(loadInfo.cpu_ticks.3)
    }

    var total: UInt64 {
        user + nice + system + idle
    }

    var active: UInt64 {
        user + nice + system
    }
}

public enum SystemSamplerError: Error {
    case cpuReadFailed(kern_return_t)
    case memoryReadFailed(kern_return_t)
    case pageSizeReadFailed(kern_return_t)
}

public final class MachSystemSampler: SystemSampling, @unchecked Sendable {
    private var previousTicks: CPUTicks?
    private let totalMemoryBytes: UInt64

    public init() {
        self.totalMemoryBytes = ProcessInfo.processInfo.physicalMemory
    }

    public func sample() throws -> SystemSnapshot {
        try sample(detail: .full)
    }

    public func sample(detail: SamplingDetail) throws -> SystemSnapshot {
        let currentTicks = try readCPUTicks()
        let cpuUsage = Self.computeCPUUsage(previousTicks: previousTicks, currentTicks: currentTicks)
        previousTicks = currentTicks

        let memoryMetrics = try readMemory(summaryOnly: detail == .summary)
        return SystemSnapshot(
            cpuUsage: cpuUsage,
            usedMemoryBytes: memoryMetrics.usedBytes,
            totalMemoryBytes: memoryMetrics.totalBytes,
            memoryAppBytes: memoryMetrics.appBytes,
            memoryWiredBytes: memoryMetrics.wiredBytes,
            memoryCompressedBytes: memoryMetrics.compressedBytes,
            memoryCachedBytes: memoryMetrics.cachedBytes
        )
    }

    static func computeCPUUsage(previousTicks: CPUTicks?, currentTicks: CPUTicks) -> Double {
        guard let previousTicks else { return 0 }

        let totalDelta = currentTicks.total &- previousTicks.total
        guard totalDelta > 0 else { return 0 }

        let activeDelta = currentTicks.active &- previousTicks.active
        let usage = Double(activeDelta) / Double(totalDelta)
        return max(0, min(1, usage))
    }

    private func readCPUTicks() throws -> CPUTicks {
        let host = mach_host_self()
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &loadInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPointer in
                host_statistics(host, HOST_CPU_LOAD_INFO, intPointer, &count)
            }
        }
        guard result == KERN_SUCCESS else {
            throw SystemSamplerError.cpuReadFailed(result)
        }
        return CPUTicks(loadInfo: loadInfo)
    }

    private func readMemory(summaryOnly: Bool) throws -> MemoryMetrics {
        let host = mach_host_self()

        var pageSize: vm_size_t = 0
        let pageSizeResult = host_page_size(host, &pageSize)
        guard pageSizeResult == KERN_SUCCESS else {
            throw SystemSamplerError.pageSizeReadFailed(pageSizeResult)
        }

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let statsResult = withUnsafeMutablePointer(to: &vmStats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPointer in
                host_statistics64(host, HOST_VM_INFO64, intPointer, &count)
            }
        }
        guard statsResult == KERN_SUCCESS else {
            throw SystemSamplerError.memoryReadFailed(statsResult)
        }

        let counters = MemoryPageCounters(
            active: UInt64(vmStats.active_count),
            inactive: UInt64(vmStats.inactive_count),
            wired: UInt64(vmStats.wire_count),
            compressed: UInt64(vmStats.compressor_page_count),
            internalPages: UInt64(vmStats.internal_page_count),
            purgeablePages: UInt64(vmStats.purgeable_count),
            free: UInt64(vmStats.free_count),
            speculative: UInt64(vmStats.speculative_count)
        )

        if summaryOnly {
            let appPagesFromInternal = counters.internalPages > counters.purgeablePages
                ? counters.internalPages - counters.purgeablePages
                : 0
            let appPages = appPagesFromInternal > 0 ? appPagesFromInternal : counters.active
            let usedBytes = min(
                (appPages + counters.wired + counters.compressed) * UInt64(pageSize),
                totalMemoryBytes
            )
            return MemoryMetrics(
                totalBytes: totalMemoryBytes,
                usedBytes: usedBytes,
                appBytes: 0,
                wiredBytes: 0,
                compressedBytes: 0,
                cachedBytes: 0,
                freeBytes: 0
            )
        }

        return MemoryMetrics.from(
            pageSizeBytes: UInt64(pageSize),
            totalBytes: totalMemoryBytes,
            counters: counters
        )
    }

}
