// AllocationTrackingTests.swift
// TestingPerformance
//
// Memory allocation tracking tests

import Testing
import TestingPerformance

extension PerformanceTests {
    @Suite(.serialized)
    struct AllocationTracking {

        @Test(.timed(maxAllocations: 100_000))
        func `allocation-free iteration`() {
            let numbers = Array(1...10_000)
            var sum = 0
            for num in numbers {
                sum += num
            }
            _ = sum
        }

        @Test(.timed(threshold: .milliseconds(50), maxAllocations: 200_000))
        func `reduce with allocation limit`() {
            let numbers = Array(1...10_000)
            _ = numbers.reduce(0, +)
        }

        @Test(.timed(maxAllocations: 300_000))
        func `map operation allocations`() {
            let numbers = Array(1...5_000)
            _ = numbers.map { $0 * 2 }
        }

        @Test(.timed(maxAllocations: 300_000))
        func `filter operation allocations`() {
            let numbers = Array(1...5_000)
            _ = numbers.filter { $0 % 2 == 0 }
        }
    }
}
