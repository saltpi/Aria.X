# AriaX

[English](README.md) | 简体中文

![AriaX Screenshot 1](images/screenshot1.png)

---

## AriaX：Apple 用户的终极下载管理器

AriaX 是一款专为 Apple 生态（macOS 与 iOS）打造的现代化、高性能下载管理器。我们使用 **SwiftUI** 从零开始构建，旨在将 `aria2` 强大的全协议下载能力与原生 App 的极致优雅完美结合。

![AriaX Screenshot 2](images/screenshot2.png)

### 为什么选择 AriaX？

*   **原生与现代**: 完全基于 SwiftUI 开发，拥有丝滑的交互体验和完美的系统集成感，适配最新的 macOS 与 iOS 特性。
*   **零配置上手（完整版）**: 内置预配置的 `aria2` 核心引擎。无需打开终端，无需研究配置文件，安装即用。
*   **双重管理模式**: 既可以作为本地下载器，也可以通过 JSON-RPC 远程管理您的 NAS 或服务器上的下载任务。
*   **深度系统集成**:
    *   **Safari 浏览器扩展**: 官方提供的 Safari 插件，支持一键推送任务。
    *   **智能 URL Scheme**: 支持 `ariax://` 协议，方便与其他自动化工具联动。
*   **全球化支持**: 完整支持中（简/繁）、英、日、德、法等 10 多种主流语言。
*   **双版本策略**:
    *   **AriaX (完整版)**: 内置下载引擎，通过官网 DMG 分发，性能最强。
    *   **AriaX Lite**: 纯远程管理客户端，可通过 **Mac App Store** 安全下载。

### 安装指南

1.  **AriaX (完整版)**: 从官方渠道下载 `.dmg` 安装包。该版本内置了完整的下载引擎，开箱即用。
2.  **AriaX Lite**: 在 **Mac App Store** 搜索 "AriaX" 下载。适合已有远程 `aria2` 服务的老用户。

### 浏览器集成

通过以下步骤开启 Safari 插件，提升下载效率：
1.  打开 **AriaX** -> **设置** -> **浏览器集成**。
2.  点击 **启用 Safari 扩展** 按钮。
3.  在弹出的 Safari 设置中勾选 **AriaX Extension**。
4.  之后在 Safari 中右键点击任何链接，即可看到“通过 AriaX 下载”选项。

### 隐私与安全

AriaX 始终将用户隐私放在首位。我们不会收集您的下载历史、敏感配置或服务器凭据。所有数据均存储在您的本地设备上，或在您开启同步后存储于您的私有 iCloud 容器中。

---

© 2026 AriaX. All rights reserved.
