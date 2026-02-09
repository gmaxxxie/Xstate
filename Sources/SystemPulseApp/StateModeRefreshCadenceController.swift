import MonitorCore

struct StateModeRefreshCadenceController {
    private var shouldRefreshOnNextSlowTick = true

    mutating func shouldSkipTimerTick(
        displayMode: StatusItemDisplayMode,
        isMenuOpen: Bool,
        latestStatuses: ResourceStatuses?,
        latestError: Bool
    ) -> Bool {
        let canUseSlowCadence = displayMode == .state &&
            !isMenuOpen &&
            !latestError &&
            latestStatuses?.cpu == .normal &&
            latestStatuses?.memory == .normal

        guard canUseSlowCadence else {
            shouldRefreshOnNextSlowTick = true
            return false
        }

        let shouldRefresh = shouldRefreshOnNextSlowTick
        shouldRefreshOnNextSlowTick.toggle()
        return !shouldRefresh
    }
}
