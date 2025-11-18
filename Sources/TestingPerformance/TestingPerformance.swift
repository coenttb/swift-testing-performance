// TestingPerformance.swift
// TestingPerformance
//
// Main namespace and core types

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Namespace for TestingPerformance performance testing utilities
///
/// Provides measurement, formatting, and assertion functions for performance testing.
///
/// Example:
/// ```swift
/// let (result, measurement) = TestingPerformance.measure {
///     numbers.sum()
/// }
/// TestingPerformance.printPerformance("sum", measurement)
/// ```
public enum TestingPerformance {}

// MARK: - Error Types

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TestingPerformance {
    /// Errors that can occur during performance testing
    public enum Error: Swift.Error, CustomStringConvertible {
        /// Performance threshold was exceeded in a trait-based test
        case thresholdExceeded(test: String, metric: Metric, expected: Duration, actual: Duration)

        /// Memory allocation limit was exceeded
        case allocationLimitExceeded(test: String, limit: Int, actual: Int)

        /// Performance expectation assertion failed
        case performanceExpectationFailed(metric: Metric, threshold: Duration, actual: Duration)

        /// Performance regression was detected
        case regressionDetected(metric: Metric, baseline: Duration, current: Duration, regression: Double, tolerance: Double)

        public var description: String {
            switch self {
            case .thresholdExceeded(let test, let metric, let expected, let actual):
                return """
                    Performance threshold exceeded in '\(test)':
                    Expected \(metric): < \(TestingPerformance.formatDuration(expected))
                    Actual \(metric): \(TestingPerformance.formatDuration(actual))
                    """

            case .allocationLimitExceeded(let test, let limit, let actual):
                return """
                    Memory allocation limit exceeded in '\(test)':
                    Limit: \(formatBytes(limit))
                    Actual: \(formatBytes(actual))
                    Exceeded by: \(formatBytes(actual - limit))
                    """

            case .performanceExpectationFailed(let metric, let threshold, let actual):
                return """
                    Performance expectation failed:
                    Expected \(metric) < \(TestingPerformance.formatDuration(threshold))
                    Actual: \(TestingPerformance.formatDuration(actual))
                    Exceeded by: \(TestingPerformance.formatDuration(actual - threshold))
                    """

            case .regressionDetected(let metric, let baseline, let current, let regression, let tolerance):
                return """
                    Performance regression detected:
                    Baseline \(metric): \(TestingPerformance.formatDuration(baseline))
                    Current \(metric): \(TestingPerformance.formatDuration(current))
                    Regression: \(formatPercent(regression * 100))%
                    Tolerance: \(formatPercent(tolerance * 100))%
                    """
            }
        }

        private func formatBytes(_ bytes: Int) -> String {
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

        private func formatNumber(_ value: Double, decimals: Int) -> String {
            let multiplier = pow(10.0, Double(decimals))
            let rounded = (value * multiplier).rounded() / multiplier

            let integerPart = Int(rounded)
            let fractionalPart = rounded - Double(integerPart)

            if fractionalPart == 0 {
                return "\(integerPart).\(String(repeating: "0", count: decimals))"
            }

            let doubleFraction: Double = fractionalPart * multiplier
            var fractionStr = "\(Int(doubleFraction.rounded()))"
            while fractionStr.count < decimals {
                fractionStr = "0" + fractionStr
            }

            return "\(integerPart).\(fractionStr)"
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
}
