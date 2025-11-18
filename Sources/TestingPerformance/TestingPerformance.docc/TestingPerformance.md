# ``TestingPerformance``

Performance testing utilities for Swift Testing framework.

## Overview

TestingPerformance provides comprehensive performance testing capabilities for the Swift Testing framework. It enables you to measure execution time, track memory allocations, compare performance across runs, and enforce performance budgets—all with zero external dependencies.

### Key Features

- **Zero Dependencies**: Built entirely on Swift stdlib and platform APIs
- **Swift Testing Integration**: Native traits like `@Test(.timed())`
- **Statistical Analysis**: Median, mean, percentiles, standard deviation, and Welch's t-test
- **Memory Tracking**: Monitor allocations during test execution
- **Rich Reporting**: Beautiful formatted output with ANSI colors
- **Baseline Comparison**: Detect performance regressions
- **Platform-Agnostic**: Works on macOS, iOS, Linux, and more

## Topics

### Essentials

- ``TestingPerformance``
- <doc:GettingStarted>
- <doc:PerformanceTraits>

### Measurement

- ``TestingPerformance/measure(warmup:iterations:operation:)-4kv1g``
- ``TestingPerformance/measure(warmup:iterations:operation:)-32h7a``
- ``TestingPerformance/time(operation:)-2qtt``
- ``TestingPerformance/time(operation:)-21jsp``
- ``TestingPerformance/Measurement``
- ``TestingPerformance/Metric``

### Assertions and Expectations

- ``TestingPerformance/expectPerformance(lessThan:warmup:iterations:metric:operation:)-5llun``
- ``TestingPerformance/expectPerformance(lessThan:warmup:iterations:metric:operation:)-9621g``
- ``TestingPerformance/expectNoRegression(current:baseline:tolerance:metric:)``

### Performance Comparison

- ``PerformanceComparison``
- ``TestingPerformance/printComparisonReport(_:)``
- ``PerformanceSuite``

### Reporting and Formatting

- ``TestingPerformance/printPerformance(_:_:allocations:)``
- ``TestingPerformance/printComparisonReport(_:)``

### Platform-Specific Thresholds

- ``Threshold``

### Error Handling

- ``TestingPerformance/Error``
