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

- ``TestingPerformance/measure(warmup:iterations:operation:)-5zs0y``
- ``TestingPerformance/measure(warmup:iterations:operation:)-8tbt2``
- ``TestingPerformance/time(operation:)``
- ``TestingPerformance/time(operation:)-9h4h0``
- ``Measurement``
- ``Metric``

### Assertions and Expectations

- ``TestingPerformance/expectPerformance(lessThan:warmup:iterations:metric:operation:)-7tkbz``
- ``TestingPerformance/expectPerformance(lessThan:warmup:iterations:metric:operation:)-2y8rz``
- ``TestingPerformance/expectNoRegression(current:baseline:tolerance:metric:)``

### Performance Traits

- ``_PerformanceTrait``
- ``Trait/timed(iterations:warmup:threshold:maxAllocations:metric:)``

### Performance Comparison

- ``PerformanceComparison``
- ``TestingPerformance/printComparisonReport(_:)``
- ``PerformanceSuite``

### Memory Allocation Tracking

- ``TestingPerformance/captureAllocationStats()``
- ``TestingPerformance/AllocationStats``

### Reporting and Formatting

- ``TestingPerformance/printPerformance(_:_:allocations:)``
- ``TestingPerformance/formatDuration(_:style:)``
- ``TestingPerformance/DurationFormat``

### Statistics

- ``TestingPerformance/isSignificantlyDifferent(baseline:current:alpha:)``
- ``TestingPerformance/isSignificantlyFaster(baseline:current:alpha:)``
- ``TestingPerformance/isSignificantlySlower(baseline:current:alpha:)``

### Platform-Specific Thresholds

- ``Threshold``

### Error Handling

- ``TestingPerformance/Error``
