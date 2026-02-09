import AppKit
import MonitorCore

@MainActor
final class MenuBarController: NSObject {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()

    private let sampler: any SystemSampling
    private let evaluator: StatusEvaluator
    private let statusItem: NSStatusItem

    private let menu = NSMenu()
    private let displayModeItem = NSMenuItem(title: "", action: #selector(toggleDisplayMode), keyEquivalent: "")
    private let quitItem = NSMenuItem(title: "Quit Xstate", action: #selector(quit), keyEquivalent: "q")
    private lazy var detailMenuPresenter = DetailMenuPresenter(menu: menu)
    private var timer: DispatchSourceTimer?
    private var lastStatusKey: String?
    private var latestSnapshot: SystemSnapshot?
    private var latestStatuses: ResourceStatuses?
    private var latestError = false
    private var isMenuOpen = false
    private var statusDisplayMode: StatusItemDisplayMode = .state

    init(sampler: any SystemSampling, evaluator: StatusEvaluator) {
        self.sampler = sampler
        self.evaluator = evaluator
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureMenu()
    }

    deinit {
        timer?.cancel()
    }

    func start() {
        refresh()
        startTimer()
    }

    private func configureMenu() {
        statusItem.length = NSStatusItem.variableLength
        statusItem.button?.image = nil
        statusItem.button?.attributedTitle = StatusItemTitleBuilder.build(
            cpuValue: "--",
            memoryValue: "--",
            cpuStatus: .normal,
            memoryStatus: .normal,
            mode: statusDisplayMode
        )
        menu.delegate = self

        displayModeItem.target = self
        quitItem.target = self
        updateDisplayModeMenuItemTitle()

        menu.addItem(displayModeItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.refresh()
        }
        timer.resume()
        self.timer = timer
    }

    private func refresh() {
        autoreleasepool {
            do {
                let detail = SamplingDetailResolver.resolve(
                    displayMode: statusDisplayMode,
                    isMenuOpen: isMenuOpen
                )
                let snapshot = try sampler.sample(detail: detail)
                let statuses = evaluator.evaluate(snapshot)
                latestSnapshot = snapshot
                latestStatuses = statuses
                latestError = false
                renderStatusBar(snapshot: snapshot, statuses: statuses)
                if isMenuOpen {
                    detailMenuPresenter.attachIfNeeded()
                    renderMenu(snapshot: snapshot)
                }
            } catch {
                latestSnapshot = nil
                latestStatuses = nil
                latestError = true
                renderStatusBarError()
                if isMenuOpen {
                    detailMenuPresenter.attachIfNeeded()
                    renderMenuError()
                }
            }
        }
    }

    private func renderStatusBar(snapshot: SystemSnapshot, statuses: ResourceStatuses) {
        let content = StatusBarTitleContentBuilder.build(
            mode: statusDisplayMode,
            snapshot: snapshot,
            statuses: statuses
        )
        updateStatusBarTitle(
            content: content,
            cpuStatus: statuses.cpu,
            memoryStatus: statuses.memory
        )
    }

    private func renderMenu(snapshot: SystemSnapshot) {
        detailMenuPresenter.render(
            snapshot: snapshot,
            updatedAt: Self.timeFormatter.string(from: Date())
        )
    }

    private func renderStatusBarError() {
        let content = StatusBarTitleContentBuilder.error(mode: statusDisplayMode)
        updateStatusBarTitle(
            content: content,
            cpuStatus: .critical,
            memoryStatus: .critical
        )
    }

    private func renderMenuError() {
        detailMenuPresenter.renderError()
    }

    private func updateStatusBarTitle(
        content: StatusBarTitleContent,
        cpuStatus: ResourceStatus,
        memoryStatus: ResourceStatus
    ) {
        guard let button = statusItem.button else { return }
        if content.cacheKey == lastStatusKey { return }
        lastStatusKey = content.cacheKey
        button.attributedTitle = StatusItemTitleBuilder.build(
            cpuValue: content.cpuValue,
            memoryValue: content.memoryValue,
            cpuStatus: cpuStatus,
            memoryStatus: memoryStatus,
            mode: statusDisplayMode
        )
    }

    private func updateDisplayModeMenuItemTitle() {
        switch statusDisplayMode {
        case .state:
            displayModeItem.title = "Switch to Numeric View"
        case .numeric:
            displayModeItem.title = "Switch to Status View"
        }
    }

    private func renderLatestStatusBar() {
        if latestError {
            renderStatusBarError()
            return
        }
        guard let snapshot = latestSnapshot, let statuses = latestStatuses else {
            renderStatusBarError()
            return
        }
        renderStatusBar(snapshot: snapshot, statuses: statuses)
    }

    @objc
    private func toggleDisplayMode() {
        statusDisplayMode.toggle()
        updateDisplayModeMenuItemTitle()
        renderLatestStatusBar()
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension MenuBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true
        detailMenuPresenter.attachIfNeeded()
        refresh()
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
        detailMenuPresenter.detach()
    }
}
