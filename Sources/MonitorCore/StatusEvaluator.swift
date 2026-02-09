public struct ResourceStatuses: Sendable, Equatable {
    public var cpu: ResourceStatus
    public var memory: ResourceStatus

    public init(cpu: ResourceStatus, memory: ResourceStatus) {
        self.cpu = cpu
        self.memory = memory
    }
}

public struct StatusEvaluator: Sendable {
    public var thresholds: AlertThresholds

    public init(thresholds: AlertThresholds = .default) {
        self.thresholds = thresholds
    }

    public func evaluate(_ snapshot: SystemSnapshot) -> ResourceStatuses {
        let cpu = resolveStatus(
            usage: snapshot.cpuUsage,
            warningThreshold: thresholds.cpuWarningUsage,
            criticalThreshold: thresholds.cpuCriticalUsage
        )
        let memory = resolveStatus(
            usage: snapshot.memoryUsage,
            warningThreshold: thresholds.memoryWarningUsage,
            criticalThreshold: thresholds.memoryCriticalUsage
        )
        return ResourceStatuses(cpu: cpu, memory: memory)
    }

    public func hasCriticalPressure(_ snapshot: SystemSnapshot) -> Bool {
        let statuses = evaluate(snapshot)
        return statuses.cpu == .critical || statuses.memory == .critical
    }

    private func resolveStatus(
        usage: Double,
        warningThreshold: Double,
        criticalThreshold: Double
    ) -> ResourceStatus {
        if usage >= criticalThreshold {
            return .critical
        }
        if usage >= warningThreshold {
            return .warning
        }
        return .normal
    }
}
