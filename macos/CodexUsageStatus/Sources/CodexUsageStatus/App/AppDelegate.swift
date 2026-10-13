import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let state = UsageState()
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var previewWindow: NSWindow?
    private var timer: Timer?
    private var generation = 0
    private let refreshInterval = configuredRefreshInterval()
    private let demo = ProcessInfo.processInfo.environment["CODEX_USAGE_DEMO"] == "1"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let button = statusItem.button {
            button.target = self; button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        popover.behavior = .transient
        let hosting = NSHostingController(rootView: UsagePanel(state: state, close: { [weak self] in self?.popover.performClose(nil) }, refresh: { [weak self] in self?.refresh() }, settings: { [weak self] in self?.showSettings() }))
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting
        render()
        if demo {
            NSApp.appearance = NSAppearance(named: ProcessInfo.processInfo.environment["CODEX_USAGE_THEME"] == "dark" ? .darkAqua : .aqua)
            let data = Data(#"{"rateLimits":{"primary":{"usedPercent":18,"windowDurationMins":300,"resetsAt":1791871980},"secondary":{"usedPercent":13,"windowDurationMins":10080,"resetsAt":1792339200}},"rateLimitResetCredits":{"availableCount":3,"credits":[{"id":"demo1","resetType":"codexRateLimits","status":"available","expiresAt":1792695568},{"id":"demo2","resetType":"codexRateLimits","status":"available","expiresAt":1793293771},{"id":"demo3","resetType":"codexRateLimits","status":"available","expiresAt":1794006199}]}}"#.utf8)
            state.usage = try? UsageSummary(response: JSONDecoder().decode(RateLimitsResponse.self, from: data))
            state.updated = Date()
            if let binary = try? ApplicationResolver.resolve() {
                state.binaryPath = binary.path
                state.detectedApplicationPath = ApplicationResolver.containingApplication(binary)?.path ?? binary.path
            }
            render()
            if let preview = ProcessInfo.processInfo.environment["CODEX_USAGE_PREVIEW"] {
                if preview == "settings" { showSettings() } else { showPanelPreview() }
            } else if ProcessInfo.processInfo.environment["CODEX_USAGE_SHOW_PANEL"] == "1" {
                Task { @MainActor [weak self] in self?.clicked() }
            }
        } else { refresh() }
    }
    // Stable demo surface for visual checks; production continues to use the transient popover.
    private func showPanelPreview() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 400), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Codex · Preview"
        window.isReleasedWhenClosed = false
        let controller = NSHostingController(rootView: UsagePanel(state: state, close: { [weak self] in self?.previewWindow?.close() }, refresh: {}, settings: { [weak self] in self?.showSettings() }))
        controller.sizingOptions = [.preferredContentSize]
        window.contentViewController = controller
        window.setContentSize(controller.view.fittingSize)
        previewWindow = window
        window.center(); NSApp.activate(ignoringOtherApps: true); window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(nil)
    }
    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu(); return }
        if popover.isShown { popover.performClose(nil) }
        else if let button = statusItem.button {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            popover.contentViewController?.view.window?.makeFirstResponder(nil)
        }
    }
    private func showMenu() {
        let menu = NSMenu()
        for (title, selector) in [(L.text("刷新", "Refresh"), #selector(refreshAction)), (L.text("设置…", "Settings…"), #selector(settingsAction)), (L.text("退出", "Quit"), #selector(quit))] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: ""); item.target = self
            if selector == #selector(refreshAction) { item.isEnabled = !state.refreshing }
            menu.addItem(item)
        }
        if let button = statusItem.button { menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button) }
    }
    @objc private func refreshAction() { refresh() }
    @objc private func settingsAction() { showSettings() }
    @objc private func quit() { NSApp.terminate(nil) }
    private func showSettings() {
        popover.performClose(nil)
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 330), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: SettingsView(state: state, choose: { [weak self] in self?.chooseApplication() }, modeChanged: { [weak self] mode in self?.setDiscoveryMode(mode) }, languageChanged: { [weak self] language in
                UserDefaults.standard.set(language.rawValue, forKey: "AppLanguage")
                self?.state.language = language; self?.settingsWindow?.title = L.text("设置", "Settings"); self?.render()
            }, styleChanged: { [weak self] style in style.save(); self?.state.style = style; self?.render() }, refreshInterval: refreshInterval))
            window.center(); settingsWindow = window
        }
        settingsWindow?.title = L.text("设置", "Settings")
        NSApp.activate(ignoringOtherApps: true); settingsWindow?.makeKeyAndOrderFront(nil)
    }
    private func chooseApplication() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.applicationBundle]; panel.allowsMultipleSelection = false
        panel.message = L.text("选择包含 Codex 的 ChatGPT 或 Codex 应用", "Choose a ChatGPT or Codex application containing Codex")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { _ = try ApplicationResolver.binary(in: url); setApplication(url.path) }
        catch {
            let alert = NSAlert(); alert.messageText = L.text("无法识别应用", "Application not recognized"); alert.informativeText = error.localizedDescription; alert.runModal()
        }
    }
    private func setApplication(_ path: String) {
        UserDefaults.standard.set(path, forKey: ApplicationResolver.selectionKey)
        state.applicationPath = path
        setDiscoveryMode(.manual)
    }
    private func setDiscoveryMode(_ mode: DiscoveryMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: ApplicationResolver.modeKey)
        state.discoveryMode = mode
        generation += 1; timer?.invalidate(); state.refreshing = false
        state.usage = nil; state.updated = nil; state.failure = nil
        state.binaryPath = ""; state.detectedApplicationPath = ""
        render(); refresh()
    }
    private func refresh() {
        guard !demo, !state.refreshing else { return }
        state.refreshing = true
        let requestGeneration = generation
        Task { [weak self] in
            guard let self else { return }
            do {
                let binary = try ApplicationResolver.resolve()
                self.state.binaryPath = binary.path
                self.state.detectedApplicationPath = ApplicationResolver.containingApplication(binary)?.path ?? binary.path
                let usage = try await CodexUsageFetcher.fetch(binary: binary)
                guard requestGeneration == self.generation else { return }
                self.state.usage = usage; self.state.updated = Date(); self.state.failure = nil
                self.schedule(after: self.refreshInterval)
            } catch {
                guard requestGeneration == self.generation else { return }
                self.state.failure = error
                self.schedule(after: AppConfig.errorRetryInterval)
            }
            self.state.refreshing = false; self.render()
        }
    }
    private func schedule(after seconds: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }
    private func render() {
        statusItem.length = UsageBadgeRenderer.statusItemLength(for: state.style)
        guard let button = statusItem.button else { return }
        button.title = ""; button.imagePosition = .imageOnly
        if let usage = state.usage {
            button.image = UsageBadgeRenderer.image(for: usage, style: state.style, appearance: button.effectiveAppearance)
            button.toolTip = usage.tooltip(formatter: DateFormatter()) + (state.error.map { "\n" + $0 } ?? "")
        } else if let error = state.error {
            button.image = UsageBadgeRenderer.errorImage(style: state.style, appearance: button.effectiveAppearance); button.toolTip = error
        } else {
            button.image = UsageBadgeRenderer.placeholderImage(style: state.style, appearance: button.effectiveAppearance)
            button.toolTip = L.text("等待首次刷新", "Waiting for first refresh")
        }
        button.setAccessibilityLabel(button.toolTip)
    }
}
