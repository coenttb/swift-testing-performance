# Getting Started

Learn how to measure and test performance in your Swift projects.

## Overview

TestingPerformance makes it easy to add performance testing to your Swift Testing test suites. You can measure execution time, track allocations, and enforce performance budgets with minimal code.

## Installation

Add TestingPerformance to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-testing-performance", from: "0.1.0")
]
```

Then add it to your test target:

```swift
.testTarget(
    name: "MyTests",
    dependencies: [
        .product(name: "TestingPerformance", package: "swift-testing-performance")
    ]
)
```

## Quick Start

### Using Performance Traits

The easiest way to measure performance is with the `.timed()` trait:

```swift
import Testing
import TestingPerformance

@Test(.timed())
func fastArrayOperation() {
    let numbers = Array(1...10_000)
    _ = numbers.reduce(0, +)
}
```

This automatically prints performance statistics:

```
⏱️ fastArrayOperation()
   Iterations: 10
   Min:        2.34ms
   Median:     2.45ms
   Mean:       2.48ms
   p95:        2.78ms
   p99:        2.78ms
   Max:        2.78ms
   StdDev:     119.05µs
```

### Enforcing Performance Budgets

Add a threshold to fail tests that exceed your performance budget:

```swift
@Test(.timed(threshold: .milliseconds(5)))
func mustBeFast() {
    let numbers = Array(1...10_000)
    _ = numbers.reduce(0, +)
}
```

If the median time exceeds 5ms, the test fails with a detailed error message.

### Manual Measurement

For more control, use the measurement APIs directly:

```swift
@Test
func manualMeasurement() throws {
    let (result, measurement) = try TestingPerformance.expectPerformance(
        lessThan: .milliseconds(10)
    ) {
        expensiveOperation()
    }

    #expect(result.isValid)
    #expect(measurement.median < .milliseconds(10))
}
```

### Tracking Memory Allocations

Monitor memory allocations during test execution:

```swift
@Test(.timed(maxAllocations: 1024))
func lowAllocation() {
    let numbers = Array(1...1_000)
    var sum = 0
    for num in numbers {
        sum += num
    }
    _ = sum
}
```

### Comparing Performance

Create benchmark suites to compare related operations:

```swift
@Test
func arrayBenchmarks() {
    var suite = PerformanceSuite(name: "Array Operations")

    suite.benchmark("sum") {
        numbers.reduce(0, +)
    }

    suite.benchmark("product") {
        numbers.reduce(1, *)
    }

    suite.printReport()
}
```

Output:

```
╔══════════════════════════════════════════════════════════╗
║                    Array Operations                      ║
╚══════════════════════════════════════════════════════════╝

  sum      1.23ms
  product  1.45ms

╚══════════════════════════════════════════════════════════╝
```

## Next Steps

- Learn about <doc:PerformanceTraits> for declarative testing
- Explore ``TestingPerformance/Measurement`` for detailed metrics
- Use ``PerformanceComparison`` for regression detection
