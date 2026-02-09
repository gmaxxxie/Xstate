import MonitorCore

struct StatusBarTitleContent: Equatable {
    var cpuValue: String
    var memoryValue: String
    var cacheKey: String
}

enum StatusBarTitleContentBuilder {
    static func build(
        mode: StatusItemDisplayMode,
        snapshot: SystemSnapshot,
        statuses: ResourceStatuses
    ) -> StatusBarTitleContent {
        switch mode {
        case .state:
            return StatusBarTitleContent(
                cpuValue: "",
                memoryValue: "",
                cacheKey: "\(mode.rawValue)|\(statuses.cpu)|\(statuses.memory)"
            )
        case .numeric:
            let cpuValue = ValueFormatters.percent(snapshot.cpuUsage)
            let memoryValue = ValueFormatters.percent(snapshot.memoryUsage)
            return StatusBarTitleContent(
                cpuValue: cpuValue,
                memoryValue: memoryValue,
                cacheKey: "\(mode.rawValue)|\(cpuValue)|\(memoryValue)|\(statuses.cpu)|\(statuses.memory)"
            )
        }
    }

    static func error(mode: StatusItemDisplayMode) -> StatusBarTitleContent {
        switch mode {
        case .state:
            return StatusBarTitleContent(cpuValue: "", memoryValue: "", cacheKey: "\(mode.rawValue)|error")
        case .numeric:
            return StatusBarTitleContent(cpuValue: "--", memoryValue: "--", cacheKey: "\(mode.rawValue)|error")
        }
    }
}
