import AppKit
import SwiftUI

@MainActor
final class UsageState: ObservableObject {
    @Published var usage: UsageSummary?
    @Published var refreshing = false
    @Published var failure: Error?
    var error: String? { failure?.localizedDescription }
    @Published var updated: Date?
    @Published var language = L.language
    @Published var style = BadgeStyle.load()
    @Published var discoveryMode = ApplicationResolver.mode()
    @Published var applicationPath = UserDefaults.standard.string(forKey: ApplicationResolver.selectionKey) ?? ""
    @Published var detectedApplicationPath = ""
    @Published var binaryPath = ""
    @Published var expanded = true
}

struct UsagePanel: View {
    @ObservedObject var state: UsageState
    var close: () -> Void
    var refresh: () -> Void
    var settings: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Provider title stays separate from quota labels for future source selection.
                Text("Codex").font(.headline)
                Spacer()
                HeaderCloseButton(action: close).frame(width: 20, height: 20)
            }
            VStack(spacing: 0) {
                quota(L.text("5 小时使用限额", "5-hour usage limit"), window: state.usage?.fiveHour ?? .unknown, weekly: false)
                Divider()
                quota(L.text("每周使用限额", "Weekly usage limit"), window: state.usage?.weekly ?? .unknown, weekly: true)
            }.card()
            VStack(spacing: 0) {
                Button { state.expanded.toggle() } label: {
                    HStack {
                        Text(L.text("使用限额重置", "Usage limit resets")).fontWeight(.semibold)
                        Spacer()
                        if let count = state.usage?.resetCredits?.availableCount {
                            Text(L.text("可用 \(count) 次", "\(count) available"))
                                .foregroundStyle(Color(nsColor: .systemGreen))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.green.opacity(0.13), in: Capsule())
                        }
                        Image(systemName: state.expanded ? "chevron.up" : "chevron.down").font(.caption)
                    }.padding(12).contentShape(Rectangle())
                }.buttonStyle(.plain)
                if state.expanded {
                    if let cards = state.usage?.resetCredits {
                        if cards.availableCount == 0 {
                            notice(L.text("暂无可用重置卡", "No resets available"))
                        } else if cards.credits == nil || cards.credits?.isEmpty == true {
                            notice(L.text("已读取可用次数，暂无卡片详情", "Available count loaded; card details unavailable"))
                        } else {
                            ForEach(cards.sorted) { card in
                                Divider()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.displayTitle).fontWeight(.medium)
                                    Text(card.expiration).foregroundStyle(.secondary).font(.caption)
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
                            }
                            if cards.availableCount > (cards.credits?.count ?? 0) {
                                notice(L.text("仅显示接口返回的部分卡片", "Only some card details were returned"))
                            }
                        }
                    } else { notice(L.text("暂无重置卡信息", "Reset information unavailable")) }
                }
            }.card()
            if let credit = state.usage?.credits, credit.unlimited == true || credit.balance != nil {
                HStack {
                    Text(L.text("积分余额", "Credit balance")).fontWeight(.medium)
                    Spacer()
                    Text(credit.unlimited == true ? L.text("不限量", "Unlimited") : credit.balance ?? "--")
                }.padding(12).card()
            }
            if let error = state.error {
                Text(error).foregroundStyle(.red).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Text(state.updated.map { L.text("更新于 ", "Updated ") + L.date($0, format: "MM/dd HH:mm:ss") } ?? L.text("等待首次刷新", "Waiting for first refresh"))
                    .foregroundStyle(.secondary).font(.caption)
                Spacer()
                Button(action: settings) {
                    Text(L.text("设置", "Settings"))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                }.buttonStyle(.bordered)
                Button(action: refresh) {
                    Text(state.refreshing ? L.text("刷新中…", "Refreshing…") : L.text("刷新", "Refresh"))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                }.buttonStyle(.bordered).disabled(state.refreshing)
            }
        }.padding(16).frame(width: 420).font(.body).controlSize(.small)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(nsColor: .windowBackgroundColor))
            .onExitCommand(perform: close)
    }
    private func notice(_ text: String) -> some View {
        Text(text).foregroundStyle(.secondary).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(12)
    }
    private func quota(_ title: String, window: UsageWindow, weekly: Bool) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).fontWeight(.medium)
                Text(L.reset(window.resetsAt, weekly: weekly)).foregroundStyle(.secondary).font(.caption)
            }.frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.1))
                    Capsule().fill(Color.primary).frame(width: proxy.size.width * CGFloat(window.remainingPercent ?? 0) / 100)
                }
            }.frame(width: 100, height: 6)
            Text(L.text("剩余 ", "Remaining ") + window.percentText).foregroundStyle(.secondary).monospacedDigit()
                .fixedSize().frame(minWidth: 64, alignment: .trailing)
        }.padding(12)
    }
}

