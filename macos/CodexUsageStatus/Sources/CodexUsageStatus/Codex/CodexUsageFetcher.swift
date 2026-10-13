import Darwin
import Foundation

enum CodexUsageFetcher {
    static func fetch(binary: URL) async throws -> UsageSummary {
        try await Task.detached(priority: .utility) {
            try fetchSync(binary: binary)
        }.value
    }

    static func fetchSync(binary: URL) throws -> UsageSummary {
        let response = try readRateLimits(binary: binary)
        return try UsageSummary(response: response)
    }

    private static func readRateLimits(binary: URL) throws -> RateLimitsResponse {
        let codexPath = binary.path
        guard FileManager.default.isExecutableFile(atPath: codexPath) else {
            throw FetchError.codexNotFound(codexPath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: codexPath)
        process.arguments = ["app-server", "--listen", "stdio://"]

        let standardInput = Pipe()
        let standardOutput = Pipe()
        let standardError = Pipe()

        process.standardInput = standardInput
        process.standardOutput = standardOutput
        process.standardError = standardError

        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            finished.signal()
        }

        let responseBox = ResponseBox()
        standardError.fileHandleForReading.readabilityHandler = { handle in _ = handle.availableData }
        standardOutput.fileHandleForReading.readabilityHandler = { handle in
            responseBox.append(handle.availableData)
        }

        do {
            try process.run()
        } catch {
            standardError.fileHandleForReading.readabilityHandler = nil
            standardOutput.fileHandleForReading.readabilityHandler = nil
            throw error
        }

        let requestLines = [
            #"{"method":"initialize","id":1,"params":{"clientInfo":{"name":"codex_usage_status_menubar","title":"Codex Dosage","version":"0.1.0"},"capabilities":{"experimentalApi":true}}}"#,
            #"{"method":"initialized"}"#,
            #"{"method":"account/rateLimits/read","id":2}"#
        ].joined(separator: "\n") + "\n"

        standardInput.fileHandleForWriting.write(Data(requestLines.utf8))

        if responseBox.wait(timeout: .now() + AppConfig.appServerTimeout) == .timedOut {
            standardOutput.fileHandleForReading.readabilityHandler = nil
            standardInput.fileHandleForWriting.closeFile()
            terminateProcess(process, finished: finished)
            throw FetchError.timeout
        }

        standardOutput.fileHandleForReading.readabilityHandler = nil
        standardInput.fileHandleForWriting.closeFile()
        terminateProcess(process, finished: finished)
        _ = standardError.fileHandleForReading.readDataToEndOfFile()

        switch responseBox.result() {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        case .none:
            throw FetchError.missingRateLimitResponse
        }
    }

    private static func terminateProcess(_ process: Process, finished: DispatchSemaphore) {
        guard process.isRunning else {
            return
        }
        process.terminate()
        if finished.wait(timeout: .now() + 1) == .timedOut, process.isRunning {
            kill(process.processIdentifier, SIGKILL)
            _ = finished.wait(timeout: .now() + 1)
        }
    }
}

final class ResponseBox: @unchecked Sendable {
    private let lock = NSLock()
    private let semaphore = DispatchSemaphore(value: 0)
    private var buffer = Data()
    private var storedResult: Result<RateLimitsResponse, Error>?

    func append(_ data: Data) {
        guard !data.isEmpty else {
            return
        }

        lock.lock()
        defer { lock.unlock() }

        if storedResult != nil {
            return
        }

        buffer.append(data)
        while let newline = buffer.firstIndex(of: 10) {
            let line = String(decoding: buffer[..<newline], as: UTF8.self)
            buffer.removeSubrange(...newline)

            do {
                if let response = try Self.parseRateLimitsLine(line) {
                    storedResult = .success(response)
                    semaphore.signal()
                    return
                }
            } catch {
                storedResult = .failure(error)
                semaphore.signal()
                return
            }
        }
    }

    func wait(timeout: DispatchTime) -> DispatchTimeoutResult {
        semaphore.wait(timeout: timeout)
    }

    func result() -> Result<RateLimitsResponse, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return storedResult
    }

    private static func parseRateLimitsLine(_ line: String) throws -> RateLimitsResponse? {
        guard let lineData = line.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
            return nil
        }

        guard stringID(object["id"]) == "2" else {
            return nil
        }

        if object["error"] != nil {
            throw FetchError.appServerError
        }

        guard let result = object["result"] else {
            throw FetchError.invalidOutput
        }

        let resultData = try JSONSerialization.data(withJSONObject: result)
        return try JSONDecoder().decode(RateLimitsResponse.self, from: resultData)
    }

    private static func stringID(_ value: Any?) -> String? {
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }
}

enum FetchError: LocalizedError {
    case codexNotFound(String)
    case invalidApplication
    case applicationNotSelected
    case timeout
    case appServerExited(Int)
    case appServerError
    case invalidOutput
    case missingRateLimitResponse

    var errorDescription: String? {
        switch self {
        case .applicationNotSelected:
            return L.text("请选择应用安装位置", "Choose an application location")
        case .invalidApplication:
            return L.text("请选择有效的应用包", "Select a valid application bundle")
        case .codexNotFound(let path):
            return L.text("未找到 Codex 可执行文件，请重新选择应用：\(path)", "Codex executable not found. Select the application again: \(path)")
        case .timeout:
            return L.text("读取用量超时（20 秒）", "Codex app-server did not respond within 20 seconds")
        case .appServerExited(let status):
            return L.text("用量进程退出：\(status)", "Codex app-server exited with status \(status)")
        case .appServerError:
            return L.text("用量读取失败，请确认已在官方应用中登录", "Codex app-server returned an error")
        case .invalidOutput:
            return L.text("应用返回了无法识别的用量数据", "Codex app-server returned unexpected usage data")
        case .missingRateLimitResponse:
            return L.text("应用没有返回用量数据", "Codex app-server did not return usage data")
        }
    }
}
