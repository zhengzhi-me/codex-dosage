import Foundation

struct RateLimitsResponse: Decodable, Sendable {
    let rateLimits: RateLimitSnapshot?
    let rateLimitsByLimitId: [String: RateLimitSnapshot]?
    let rateLimitResetCredits: ResetCredits?
}
struct RateLimitSnapshot: Decodable, Sendable {
    let limitId: String?
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
    let planType: String?
    let credits: CreditBalance?
}
struct CreditBalance: Decodable, Sendable {
    let hasCredits: Bool?
    let unlimited: Bool?
    let balance: String?
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        hasCredits = try c.decodeIfPresent(Bool.self, forKey: .hasCredits)
        unlimited = try c.decodeIfPresent(Bool.self, forKey: .unlimited)
        if let string = try? c.decode(String.self, forKey: .balance) { balance = string }
        else if let number = try? c.decode(Double.self, forKey: .balance) { balance = String(number) }
        else { balance = nil }
    }
    enum Keys: String, CodingKey { case hasCredits, unlimited, balance }
}
struct ResetCredits: Decodable, Sendable {
    let availableCount: Int
    let credits: [ResetCredit]?
    var sorted: [ResetCredit] { (credits ?? []).sorted { ($0.expiresAt ?? .greatestFiniteMagnitude) < ($1.expiresAt ?? .greatestFiniteMagnitude) } }
}
struct ResetCredit: Decodable, Sendable, Identifiable {
    let id: String
    let resetType: String
    let status: String
    let grantedAt: TimeInterval?
    let expiresAt: TimeInterval?
    let title: String?
    let description: String?
    var displayTitle: String {
        resetType == "codexRateLimits" ? L.text("完全重置（每周 + 5 小时）", "Full reset (Weekly + 5 hr)") : title ?? resetType
    }
    var expiration: String {
        guard let expiresAt else { return L.text("到期时间未知", "Expiration unknown") }
        let value = L.date(Date(timeIntervalSince1970: expiresAt), format: "M/d 'GMT'XXX HH:mm")
        return L.text("将于 \(value) 到期", "Expires \(value)")
    }
}
struct RateLimitWindow: Decodable, Sendable {
    let usedPercent: Double?
    let windowDurationMins: Double?
    let resetsAt: TimeInterval?
}
struct UsageSummary: Sendable {
    let planType: String?
    let fiveHour: UsageWindow
    let weekly: UsageWindow
    let resetCredits: ResetCredits?
    let credits: CreditBalance?

    init(response: RateLimitsResponse) throws {
        // Never choose an arbitrary metered bucket and mislabel it as Codex.
        guard let snapshot = response.rateLimitsByLimitId?["codex"] ?? response.rateLimits else { throw FetchError.invalidOutput }
        let windows = [snapshot.primary, snapshot.secondary].compactMap { $0 }.map(UsageWindow.init)
        fiveHour = windows.first { $0.windowDurationMins.map { abs($0 - 300) <= 1 } ?? false }
            ?? (snapshot.primary?.windowDurationMins == nil ? snapshot.primary.map(UsageWindow.init) : nil) ?? .unknown
        weekly = windows.first { $0.windowDurationMins.map { abs($0 - 10080) <= 1 } ?? false }
            ?? (snapshot.secondary?.windowDurationMins == nil ? snapshot.secondary.map(UsageWindow.init) : nil) ?? .unknown
        planType = snapshot.planType; resetCredits = response.rateLimitResetCredits; credits = snapshot.credits
    }
    var verboseTitle: String { L.text("用量", "Usage") + ": 5h \(fiveHour.percentText) · 7d \(weekly.percentText)" }
    func tooltip(formatter: DateFormatter) -> String {
        "\(L.text("用量", "Usage"))\n\(L.text("5 小时剩余", "5-hour remaining")): \(fiveHour.percentText) · \(L.reset(fiveHour.resetsAt, weekly: false))\n\(L.text("每周剩余", "Weekly remaining")): \(weekly.percentText) · \(L.reset(weekly.resetsAt, weekly: true))"
    }
}
struct UsageWindow: Sendable {
    let remainingPercent: Int?
    let windowDurationMins: Double?
    let resetsAt: Date?
    static var unknown: UsageWindow { UsageWindow(RateLimitWindow(usedPercent: nil, windowDurationMins: nil, resetsAt: nil)) }
    var percentText: String { remainingPercent.map { "\($0)%" } ?? "--" }
    init(_ window: RateLimitWindow) {
        remainingPercent = window.usedPercent.flatMap { $0.isFinite ? min(100, max(0, Int((100 - min(100, max(0, $0))).rounded()))) : nil }
        windowDurationMins = window.windowDurationMins
        resetsAt = window.resetsAt.map { Date(timeIntervalSince1970: $0) }
    }
}
