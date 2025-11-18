# Performance Traits

Use declarative traits to measure test performance with Swift Testing.

## Overview

Performance traits integrate seamlessly with Swift Testing's trait system, allowing you to measure and enforce performance requirements declaratively on your test functions and suites.

## Basic Usage

### Simple Timing

Add `.timed()` to any test to measure its performance:

```swift
@Test(.timed())
func sortingPerformance() {
    let numbers = (1...10_000).shuffled()
    _ = numbers.sorted()
}
```

This prints detailed statistics after each test run.

### Custom Iterations

Control the number of measurement iterations:

```swift
@Test(.timed(iterations: 100))
func preciseM easurement() {
    quickOperation()
}
```

More iterations provide more accurate statistical measurements but take longer to run.

### Warmup Runs

Add warmup iterations to stabilize performance before measurement:

```swift
@Test(.timed(iterations: 50, warmup: 5))
func stableMeasurement() {
    // First 5 runs are discarded
    // Next 50 runs are measured
    operation()
}
```

Warmup runs help eliminate cold-start effects and JIT compilation overhead.

## Performance Budgets

### Setting Thresholds

Enforce maximum execution time with thresholds:

```swift
@Test(.timed(threshold: .milliseconds(10)))
func mustBeFast() {
    criticalPathOperation()
}
```

The test fails if the median time exceeds the threshold.

### Different Metrics

Choose which metric to check against the threshold:

```swift
// Check p95 instead of median
@Test(.timed(threshold: .milliseconds(20), metric: .p95))
func consistentPerformance() {
    operation()
}

// Check mean
@Test(.timed(threshold: .milliseconds(15), metric: .mean))
func averagePerformance() {
    operation()
}
```

Available metrics:
- `.median` (default) - Middle value, resistant to outliers
- `.mean` - Average value
- `.min` - Fastest iteration
- `.max` - Slowest iteration
- `.p95` - 95th percentile
- `.p99` - 99th percentile

## Memory Allocation Tracking

### Allocation Limits

Enforce maximum memory allocation during test execution:

```swift
@Test(.timed(maxAllocations: 1024))
func noExtraAllocations() {
    let numbers = Array(1...1_000)
    var sum = 0
    for num in numbers {
        sum += num  // Should iterate without copying
    }
}
```

The test fails if any iteration exceeds the allocation limit.

### Combined Constraints

Check both time and allocations:

```swift
@Test(.timed(
    threshold: .milliseconds(5),
    maxAllocations: 10_000,
    iterations: 20
))
func efficientOperation() {
    optimizedAlgorithm()
}
```

## Suite-Level Traits

Apply traits to entire test suites:

```swift
@Suite(.timed(iterations: 20))
struct PerformanceTests {
    @Test
    func operation1() {
        // Measured with 20 iterations
    }

    @Test
    func operation2() {
        // Also measured with 20 iterations
    }

    @Test(.timed(iterations: 100))
    func preciseMeasurement() {
        // Override: measured with 100 iterations
    }
}
```

Test-level traits override suite-level traits.

## Serialized Execution

Prevent interference between concurrent tests:

```swift
@Suite(.serialized)
struct PerformanceTests {
    @Test(.timed())
    func test1() {
        // Runs alone
    }

    @Test(.timed())
    func test2() {
        // Runs after test1 completes
    }
}
```

Use `.serialized` on performance test suites to ensure accurate measurements.

## Error Handling

When a performance threshold is exceeded, the test throws ``TestingPerformance/Error/thresholdExceeded(test:metric:expected:actual:)``:

```
Performance threshold exceeded in 'slowOperation':
Expected median: < 10.00ms
Actual median: 15.23ms
```

When allocation limits are exceeded, the test throws ``TestingPerformance/Error/allocationLimitExceeded(test:limit:actual:)``:

```
Memory allocation limit exceeded in 'operation':
Limit: 1.00 KB
Actual: 45.23 KB
Exceeded by: 44.23 KB
```

## Best Practices

### Choose Appropriate Iterations

- **Fast operations** (< 1ms): 100+ iterations for statistical significance
- **Medium operations** (1-100ms): 10-50 iterations
- **Slow operations** (> 100ms): 5-10 iterations

### Use Warmup for JIT Languages

Always use warmup runs when:
- Testing Swift code that might be JIT compiled
- Measuring code with lazy initialization
- Testing code with caching behavior

### Select the Right Metric

- **Median**: Best for most cases, resistant to outliers
- **Mean**: When outliers are important
- **p95/p99**: For latency-sensitive code where tail latency matters
- **Max**: When worst-case performance is critical

### Avoid Interference

```swift
// Good: Serialized execution
@Suite(.serialized)
struct PerformanceTests {
    @Test(.timed()) func test1() {}
    @Test(.timed()) func test2() {}
}

// Risky: Concurrent execution may interfere
@Suite
struct PerformanceTests {
    @Test(.timed()) func test1() {}
    @Test(.timed()) func test2() {}
}
```

## See Also

- ``TestingPerformance/Error``
- ``TestingPerformance/Measurement``
- ``TestingPerformance/Metric``
