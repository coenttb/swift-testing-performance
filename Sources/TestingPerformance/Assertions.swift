// Assertions.swift
// TestingPerformance
//
// Performance threshold assertions for Swift Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TestingPerformance {
    /// Assert that an operation completes within a duration threshold
    ///
    /// Example:
    /// ```swift
    /// TestingPerformance.expectPerformance(lessThan: .milliseconds(100)) {
    ///     numbers.sum()
    /// }
    /// ```
    @discardableResult
    public static func expectPerformance<T>(
        lessThan threshold: Duration,
        warmup: Int = 0,
        iterations: Int = 10,
        metric: TestingPerformance.Metric = .median,
        operation: () -> T
    ) -> (result: T, measurement: TestingPerformance.Measurement) {
        let (result, measurement) = measure(warmup: warmup, iterations: iterations, operation: operation)
        
        let actualDuration = metric.extract(from: measurement)
        
        guard actualDuration <= threshold else {
            fatalError("""
                Performance expectation failed:
                Expected \(metric) < \(formatDuration(threshold))
                Actual: \(formatDuration(actualDuration))
                Exceeded by: \(formatDuration(actualDuration - threshold))
                """)
        }
        
        return (result, measurement)
    }
    
    /// Assert that an async operation completes within a duration threshold
    @discardableResult
    public static func expectPerformance<T>(
        lessThan threshold: Duration,
        warmup: Int = 0,
        iterations: Int = 10,
        metric: TestingPerformance.Metric = .median,
        operation: () async throws -> T
    ) async rethrows -> (result: T, measurement: TestingPerformance.Measurement) {
        let (result, measurement) = try await measure(warmup: warmup, iterations: iterations, operation: operation)
        
        let actualDuration = metric.extract(from: measurement)
        
        guard actualDuration <= threshold else {
            fatalError("""
                Performance expectation failed:
                Expected \(metric) < \(formatDuration(threshold))
                Actual: \(formatDuration(actualDuration))
                Exceeded by: \(formatDuration(actualDuration - threshold))
                """)
        }
        
        return (result, measurement)
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TestingPerformance {
    /// Performance metrics that can be asserted against
    public enum Metric: String, Sendable {
        case min
        case max
        case median
        case mean
        case p95
        case p99
        
        public func extract(from measurement: Measurement) -> Duration {
            switch self {
            case .min: return measurement.min
            case .max: return measurement.max
            case .median: return measurement.median
            case .mean: return measurement.mean
            case .p95: return measurement.p95
            case .p99: return measurement.p99
            }
        }
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TestingPerformance {
    /// Performance regression detector
    ///
    /// Compares current performance against a baseline with tolerance.
    ///
    /// Example:
    /// ```swift
    /// let baseline = PerformanceMeasurement(durations: [.milliseconds(10)])
    /// let (result, measurement) = TestingPerformance.measure { operation() }
    ///
    /// TestingPerformance.expectNoRegression(
    ///     current: measurement,
    ///     baseline: baseline,
    ///     tolerance: 0.10  // 10% regression allowed
    /// )
    /// ```
    public static func expectNoRegression(
        current: TestingPerformance.Measurement,
        baseline: TestingPerformance.Measurement,
        tolerance: Double = 0.10,
        metric: TestingPerformance.Metric = .median
    ) {
        let currentValue = metric.extract(from: current)
        let baselineValue = metric.extract(from: baseline)
        
        let regression = (currentValue.inSeconds - baselineValue.inSeconds) / baselineValue.inSeconds
        
        guard regression <= tolerance else {
            fatalError("""
                Performance regression detected:
                Baseline \(metric): \(formatDuration(baselineValue))
                Current \(metric): \(formatDuration(currentValue))
                Regression: \(formatPercent(regression * 100))%
                Tolerance: \(formatPercent(tolerance * 100))%
                """)
        }
    }
    
    private static func formatPercent(_ value: Double) -> String {
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
