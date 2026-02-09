import AppKit
import MonitorCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let thresholds = AlertThresholds(
        cpuWarningUsage: 0.90,
        cpuCriticalUsage: 0.99,
        memoryWarningUsage: 0.90,
        memoryCriticalUsage: 0.99
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppIconProvider.applyToApplication()

        let sampler = MachSystemSampler()
        let evaluator = StatusEvaluator(thresholds: thresholds)
        let controller = MenuBarController(sampler: sampler, evaluator: evaluator)
        controller.start()
        menuBarController = controller
    }
}
