import Foundation
import Testing
@testable import CodexUsageStatus

struct UsageTests {
    private func usage(_ json: String) throws -> UsageSummary { try UsageSummary(response: JSONDecoder().decode(RateLimitsResponse.self, from: Data(json.utf8))) }
    @Test func testUnknownDoesNotBecomeFull() throws {
        let value = try usage(#"{"rateLimits":{"primary":{},"secondary":{"usedPercent":13,"windowDurationMins":10080}}}"#)
        XCTAssertNil(value.fiveHour.remainingPercent); XCTAssertEqual(value.weekly.remainingPercent, 87)
    }
    @Test func testCodexBucketAndClamping() throws {
        let value = try usage(#"{"rateLimits":{"primary":{"usedPercent":90}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":18,"windowDurationMins":300},"secondary":{"usedPercent":-10,"windowDurationMins":10080}}}}"#)
        XCTAssertEqual(value.fiveHour.remainingPercent, 82); XCTAssertEqual(value.weekly.remainingPercent, 100)
    }
    @Test func testUnrelatedBucketIsRejected() { XCTAssertThrowsError(try usage(#"{"rateLimitsByLimitId":{"other":{}}}"#)) }
    @Test func testCardStatesAndAuthoritativeCount() throws {
        XCTAssertNil(try usage(#"{"rateLimits":{}}"#).resetCredits)
        XCTAssertNil(try usage(#"{"rateLimits":{},"rateLimitResetCredits":{"availableCount":3,"credits":null}}"#).resetCredits?.credits)
        XCTAssertEqual(try usage(#"{"rateLimits":{},"rateLimitResetCredits":{"availableCount":0,"credits":[]}}"#).resetCredits?.credits?.count, 0)
        let value = try usage(#"{"rateLimits":{},"rateLimitResetCredits":{"availableCount":3,"credits":[{"id":"b","resetType":"codexRateLimits","status":"available","expiresAt":null},{"id":"a","resetType":"codexRateLimits","status":"available","expiresAt":42}]}}"#)
        XCTAssertEqual(value.resetCredits?.availableCount, 3); XCTAssertEqual(value.resetCredits?.sorted.map(\.id), ["a", "b"])
    }
    @Test func testBalanceSupportsStringAndNumber() throws {
        XCTAssertEqual(try usage(#"{"rateLimits":{"credits":{"balance":"123.45"}}}"#).credits?.balance, "123.45")
        XCTAssertEqual(try usage(#"{"rateLimits":{"credits":{"balance":123.45}}}"#).credits?.balance, "123.45")
    }
    @Test func testApplicationLayoutsAndReResolution() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("Renamed App.app")
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents"), withIntermediateDirectories: true)
        let plist: [String: Any] = ["CFBundleIdentifier": "com.openai.codex", "CFBundlePackageType": "APPL", "CFBundleName": "Renamed App"]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0).write(to: app.appendingPathComponent("Contents/Info.plist"))
        for relative in ApplicationResolver.candidates {
            let path = app.appendingPathComponent(relative)
            try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("#!/bin/sh\n".utf8).write(to: path)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path.path)
            XCTAssertEqual(try ApplicationResolver.binary(in: app), path)
            try FileManager.default.removeItem(at: path)
        }
        XCTAssertThrowsError(try ApplicationResolver.binary(in: app))
        XCTAssertThrowsError(try ApplicationResolver.binary(in: root))
    }
    @Test func testDiscoveryModeDefaultsAndMigration() {
        let name = "UsageTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        XCTAssertEqual(ApplicationResolver.mode(defaults: defaults), .automatic)
        defaults.set("/Custom App.app", forKey: ApplicationResolver.selectionKey)
        XCTAssertEqual(ApplicationResolver.mode(defaults: defaults), .manual)
        defaults.set("automatic", forKey: ApplicationResolver.modeKey)
        XCTAssertEqual(ApplicationResolver.mode(defaults: defaults), .automatic)
        XCTAssertEqual(defaults.string(forKey: ApplicationResolver.selectionKey), "/Custom App.app")
        defaults.set("manual", forKey: ApplicationResolver.modeKey)
        XCTAssertEqual(ApplicationResolver.mode(defaults: defaults), .manual)
    }
    @Test func testOuterApplicationPath() {
        let binary = URL(fileURLWithPath: "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex")
        XCTAssertEqual(ApplicationResolver.containingApplication(binary)?.path, "/Applications/ChatGPT.app")
        XCTAssertNil(ApplicationResolver.containingApplication(URL(fileURLWithPath: "/usr/local/bin/codex")))
    }
    @Test func testSplitUnicodeResponse() throws {
        let data = Data(#"{"id":2,"result":{"rateLimits":{"planType":"中文"}}}"#.utf8) + Data([10])
        let box = ResponseBox()
        for byte in data { box.append(Data([byte])) }
        guard case .success(let response) = box.result() else { return XCTFail("Split JSON response not decoded") }
        XCTAssertEqual(response.rateLimits?.planType, "中文")
    }
}

private func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T) { #expect(actual == expected) }
private func XCTAssertNil<T>(_ value: T?) { #expect(value == nil) }
private func XCTFail(_ message: String) { Issue.record(Comment(rawValue: message)) }
private func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T) {
    do { _ = try expression(); Issue.record("Expected an error") } catch {}
}
