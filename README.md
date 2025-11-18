# swift-testing-performance

[![CI](https://github.com/coenttb/swift-testing-performance/workflows/CI/badge.svg)](https://github.com/coenttb/swift-testing-performance/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Performance testing infrastructure for Swift Testing framework with statistical analysis, performance budgets, and memory allocation tracking.

## Overview

swift-testing-performance provides declarative performance testing using Swift Testing's trait system. It integrates statistical metrics, automatic threshold enforcement, and memory allocation tracking into Swift Testing's workflow without external dependencies.

The package enables performance regression detection in CI pipelines through trait-based API, comprehensive statistical analysis, and zero-dependency implementation using only Swift standard library and platform math libraries (Darwin/Glibc).

## Features

- **Swift Testing Integration**: Declarative `.timed()` trait for performance testing with automatic statistical reporting
- **Statistical Metrics**: Comprehensive analysis including min, median, mean, p95, p99, max, and standard deviation
- **Performance Budgets**: Automatic test failures when median exceeds defined thresholds
- **Memory Allocation Tracking**: Platform-specific malloc statistics to enforce zero-allocation algorithms
- **Flexible Measurement API**: Both trait-based (`@Test(.timed())`) and manual (`TestingPerformance.measure()`) measurement
- **Zero Dependencies**: Uses only Swift standard library, Testing framework, and platform math libraries (Darwin/Glibc)
- **High Precision**: Int128-based Duration division for attosecond-level precision

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-testing-performance", from: "1.0.0")
]
```

### Requirements

- Swift 6.0+
- macOS 15.0+, iOS 18.0+, watchOS 11.0+, tvOS 18.0+
- Swift Testing framework

## Quick Start

### Basic Performance Test

```swift
import Testing
import TestingPerformance

@Test(.timed())
func `array reduce performance`() {
    let numbers = Array(1...100_000)
    _ = numbers.reduce(0, +)
}
```

Output:
```
⏱️ `array reduce performance`()
   Iterations: 10
   Min:        25.18ms
   Median:     25.51ms
   Mean:       25.61ms
   p95:        26.83ms
   p99:        26.83ms
   Max:        26.83ms
   StdDev:     466.95µs
```

### With Performance Budget

```swift
@Test(.timed(threshold: .milliseconds(30)))
func `must complete within 30ms`() {
    let numbers = Array(1...100_000)
    _ = numbers.reduce(0, +)
}
```

Test fails if median exceeds 30ms with detailed error:
```
Performance threshold exceeded in 'must complete within 30ms':
Expected median: < 30.00ms
Actual median: 35.42ms
```

### Memory Allocation Tracking

```swift
@Test(.timed(threshold: .milliseconds(30), maxAllocations: 60_000))
func `zero-allocation iteration`() {
    let numbers = Array(1...100_000)
    _ = numbers.reduce(0, +)
}
```

Output includes allocation statistics:
```
   Allocations:
     Min:      0 bytes
     Median:   0 bytes
     Max:      49.06 KB
     Avg:      4.91 KB
```

Median of 0 bytes proves the algorithm is allocation-free.

## Usage Examples

### Organizing Performance Tests

Use serialized test execution to prevent interference:

```swift
import Testing
import TestingPerformance

@Suite(.serialized)
struct PerformanceTests {}

extension PerformanceTests {
    @Suite(.serialized)
    struct `Array Performance` {

        @Test(.timed(threshold: .milliseconds(30)))
        func `sum 100k elements`() {
            let numbers = Array(1...100_000)
            _ = numbers.reduce(0, +)
        }

        @Test(.timed(threshold: .milliseconds(50)))
        func `map 100k elements`() {
            let numbers = Array(1...100_000)
            _ = numbers.map { $0 * 2 }
        }
    }
}
```

### Manual Measurement API

For custom measurement scenarios outside Swift Testing:

```swift
import TestingPerformance

// Statistical measurement
let (result, measurement) = TestingPerformance.measure(iterations: 100) {
    expensiveOperation()
}

print("Median: \(TestingPerformance.formatDuration(measurement.median))")
print("p95: \(TestingPerformance.formatDuration(measurement.p95))")

// Single-shot timing
let (quickResult, duration) = TestingPerformance.time {
    oneTimeOperation()
}

// Async operations
let (asyncResult, asyncMeasurement) = await TestingPerformance.measure {
    await asyncOperation()
}
```

### Performance Assertions

```swift
// Assert performance threshold
TestingPerformance.expectPerformance(lessThan: .milliseconds(100)) {
    operation()
}

// Regression detection
let baseline = TestingPerformance.Measurement(
    durations: Array(repeating: .milliseconds(10), count: 10)
)
let current = TestingPerformance.measure { operation() }.measurement

TestingPerformance.expectNoRegression(
    current: current,
    baseline: baseline,
    tolerance: 0.10  // Allow 10% regression
)
```

### Performance Suite API

Compare multiple related operations:

```swift
var suite = PerformanceSuite(name: "String Operations")

suite.benchmark("concatenation") {
    var result = ""
    for i in 1...1000 {
        result += String(i)
    }
}

suite.benchmark("interpolation") {
    var result = ""
    for i in 1...1000 {
        result += "\(i)"
    }
}

suite.benchmark("joined") {
    let parts = (1...1000).map(String.init)
    _ = parts.joined()
}

suite.printReport()
```

Output:
```
╔══════════════════════════════════════════════════════════╗
║  String Operations                                       ║
╚══════════════════════════════════════════════════════════╝

  concatenation   5.23ms
  interpolation   4.87ms
  joined          1.42ms
```

### Trait API

The `.timed()` trait supports comprehensive configuration:

```swift
@Test(.timed(
    iterations: 10,           // Number of measurement runs (default: 10)
    warmup: 0,                // Warmup runs before measurement (default: 0)
    threshold: .milliseconds(30),  // Optional performance budget
    maxAllocations: 60_000,   // Optional allocation limit in bytes
    metric: .median           // Metric for threshold (default: .median)
))
func `performance test`() {
    // Test code
}
```

### Performance Metrics

Choose which metric to enforce thresholds against:

- `.min` - Minimum measured duration
- `.max` - Maximum measured duration
- `.median` - Median duration (default, most stable)
- `.mean` - Mean/average duration
- `.p95` - 95th percentile
- `.p99` - 99th percentile

Example:
```swift
@Test(.timed(threshold: .milliseconds(30), metric: .p95))
func `p95 threshold`() {
    let numbers = Array(1...100_000)
    _ = numbers.reduce(0, +)
}
```

## Best Practices

### 1. Separate Correctness from Performance

```swift
// Correctness test
@Test
func `sum returns correct total`() {
    #expect([1, 2, 3].sum() == 6)
}

// Performance test
extension PerformanceTests {
    @Test(.timed(threshold: .milliseconds(30)))
    func `sum is fast`() {
        _ = Array(1...100_000).sum()
    }
}
```

### 2. Use Serialized Execution

Always use `.serialized` for performance test suites to avoid interference:

```swift
@Suite(.serialized)
struct PerformanceTests {}

extension PerformanceTests {
    @Suite(.serialized)
    struct `Sequence Performance` {
        // Tests run one at a time
    }
}
```

### 3. Use Median for Thresholds

Median is more stable than mean for performance thresholds:

```swift
@Test(.timed(threshold: .milliseconds(30), metric: .median))  // ✅ Recommended
@Test(.timed(threshold: .milliseconds(30), metric: .mean))    // ⚠️ Less stable
```

### 4. Add Headroom to Thresholds

Account for system variation with 10-15% headroom:

```swift
// Measured median: 25ms
@Test(.timed(threshold: .milliseconds(30)))  // ✅ 20% headroom
@Test(.timed(threshold: .milliseconds(25)))  // ❌ Too tight, will flake
```

### 5. Adjust Iterations by Runtime

- Fast operations (<1ms): 100+ iterations
- Medium operations (1-100ms): 10-50 iterations
- Slow operations (>100ms): 5-10 iterations

```swift
@Test(.timed(iterations: 100, threshold: .microseconds(50)))
func `fast operation`() { ... }

@Test(.timed(iterations: 10, threshold: .milliseconds(500)))
func `slow operation`() { ... }
```

## Memory Allocation Tracking

TestingPerformance tracks memory allocations during test execution using platform-specific malloc statistics:

- **Darwin**: `malloc_statistics_t` via `malloc_zone_statistics()`
- **Linux**: `mallinfo()` via glibc

### Interpreting Allocation Stats

```
Allocations:
  Min:      0 bytes      ← Best case (no allocations)
  Median:   0 bytes      ← Typical case (50th percentile)
  Max:      49.06 KB     ← Worst case (caught background activity)
  Avg:      4.91 KB      ← Average across all iterations
```

**Key insight**: Median of 0 bytes proves the algorithm is allocation-free. The max captures occasional background system allocations (malloc zone management, runtime housekeeping).

### Setting Allocation Limits

Account for system noise when setting limits:

```swift
// For truly allocation-free algorithms
@Test(.timed(maxAllocations: 60_000))  // ~60KB headroom for system noise
func `zero allocation test`() {
    let numbers = Array(1...100_000)
    var sum = 0
    for num in numbers {
        sum += num
    }
    _ = sum
}
```

## Relationship to Swift Benchmark

- **swift-testing-performance**: Regression testing with performance budgets in your Swift Testing suite for CI pipelines
- **swift-benchmark**: Dedicated microbenchmarking for comparing algorithms across runs/machines with detailed analysis

Use both: swift-testing-performance for CI regression gates, Benchmark for detailed performance profiling.

## License

This project is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

## Author

[Coen ten Thije Boonkkamp](https://github.com/coenttb)