// Keep the close control accessible without making it the initial keyboard target.
private struct HeaderCloseButton: NSViewRepresentable {
    var action: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(action: action) }
    func makeNSView(context: Context) -> CloseButton {
        let button = CloseButton()
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: L.text("关闭", "Close"))
        button.imageScaling = .scaleProportionallyDown
        button.focusRingType = .none
        button.target = context.coordinator
        button.action = #selector(Coordinator.close)
        return button
    }
    func updateNSView(_ button: CloseButton, context: Context) {
        context.coordinator.action = action
        button.toolTip = L.text("关闭", "Close")
        button.setAccessibilityLabel(L.text("关闭", "Close"))
    }
    final class CloseButton: NSButton {
        override var acceptsFirstResponder: Bool { false }
    }
    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func close() { action() }
    }
}
private extension View {
    func card() -> some View {
        self.background(Color(nsColor: .controlBackgroundColor)).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.09), lineWidth: 1))
    }
}

struct SettingsView: View {
    @ObservedObject var state: UsageState
    var choose: () -> Void
    var modeChanged: @MainActor @Sendable (DiscoveryMode) -> Void
    var languageChanged: @MainActor @Sendable (AppLanguage) -> Void
    var styleChanged: @MainActor @Sendable (BadgeStyle) -> Void
    var refreshInterval: TimeInterval
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.text("设置", "Settings")).font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                Text(L.text("应用安装位置", "Application location")).fontWeight(.medium)
                Picker(L.text("发现方式", "Discovery"), selection: Binding(get: { state.discoveryMode }, set: modeChanged)) {
                    Text(L.text("自动", "Automatic")).tag(DiscoveryMode.automatic)
                    Text(L.text("手动", "Manual")).tag(DiscoveryMode.manual)
                }.pickerStyle(.segmented).labelsHidden()
                let path = state.discoveryMode == .automatic ? state.detectedApplicationPath : state.applicationPath
                Text(path.isEmpty ? L.text("尚未选择或识别到应用", "No application selected or detected") : path)
                    .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                if state.discoveryMode == .manual {
                    Button(L.text("选择应用…", "Choose application…"), action: choose)
                }
            }
            Divider()
            Picker(L.text("语言", "Language"), selection: Binding(get: { state.language }, set: languageChanged)) {
                Text(L.text("跟随系统", "System default")).tag(AppLanguage.system)
                Text("简体中文").tag(AppLanguage.zh)
                Text("English").tag(AppLanguage.en)
            }
            Picker(L.text("样式", "Style"), selection: Binding(get: { state.style }, set: styleChanged)) {
                ForEach(BadgeStyle.allCases, id: \.self) { Text($0.menuTitle).tag($0) }
            }
            Text(L.text("刷新间隔：\(Int(refreshInterval)) 秒；失败后 300 秒重试。", "Refresh: \(Int(refreshInterval)) seconds; retry after 300 seconds on failure."))
                .font(.caption).foregroundStyle(.secondary)
            Text(L.text("数据由官方应用的本地接口只读提供。", "Read-only data from the official application's local interface."))
                .font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(width: 360).font(.body).fixedSize(horizontal: false, vertical: true)
    }
}
