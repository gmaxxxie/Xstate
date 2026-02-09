public struct SystemSnapshot: Sendable, Equatable {
    public var cpuUsage: Double
    public var usedMemoryBytes: UInt64
    public var totalMemoryBytes: UInt64
    public var memoryAppBytes: UInt64
    public var memoryWiredBytes: UInt64
    public var memoryCompressedBytes: UInt64
    public var memoryCachedBytes: UInt64

    public init(
        cpuUsage: Double,
        usedMemoryBytes: UInt64,
        totalMemoryBytes: UInt64,
        memoryAppBytes: UInt64 = 0,
        memoryWiredBytes: UInt64 = 0,
        memoryCompressedBytes: UInt64 = 0,
        memoryCachedBytes: UInt64 = 0
    ) {
        self.cpuUsage = cpuUsage
        self.usedMemoryBytes = usedMemoryBytes
        self.totalMemoryBytes = totalMemoryBytes
        self.memoryAppBytes = memoryAppBytes
        self.memoryWiredBytes = memoryWiredBytes
        self.memoryCompressedBytes = memoryCompressedBytes
        self.memoryCachedBytes = memoryCachedBytes
    }

    public var memoryUsage: Double {
        guard totalMemoryBytes > 0 else { return 0 }
        return Double(usedMemoryBytes) / Double(totalMemoryBytes)
    }
}

public enum ResourceStatus: Sendable, Equatable {
    case normal
    case warning
    case critical
}

public struct AlertThresholds: Sendable, Equatable {
    public var cpuWarningUsage: Double
    public var cpuCriticalUsage: Double
    public var memoryWarningUsage: Double
    public var memoryCriticalUsage: Double

    public init(
        cpuWarningUsage: Double,
        cpuCriticalUsage: Double,
        memoryWarningUsage: Double,
        memoryCriticalUsage: Double
    ) {
        self.cpuWarningUsage = cpuWarningUsage
        self.cpuCriticalUsage = cpuCriticalUsage
        self.memoryWarningUsage = memoryWarningUsage
        self.memoryCriticalUsage = memoryCriticalUsage
    }

    public init(cpuCriticalUsage: Double, memoryCriticalUsage: Double) {
        self.init(
            cpuWarningUsage: cpuCriticalUsage,
            cpuCriticalUsage: cpuCriticalUsage,
            memoryWarningUsage: memoryCriticalUsage,
            memoryCriticalUsage: memoryCriticalUsage
        )
    }

    public static let `default` = AlertThresholds(
        cpuWarningUsage: 0.90,
        cpuCriticalUsage: 0.99,
        memoryWarningUsage: 0.90,
        memoryCriticalUsage: 0.99
    )
}
