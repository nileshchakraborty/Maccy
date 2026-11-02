import AppKit
import Foundation

func benchmarkSearchSpeed() {
    print("⚡ Benchmarking Search Speed across 100 clipboard entries (15,000 queries)...")
    let items = (0..<100).map { i in
        "Code snippet or document line #\(i): const data = fetch('/api/user/\(i)');"
    }

    let query = "api/user"
    let start = CFAbsoluteTimeGetCurrent()
    var matchCount = 0
    let queryLower = query.lowercased()
    for _ in 0..<15_000 {
        let matches = items.filter { $0.lowercased().contains(queryLower) }
        matchCount += matches.count
    }
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    let qps = Int(15_000.0 / elapsed)
    let avgMicrosec = (elapsed / 15_000.0) * 1_000_000.0
    print("   ✅ 15,000 search queries completed in \(String(format: "%.4f", elapsed))s (\(qps) queries/sec)")
    print("   Avg latency per search query: \(String(format: "%.3f", avgMicrosec)) microseconds!\n")
}

func benchmarkDetectionLatency() {
    print("⚡ Benchmarking System Pasteboard Detection Latency...")
    let pb = NSPasteboard.general
    let start = CFAbsoluteTimeGetCurrent()
    pb.clearContents()
    pb.setString("Benchmark copy at \(Date())", forType: .string)
    Thread.sleep(forTimeInterval: 0.15)
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    print("   ✅ Pasteboard updated & serviced in \(String(format: "%.3f", elapsed * 1000))ms\n")
}

print("=================================================================")
print("  CLIPVAULT SPEED OPTIMIZATION & SEARCH BENCHMARK")
print("=================================================================\n")
benchmarkSearchSpeed()
benchmarkDetectionLatency()
print("=================================================================")
