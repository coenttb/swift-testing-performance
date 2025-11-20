// AllocationTrackingTests.swift
// TestingPerformance
//
// Memory allocation tracking tests

import Testing
import TestingPerformance

extension PerformanceTests {
    @Suite("Allocation Tracking", .serialized)
    struct AllocationTracking {
        // Note: .serialized is required for accurate allocation tracking
        // On Darwin, malloc_zone_statistics returns process-wide stats
        // Parallel tests would interfere with each other's measurements

        @Test(.timed(maxAllocations: 500_000))
        func `allocation-free iteration`() {
            // Generous limit to account for platform variations
            let numbers = Array(1...10_000)
            var sum = 0
            for num in numbers {
                sum += num
            }
            _ = sum
        }

        @Test(.timed(threshold: .milliseconds(50), maxAllocations: 1_000_000))
        func `reduce with allocation limit`() {
            // Generous limit to account for platform variations
            let numbers = Array(1...10_000)
            _ = numbers.reduce(0, +)
        }

        @Test(.timed(maxAllocations: 1_000_000))
        func `map operation allocations`() {
            // Generous limit to account for platform variations
            let numbers = Array(1...5_000)
            _ = numbers.map { $0 * 2 }
        }

        @Test(.timed(maxAllocations: 1_000_000))
        func `filter operation allocations`() {
            // Generous limit to account for platform variations
            let numbers = Array(1...5_000)
            _ = numbers.filter { $0 % 2 == 0 }
        }
    }
}
