public struct MemoryPageCounters: Sendable, Equatable {
    public var active: UInt64
    public var inactive: UInt64
    public var wired: UInt64
    public var compressed: UInt64
    public var internalPages: UInt64
    public var purgeablePages: UInt64
    public var free: UInt64
    public var speculative: UInt64

    public init(
        active: UInt64,
        inactive: UInt64,
        wired: UInt64,
        compressed: UInt64,
        internalPages: UInt64,
        purgeablePages: UInt64,
        free: UInt64,
        speculative: UInt64
    ) {
        self.active = active
        self.inactive = inactive
        self.wired = wired
        self.compressed = compressed
        self.internalPages = internalPages
        self.purgeablePages = purgeablePages
        self.free = free
        self.speculative = speculative
    }
}

public struct MemoryMetrics: Sendable, Equatable {
    public var totalBytes: UInt64
    public var usedBytes: UInt64
    public var appBytes: UInt64
    public var wiredBytes: UInt64
    public var compressedBytes: UInt64
    public var cachedBytes: UInt64
    public var freeBytes: UInt64

    public init(
        totalBytes: UInt64,
        usedBytes: UInt64,
        appBytes: UInt64,
        wiredBytes: UInt64,
        compressedBytes: UInt64,
        cachedBytes: UInt64,
        freeBytes: UInt64
    ) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.appBytes = appBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.cachedBytes = cachedBytes
        self.freeBytes = freeBytes
    }

    public var usage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    public static func from(
        pageSizeBytes: UInt64,
        totalBytes: UInt64,
        counters: MemoryPageCounters
    ) -> MemoryMetrics {
        let appPagesFromInternal = counters.internalPages > counters.purgeablePages
            ? counters.internalPages - counters.purgeablePages
            : 0
        let appPages = appPagesFromInternal > 0 ? appPagesFromInternal : counters.active

        let appBytes = appPages * pageSizeBytes
        let wiredBytes = counters.wired * pageSizeBytes
        let compressedBytes = counters.compressed * pageSizeBytes
        let cachedBytes = counters.inactive * pageSizeBytes
        let freeBytes = (counters.free + counters.speculative) * pageSizeBytes
        let rawUsedBytes = appBytes + wiredBytes + compressedBytes
        let usedBytes = min(rawUsedBytes, totalBytes)

        return MemoryMetrics(
            totalBytes: totalBytes,
            usedBytes: usedBytes,
            appBytes: appBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            cachedBytes: cachedBytes,
            freeBytes: freeBytes
        )
    }
}
