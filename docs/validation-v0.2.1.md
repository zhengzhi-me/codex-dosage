# V0.2.1 本地验证记录

日期：2026-10-13（Asia/Shanghai）。本次交付为本地 Apple Silicon arm64 安装包，没有覆盖已安装应用或发布 GitHub Release。

## 改动

- Codex 用量面板改为约 420 pt 宽度；使用系统正文／说明字号，移除 ScrollView 与固定内容高度，按完整内容确定尺寸。
- 弹出面板的 NSHostingController 使用 preferredContentSize，随数据与折叠状态调整高度。
- 关闭按钮采用不接受键盘焦点的原生 NSButton，去掉焦点环；打开面板时清除默认第一响应者，保留 Escape 关闭。
- 左上角显示 Codex；当前只有一个数据来源，没有加入不可操作的扩展菜单。
- 设置页宽度缩至 360 pt，应用发现模式改为“自动／手动”，默认自动；自动显示实际应用包路径，手动才显示选择按钮。
- 手动地址在切回自动时保留。旧版已保存手动地址的设置继续按手动模式工作。
- “菜单栏样式”改为“样式”。CLI 同步遵循发现模式。

## 验证

- Node 自动测试 8 项通过；Swift Testing 9 项通过，包括默认模式、旧设置兼容、自动／手动切换及嵌套应用包路径解析。
- 固定数据的同一 UsagePanel 视图在独立原生预览窗口中检查：中文浅色、英文深色均完整展示两项额度与三张卡片，没有滚动区域或截断；关闭按钮没有蓝色选中框，辅助功能树初始焦点为窗口。
- 设置页截图确认宽度缩小，自动显示 `/Applications/ChatGPT.app` 且没有选择按钮；实际点击切至手动后显示选择按钮。
- Release 构建和 ZIP 完成；解压到临时目录后，通过 `codesign --verify --deep --strict`，应用的 `--once` 成功读取真实用量。
- `git diff --check` 通过。

界面检查使用与真实弹出面板相同的视图，采用独立窗口避免瞬时弹出面板被自动化工具激活关闭。实际菜单栏弹出面板的屏幕边缘定位和点击外部关闭未在本轮重新自动化验收。固定数据检查包含三张卡片；没有验证极大量卡片超出屏幕高度的场景。

## 包与复现

安装包：`dist/CodexUsageStatus-0.2.1-macos-arm64.zip`

SHA-256：`e4272b75db2771307e647c574725cd6f4b54ac914df14fd7fbe7b7ba0b43d130`

```sh
npm test
DEVELOPER_DIR=/Library/Developer/CommandLineTools npm run test:macos
DEVELOPER_DIR=/Library/Developer/CommandLineTools npm run package:macos
```

独立原生预览窗口：

```sh
CODEX_USAGE_DEMO=1 CODEX_USAGE_LANGUAGE=zh CODEX_USAGE_PREVIEW=panel dist/CodexUsageStatus.app/Contents/MacOS/CodexUsageStatus
CODEX_USAGE_DEMO=1 CODEX_USAGE_LANGUAGE=en CODEX_USAGE_THEME=dark CODEX_USAGE_PREVIEW=panel dist/CodexUsageStatus.app/Contents/MacOS/CodexUsageStatus
```

预览参数只在固定数据模式下生效，不改变系统外观，也不请求后端。当前仍保留 macOS 13 最低目标；本机运行环境为 macOS 27。Intel 与 macOS 13 实机尚未验收。
