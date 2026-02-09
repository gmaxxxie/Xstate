import Foundation

public enum ValueFormatters {
    public static func percent(_ value: Double) -> String {
        let clamped = max(0, min(1, value))
        let percentage = Int((clamped * 100).rounded())
        return "\(percentage)%"
    }

    public static func memorySummary(usedBytes: UInt64, totalBytes: UInt64) -> String {
        let bytesPerGB = 1024.0 * 1024.0 * 1024.0
        let usedGB = Double(usedBytes) / bytesPerGB
        let totalGB = Double(totalBytes) / bytesPerGB
        let usage = totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes)
        return "\(String(format: "%.1f", usedGB)) / \(String(format: "%.1f", totalGB)) GB (\(percent(usage)))"
    }

    public static func gigabytes(_ bytes: UInt64) -> String {
        let bytesPerGB = 1024.0 * 1024.0 * 1024.0
        let value = Double(bytes) / bytesPerGB
        return "\(String(format: "%.2f", value)) GB"
    }

    public static func statusBarTitle(from snapshot: SystemSnapshot) -> String {
        "CPU \(percent(snapshot.cpuUsage)) | MEM \(percent(snapshot.memoryUsage))"
    }
}
