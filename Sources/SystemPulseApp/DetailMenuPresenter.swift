import AppKit
import MonitorCore

final class DetailMenuPresenter {
    private struct Items {
        let cpuItem: NSMenuItem
        let memoryPhysicalItem: NSMenuItem
        let memoryItem: NSMenuItem
        let memoryCachedItem: NSMenuItem
        let memoryAppItem: NSMenuItem
        let memoryWiredItem: NSMenuItem
        let memoryCompressedItem: NSMenuItem
        let updatedItem: NSMenuItem
        let nodes: [NSMenuItem]
    }

    private weak var menu: NSMenu?
    private var items: Items?

    init(menu: NSMenu) {
        self.menu = menu
    }

    func attachIfNeeded() {
        guard items == nil, let menu else { return }
        let built = Self.makeItems()
        items = built
        for (index, node) in built.nodes.enumerated() {
            menu.insertItem(node, at: index)
        }
    }

    func detach() {
        guard let menu, let items else { return }
        for node in items.nodes {
            menu.removeItem(node)
        }
        self.items = nil
    }

    func render(snapshot: SystemSnapshot, updatedAt: String = "--") {
        guard let items else { return }
        items.cpuItem.title = "CPU: \(ValueFormatters.percent(snapshot.cpuUsage))"
        items.memoryPhysicalItem.title = "Physical Memory: \(ValueFormatters.gigabytes(snapshot.totalMemoryBytes))"
        items.memoryItem.title = "Used Memory: \(ValueFormatters.memorySummary(usedBytes: snapshot.usedMemoryBytes, totalBytes: snapshot.totalMemoryBytes))"
        items.memoryCachedItem.title = "Cached Files: \(ValueFormatters.gigabytes(snapshot.memoryCachedBytes))"
        items.memoryAppItem.title = "App Memory: \(ValueFormatters.gigabytes(snapshot.memoryAppBytes))"
        items.memoryWiredItem.title = "Wired Memory: \(ValueFormatters.gigabytes(snapshot.memoryWiredBytes))"
        items.memoryCompressedItem.title = "Compressed: \(ValueFormatters.gigabytes(snapshot.memoryCompressedBytes))"
        items.updatedItem.title = "Updated: \(updatedAt)"
    }

    func renderError() {
        guard let items else { return }
        items.cpuItem.title = "CPU: unavailable"
        items.memoryPhysicalItem.title = "Physical Memory: unavailable"
        items.memoryItem.title = "Used Memory: unavailable"
        items.memoryCachedItem.title = "Cached Files: unavailable"
        items.memoryAppItem.title = "App Memory: unavailable"
        items.memoryWiredItem.title = "Wired Memory: unavailable"
        items.memoryCompressedItem.title = "Compressed: unavailable"
        items.updatedItem.title = "Updated: error"
    }

    private static func makeItems() -> Items {
        let cpuItem = menuItem(title: "CPU: --")
        let memoryPhysicalItem = menuItem(title: "Physical Memory: --")
        let memoryItem = menuItem(title: "Used Memory: --")
        let memoryCachedItem = menuItem(title: "Cached Files: --")
        let memoryAppItem = menuItem(title: "App Memory: --")
        let memoryWiredItem = menuItem(title: "Wired Memory: --")
        let memoryCompressedItem = menuItem(title: "Compressed: --")
        let updatedItem = menuItem(title: "Updated: --")
        let nodes: [NSMenuItem] = [
            cpuItem,
            .separator(),
            memoryPhysicalItem,
            memoryItem,
            memoryCachedItem,
            memoryAppItem,
            memoryWiredItem,
            memoryCompressedItem,
            updatedItem,
            .separator()
        ]
        return Items(
            cpuItem: cpuItem,
            memoryPhysicalItem: memoryPhysicalItem,
            memoryItem: memoryItem,
            memoryCachedItem: memoryCachedItem,
            memoryAppItem: memoryAppItem,
            memoryWiredItem: memoryWiredItem,
            memoryCompressedItem: memoryCompressedItem,
            updatedItem: updatedItem,
            nodes: nodes
        )
    }

    private static func menuItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
