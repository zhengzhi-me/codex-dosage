# V0.2.0 本地验证记录

日期：2026-10-13（Asia/Shanghai）。本轮为本地交付，没有发布 GitHub Release，也没有覆盖 `/Applications` 中的已安装版本。

## 已完成

- Node 自动测试：8 项通过，包括应用包布局、自定义路径、失效路径、额度缺失、重置卡兼容和主窗口缺失时的标签处理。
- Swift Testing：7 项通过，包括应用包更新后的重新解析、用量数据、余额、重置卡和 UTF-8 分片响应。
- 最终 arm64 Release 构建、ad-hoc 签名与 ZIP 打包完成。
- 安装 ZIP 在临时目录解压后，通过 `codesign --verify --deep --strict`；解压应用的 `--once` 成功读取真实账号用量。
- Node CLI 自动识别本机 ChatGPT.app，中文输出显示真实用量、3 张重置卡到期时间和接口余额。
- 原生界面的辅助功能树确认真实用量、3 张卡及到期时间；设置页截图确认中文排版、应用路径和语言／样式选择器。
- 固定数据模式提供 82%／87%／3 张卡，支持独立指定浅色、深色及显示语言，不请求后端、不写入语言偏好。
- 项目位于 iCloud 工作区，生成 `.app` 的 Finder 扩展属性可能影响签名验证；构建清理生成物属性，ZIP 排除扩展属性，并以解压产物验证签名。

## 验收边界

自动化工具在访问瞬时弹出面板时超时，语言菜单操作也出现状态失效。因此不能把中英文即时切换、深色面板、点击外部关闭、Escape、折叠和滚动全部报告为人工验收通过；代码已实现，需要实际点击验收。没有宣称与参考截图逐像素一致。

本次交付仅构建并运行验证 Apple Silicon arm64。保留 Intel 打包能力，但没有完成 Intel 构建和运行验证。声明最低 macOS 13，当前实机验证环境为 macOS 27，没有在 macOS 13 实机验收。

## 复现

```sh
npm test
DEVELOPER_DIR=/Library/Developer/CommandLineTools npm run test:macos
DEVELOPER_DIR=/Library/Developer/CommandLineTools npm run package:macos
npm run usage -- --lang=zh
```

需正常安装并配置 Swift 6+ 工具链。命令行工具模式的测试入口包含所需 Testing 框架与宏插件参数；完整 Xcode 环境可直接 `npm run test:macos`。

固定数据验收（先退出其他本工具实例）：

```sh
CODEX_USAGE_DEMO=1 CODEX_USAGE_LANGUAGE=zh CODEX_USAGE_THEME=dark CODEX_USAGE_SHOW_PANEL=1 dist/CodexUsageStatus.app/Contents/MacOS/CodexUsageStatus
```

`CODEX_USAGE_LANGUAGE` 和 `CODEX_USAGE_THEME` 在上述 GUI 测试模式下生效。生产界面使用设置中的语言和系统外观。

安装 ZIP：`dist/CodexUsageStatus-0.2.0-macos-arm64.zip`

SHA-256：`fd19a41b4a9e4604f7309ef3dbb3504eb1ef6afaa46f2cc776df76678b55f58b`
