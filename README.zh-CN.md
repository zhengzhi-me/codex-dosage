# Codex Dosage

<img src="assets/logo.svg" width="96" alt="Codex Dosage 图标" />

[English](README.md) · 简体中文

轻量的 macOS 菜单栏 Codex 用量工具：随时查看 5 小时与每周剩余额度、重置时间、可用额度重置卡及积分余额。

基于 [tollenceld/codex-usage-status](https://github.com/tollenceld/codex-usage-status) 修改，增加用量面板、中英文设置，以及 ChatGPT/Codex 应用包识别。本项目为独立第三方工具，与 OpenAI 无隶属、赞助或背书关系。

## 功能

- **菜单栏用量：** 双环展示 5 小时及每周剩余百分比，设置中可切换大字号样式。
- **用量面板：** 左键打开，展示进度条、重置时间、可用重置次数及卡片到期时间；接口提供余额时另行显示。右键提供设置、刷新与退出。
- **重置卡只读展示：** 不消耗卡片，也不修改账号限额。
- **应用发现：** 默认按应用包身份及内部结构自动识别 ChatGPT/Codex；切换手动后可选择自定义安装位置，支持应用改名和带空格的路径。
- **语言切换：** 跟随系统、简体中文、English，即时生效并保存选择。
- **自动刷新：** 默认每 120 秒刷新，失败后 300 秒重试；保留上次成功数据及更新时间。缺失用量显示未知。
- **原生界面：** AppKit/SwiftUI 悬浮面板，紧凑系统字号、深色模式，以及终端与用量组合图标。

## 界面预览

### 用量面板

<img src="docs/assets/usage-panel.png" width="472" alt="Codex 用量、重置卡和余额面板" />

### 设置：自动发现与手动选择

<img src="docs/assets/settings-automatic.png" width="360" alt="自动发现应用的设置页面" />
<img src="docs/assets/settings-manual.png" width="360" alt="手动选择应用的设置页面" />

截图展示示例账号数据，实际额度、重置卡、日期和余额以接口返回为准。

## 安装 V0.1.0

从 [Releases](https://github.com/zhengzhi-me/codex-dosage/releases) 下载 [Codex-Dosage-0.1.0-macos-arm64.zip](https://github.com/zhengzhi-me/codex-dosage/releases/download/V0.1.0/Codex-Dosage-0.1.0-macos-arm64.zip)。

1. 退出旧版，解压后将 **Codex Dosage.app** 移到“应用程序”目录。
2. 打开应用；它仅显示在菜单栏，不显示 Dock 图标。
3. 在官方 ChatGPT/Codex 应用中登录；自动发现失败时切换手动选择。

需要 **macOS 13+** 和受支持的官方桌面应用。本次提供 **Apple Silicon（arm64）** 安装包；Intel 用户可自行从源码构建，V0.1.0 未提供或运行验证 Intel 安装包。

当前为本地 ad-hoc 签名，未经过 Apple 公证，下载后 macOS 可能提示安全警告。原有设置保留；如曾添加旧版登录项，请改为新应用。

## 数据来源与隐私

通过官方应用包自带的 `app-server`，经本机标准输入／输出调用 `account/rateLimits/read`。本工具不抓取屏幕、不读取认证文件、不发送遥测。**官方 app-server 获取最新账号信息时可能联网，本地接口不等于完全离线。** 刷新失败时保留最近成功的数据。

重置卡和余额取决于官方接口返回的字段。不提供消耗卡片、购买积分、切换账号或登录操作。详见 [PRIVACY.md](PRIVACY.md) 和 [SECURITY.md](SECURITY.md)。

## 源码构建与命令行

需要 Swift 6+／Xcode Command Line Tools；Node.js 20+ 用于测试及可选 CLI。

```sh
npm test
npm run test:macos
npm run build:macos
npm run start:macos
```

应用生成于 `dist/Codex Dosage.app`。运行 `npm run package:macos` 打包；设置 `BUILD_ARCH=x86_64` 可构建 Intel 版本。使用独立命令行工具时，可指定 `DEVELOPER_DIR=/Library/Developer/CommandLineTools`。如提示 Xcode 许可，请由用户本人阅读并接受。

```sh
npm run usage -- --lang=zh
npm run usage:json
npm run usage -- --app="/Applications/ChatGPT.app"
```

开发覆盖选项：`CODEX_BIN` 指定可执行文件，`CODEX_APP` 指定应用包，`CODEX_USAGE_REFRESH_SECONDS` 设置刷新间隔（最少 60 秒）。固定数据模式需显式启用 `CODEX_USAGE_DEMO=1`，正常运行读取真实账号数据。

## 来源与许可证

- 原项目：[tollenceld/codex-usage-status](https://github.com/tollenceld/codex-usage-status)，保留原版权声明与完整 [MIT 许可证](LICENSE)。
- 应用图标：用户提供 SVG／PNG，终端符号参考并改编自 [Lucide terminal](https://lucide.dev/icons/terminal)，相关 ISC／MIT 声明见 [licenses/Lucide-LICENSE](licenses/Lucide-LICENSE)。
- 本次改动：应用发现、中英文界面、用量与重置卡面板、刷新状态、图标和安装包。

OpenAI、ChatGPT、Codex 等名称及商标归各自权利人所有。此前本地开发版本记录在 [开发历史](docs/development-history.md)；独立 Codex Dosage 发布序列从 **V0.1.0** 开始。
