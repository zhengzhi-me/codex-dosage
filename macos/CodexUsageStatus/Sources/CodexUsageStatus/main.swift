import AppKit
import Foundation

if CommandLine.arguments.contains("--once") {
    do {
        let usage = try CodexUsageFetcher.fetchSync(binary: ApplicationResolver.resolve())
        print(usage.verboseTitle)
        exit(0)
    } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
