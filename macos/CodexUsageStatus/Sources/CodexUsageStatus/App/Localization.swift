import Foundation

enum AppLanguage: String, CaseIterable { case system, zh, en }
enum L {
    static var language: AppLanguage {
        if ProcessInfo.processInfo.environment["CODEX_USAGE_DEMO"] == "1", let value = ProcessInfo.processInfo.environment["CODEX_USAGE_LANGUAGE"], let language = AppLanguage(rawValue: value) { return language }
        return AppLanguage(rawValue: UserDefaults.standard.string(forKey: "AppLanguage") ?? "system") ?? .system
    }
    static var chinese: Bool { language == .zh || (language == .system && (Locale.preferredLanguages.first ?? "en").hasPrefix("zh")) }
    static var locale: Locale { Locale(identifier: chinese ? "zh_CN" : "en_US") }
    static func text(_ zh: String, _ en: String) -> String { chinese ? zh : en }
    static func date(_ date: Date?, format: String) -> String {
        guard let date else { return text("未知", "Unknown") }
        let formatter = DateFormatter(); formatter.locale = locale; formatter.timeZone = .current; formatter.dateFormat = format
        return formatter.string(from: date)
    }
    static func reset(_ date: Date?, weekly: Bool) -> String {
        guard let date else { return text("重置时间未知", "Reset time unknown") }
        let value = self.date(date, format: weekly ? (chinese ? "M月d日" : "MMM d") : "HH:mm")
        return text("将于 \(value) 重置", "Resets at \(value)")
    }
}
