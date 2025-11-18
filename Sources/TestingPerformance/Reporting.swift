// Reporting.swift
// TestingPerformance
//
// Performance test reporting and formatting

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TestingPerformance {
    /// Print a performance measurement summary
    ///
    /// Example:
    /// ```swift
    /// let measurement = TestingPerformance.measure(iterations: 100) { operation() }
    /// TestingPerformance.printPerformance("Operation Name", measurement)
    /// ```
    public static func printPerformance(
        _ name: String,
        _ measurement: TestingPerformance.Measurement,
        allocations: [Int]? = nil
    ) {
        var output = """
            ⏱️ \(name)
               Iterations: \(measurement.durations.count)
               Min:        \(formatDuration(measurement.min))
               Median:     \(formatDuration(measurement.median))
               Mean:       \(formatDuration(measurement.mean))
               p95:        \(formatDuration(measurement.p95))
               p99:        \(formatDuration(measurement.p99))
               Max:        \(formatDuration(measurement.max))
               StdDev:     \(formatDuration(measurement.standardDeviation))
            """
        
        if let allocations = allocations, !allocations.isEmpty {
            let minAlloc = allocations.min() ?? 0
            let maxAlloc = allocations.max() ?? 0
            let avgAlloc = allocations.reduce(0, +) / allocations.count
            
            output += """
            
               Allocations:
                 Min:      \(formatBytes(minAlloc))
                 Median:   \(formatBytes(allocations.sorted()[allocations.count / 2]))
                 Max:      \(formatBytes(maxAlloc))
                 Avg:      \(formatBytes(avgAlloc))
            """
        }
        
        print(output)
    }
    
    private static func formatBytes(_ bytes: Int) -> String {
        if bytes == 0 {
            return "0 bytes"
        } else if bytes < 1024 {
            return "\(bytes) bytes"
        } else if bytes < 1024 * 1024 {
            return formatNumber(Double(bytes) / 1024.0, decimals: 2) + " KB"
        } else if bytes < 1024 * 1024 * 1024 {
            return formatNumber(Double(bytes) / (1024.0 * 1024.0), decimals: 2) + " MB"
        } else {
            return formatNumber(Double(bytes) / (1024.0 * 1024.0 * 1024.0), decimals: 2) + " GB"
        }
    }
    
    private static func formatNumber(_ value: Double, decimals: Int) -> String {
        let multiplier = pow(10.0, Double(decimals))
        let rounded = (value * multiplier).rounded() / multiplier
        
        let integerPart = Int(rounded)
        let fractionalPart = rounded - Double(integerPart)
        
        if fractionalPart == 0 {
            return "\(integerPart).\(String(repeating: "0", count: decimals))"
        }
        
        var fractionStr = "\(Int((fractionalPart * multiplier).rounded()))"
        while fractionStr.count < decimals {
            fractionStr = "0" + fractionStr
        }
        
        return "\(integerPart).\(fractionStr)"
    }
}

/// Performance comparison report
@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public struct PerformanceComparison: Sendable {
    public let name: String
    public let current: TestingPerformance.Measurement
    public let baseline: TestingPerformance.Measurement
    public let metric: TestingPerformance.Metric
    
    public init(
        name: String,
        current: TestingPerformance.Measurement,
        baseline: TestingPerformance.Measurement,
        metric: TestingPerformance.Metric = .median
    ) {
        self.name = name
        self.current = current
        self.baseline = baseline
        self.metric = metric
    }
    
    public var currentValue: Duration {
        metric.extract(from: current)
    }
    
    public var baselineValue: Duration {
        metric.extract(from: baseline)
    }
    
    public var change: Double {
        (currentValue.inSeconds - baselineValue.inSeconds) / baselineValue.inSeconds
    }
    
    public var isRegression: Bool {
        change > 0
    }
    
    public var isImprovement: Bool {
        change < 0
    }
    
    public func formatted() -> String {
        let changePercent = abs(change) * 100
        let changeSymbol = isRegression ? "↑" : "↓"
        let changeColor = isRegression ? "🔴" : "🟢"
        
        return """
            \(changeColor) \(name)
                Baseline: \(TestingPerformance.formatDuration(baselineValue))
                Current:  \(TestingPerformance.formatDuration(currentValue))
                Change:   \(changeSymbol) \(formatPercent(changePercent))%
            """
    }
    
    private func formatPercent(_ value: Double) -> String {
        let multiplier = 10.0
        let rounded = (value * multiplier).rounded() / multiplier
        
        let integerPart = Int(rounded)
        let fractionalPart = rounded - Double(integerPart)
        
        if fractionalPart == 0 {
            return "\(integerPart).0"
        }
        
        let fractionStr = "\(Int((fractionalPart * multiplier).rounded()))"
        return "\(integerPart).\(fractionStr)"
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TestingPerformance {
    /// Print comparison report for multiple benchmarks
    public static func printComparisonReport(_ comparisons: [PerformanceComparison]) {
        print("\n╔══════════════════════════════════════════════════════════╗")
        print("║           PERFORMANCE COMPARISON REPORT                  ║")
        print("╚══════════════════════════════════════════════════════════╝\n")
        
        for comparison in comparisons {
            print(comparison.formatted())
            print("")
        }
        
        let regressions = comparisons.filter { $0.isRegression }.count
        let improvements = comparisons.filter { $0.isImprovement }.count
        let neutral = comparisons.count - regressions - improvements
        
        print("Summary: \(improvements) improvements, \(neutral) neutral, \(regressions) regressions")
        print("╚══════════════════════════════════════════════════════════╝\n")
    }
}

/// Performance benchmark suite
///
/// Collects and reports on multiple related benchmarks.
///
/// Example:
/// ```swift
/// var suite = PerformanceSuite(name: "Sequence Operations")
///
/// suite.benchmark("sum") {
///     numbers.sum()
/// }
///
/// suite.benchmark("product") {
///     numbers.product()
/// }
///
/// suite.printReport()
/// ```
@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public struct PerformanceSuite {
    public let name: String
    private var benchmarks: [(name: String, measurement: TestingPerformance.Measurement)] = []
    
    public init(name: String) {
        self.name = name
    }
    
    public mutating func benchmark<T>(
        _ name: String,
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () -> T
    ) -> T {
        let (result, measurement) = TestingPerformance.measure(warmup: warmup, iterations: iterations, operation: operation)
        benchmarks.append((name, measurement))
        return result
    }
    
    public mutating func benchmark<T>(
        _ name: String,
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () async throws -> T
    ) async rethrows -> T {
        let (result, measurement) = try await TestingPerformance.measure(warmup: warmup, iterations: iterations, operation: operation)
        benchmarks.append((name, measurement))
        return result
    }
    
    public func printReport(metric: TestingPerformance.Metric = .median) {
        print("\n╔══════════════════════════════════════════════════════════╗")
        print("║  \(padRight(name, toLength: 56))║")
        print("╚══════════════════════════════════════════════════════════╝\n")
        
        let maxNameLength = benchmarks.map { $0.name.count }.max() ?? 0
        
        for (name, measurement) in benchmarks {
            let value = metric.extract(from: measurement)
            let paddedName = padRight(name, toLength: maxNameLength)
            print("  \(paddedName)  \(TestingPerformance.formatDuration(value))")
        }
        
        print("\n╚══════════════════════════════════════════════════════════╝\n")
    }
    
    private func padRight(_ string: String, toLength length: Int) -> String {
        if string.count >= length {
            return string
        }
        return string + String(repeating: " ", count: length - string.count)
    }
}
