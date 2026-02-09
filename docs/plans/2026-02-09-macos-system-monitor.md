# macOS 轻量 CPU/内存监控应用 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建一个原生、轻量、仅在系统状态栏实时显示 CPU 与内存使用情况的 macOS 小应用，在资源紧缺时将对应数据标红。

**Architecture:** 使用一个可测试的 `MonitorCore` 模块负责采样、阈值判定与展示文案；状态栏层使用 AppKit `NSStatusItem` 常驻菜单栏，无主窗口。采样逻辑基于 Darwin/Mach API，按固定间隔轮询并更新状态栏标题与菜单内容。

**Tech Stack:** Swift 6, SwiftUI (macOS), Darwin/Mach APIs, Swift Testing

### Task 1: 初始化工程

**Files:**
- Create: `Package.swift`
- Create: `Sources/SystemPulseApp/SystemPulseApp.swift`
- Create: `Sources/MonitorCore/`
- Create: `Tests/MonitorCoreTests/`

**Step 1: 创建 Swift Package 骨架**

Run: `swift package init --type executable --name SystemPulse`
Expected: 生成基础 `Package.swift` 与 `Sources`/`Tests` 目录。

**Step 2: 调整 Package 结构**

Run: 手动改 `Package.swift`，拆分为 `MonitorCore`（库）+ `SystemPulseApp`（可执行）+ `MonitorCoreTests`。
Expected: `swift package describe` 能看到 1 个库 target、1 个可执行 target、1 个测试 target。

### Task 2: 先写失败测试（TDD Red）

**Files:**
- Create: `Tests/MonitorCoreTests/StatusEvaluatorTests.swift`
- Create: `Tests/MonitorCoreTests/FormattersTests.swift`
- Modify: `Sources/MonitorCore/`（仅先创建空壳，确保测试可编译后失败）

**Step 1: 编写阈值判定失败测试**

断言 CPU/内存超过阈值会标记为 `.critical`，否则 `.normal`。

**Step 2: 编写文案格式化失败测试**

断言百分比与内存值格式符合 UI 要求。

**Step 3: 运行测试确认失败**

Run: `swift test`
Expected: 失败原因为缺失实现或断言不满足（不是编译错误）。

### Task 3: 最小实现使测试通过（TDD Green）

**Files:**
- Create: `Sources/MonitorCore/SystemSnapshot.swift`
- Create: `Sources/MonitorCore/StatusEvaluator.swift`
- Create: `Sources/MonitorCore/ValueFormatters.swift`

**Step 1: 实现阈值判定**

实现 CPU 和内存使用率到告警状态映射逻辑。

**Step 2: 实现显示文案格式化**

实现百分比和内存展示格式。

**Step 3: 运行测试确认通过**

Run: `swift test`
Expected: 所有测试通过。

### Task 4: 实时采样与状态栏展示（无窗口）

**Files:**
- Create: `Sources/MonitorCore/SystemSampler.swift`
- Create: `Sources/SystemPulseApp/MenuBarController.swift`
- Create: `Sources/SystemPulseApp/AppDelegate.swift`
- Modify: `Sources/SystemPulseApp/SystemPulseApp.swift`

**Step 1: 实现系统采样**

使用 Mach API 读取 CPU 使用率与内存总量/已用量。

**Step 2: 轮询更新状态栏**

定时采样并刷新 `NSStatusItem` 文案，默认 1 秒刷新一次。

**Step 3: 状态栏标红逻辑**

展示 CPU、内存两项数值；当任一状态为 `.critical` 时在状态栏按钮文案使用红色高亮。

### Task 5: 验证与交付

**Files:**
- Modify: `README.md`

**Step 1: 运行测试**

Run: `swift test`
Expected: 全绿。

**Step 2: 运行构建**

Run: `swift build`
Expected: 构建成功。

**Step 3: 写使用说明**

记录如何运行、阈值配置点、轻量化取舍说明。
