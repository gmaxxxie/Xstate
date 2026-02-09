# Xstate

原生 macOS 状态栏小应用（无窗口），实时显示 CPU、MEM 压力。  
支持两种查看模式：状态模式（白/黄/红图标）与数值模式（百分比）。内存口径采用 `Used = App + Wired + Compressed`（缓存文件单独展示，不计入告警百分比）。

## 特性

- 仅状态栏展示：原生单行样式，支持“状态图标模式”与“百分比数值模式”切换
- 1 秒刷新一次
- 低开销：Darwin/Mach API 直接采样，无额外依赖
- 内置 `Xstate` 应用图标（程序启动时自动应用）
- 点击状态栏可查看 CPU/内存详细值并退出应用
- 菜单中可一键切换 `Switch to Numeric View / Switch to Status View`
- 内存菜单项包含：Physical、Used、Cached Files、App、Wired、Compressed
- 字体遵循 macOS 状态栏系统渲染（SF Pro Text 13pt），不使用自绘字体

## 运行

```bash
swift run Xstate
```

启动后默认是状态模式：CPU/MEM 图标按压力显示白/黄/红。  
可在菜单中切到数值模式，显示 `图标 xx%  图标 xx%`。

## 生成 .app

```bash
./install.sh --force
```

默认会生成：`dist/Xstate.app`
并自动生成应用图标：`Contents/Resources/AppIcon.icns`

可选参数：

- `--install`: 同时安装到 `/Applications`
- `--name <AppName>`: 自定义生成的 App 名称
- `--bundle-id <bundle.id>`: 自定义 Bundle ID
- `--output-dir <path>`: 自定义输出目录
- `--force`: 覆盖已有同名 `.app`

## 阈值配置

在 `Sources/SystemPulseApp/AppDelegate.swift` 修改：

```swift
private let thresholds = AlertThresholds(
    cpuWarningUsage: 0.90,
    cpuCriticalUsage: 0.99,
    memoryWarningUsage: 0.90,
    memoryCriticalUsage: 0.99
)
```

- `Warning` 进入黄色预警
- `Critical` 进入红色（满跑）状态
- 低于 `Warning` 显示白色
- 内存百分比使用 `Used / Physical`，其中 `Used = App + Wired + Compressed`

## 主要代码结构

- `Sources/MonitorCore/SystemSampler.swift`: Mach API 采样（CPU/内存）
- `Sources/MonitorCore/StatusEvaluator.swift`: 阈值判定
- `Sources/MonitorCore/ValueFormatters.swift`: 状态栏文案格式化
- `Sources/SystemPulseApp/AppIconProvider.swift`: 应用图标绘制与注入
- `Sources/SystemPulseApp/MenuBarController.swift`: 状态栏 UI 与定时刷新
