import MonitorCore

enum SamplingDetailResolver {
    static func resolve(
        displayMode: StatusItemDisplayMode,
        isMenuOpen: Bool
    ) -> SamplingDetail {
        if isMenuOpen {
            return .full
        }
        switch displayMode {
        case .state, .numeric:
            return .summary
        }
    }
}
