// ParallelAllocationTests.swift
// TestingPerformance
//
// Tests demonstrating parallel-safe allocation tracking using median-based validation

import Testing
import TestingPerformance

@Suite("Parallel Allocation Tests")
struct ParallelAllocationTests {
    // Note: These tests intentionally do NOT use .serialized
    // They demonstrate that median-based allocation validation
    // works correctly even with parallel test execution

    @Test(.timed(maxAllocations: 1_000_000))
    func `parallel test 1`() {
        let numbers = Array(1...5_000)
        _ = numbers.map { $0 * 2 }
    }

    @Test(.timed(maxAllocations: 1_000_000))
    func `parallel test 2`() {
        let numbers = Array(1...5_000)
        _ = numbers.filter { $0 % 2 == 0 }
    }

    @Test(.timed(maxAllocations: 1_000_000))
    func `parallel test 3`() {
        let numbers = Array(1...5_000)
        _ = numbers.reduce(0, +)
    }

    @Test(.timed(maxAllocations: 500_000))
    func `parallel test 4`() {
        // Allocation-free iteration
        let numbers = Array(1...10_000)
        var sum = 0
        for num in numbers {
            sum += num
        }
        _ = sum
    }

    @Test(.timed(maxAllocations: 1_000_000))
    func `parallel test 5`() {
        let numbers = Array(1...5_000)
        _ = numbers.compactMap { $0 % 3 == 0 ? $0 : nil }
    }
}

@Suite("Parallel Allocation Tests - Larger Suite")
struct ParallelAllocationLargeSuite {
    // A larger suite to increase the likelihood of parallel execution

    @Test(.timed(maxAllocations: 800_000))
    func `test 01`() { _ = Array(repeating: 0, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 02`() { _ = Array(repeating: 1, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 03`() { _ = Array(repeating: 2, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 04`() { _ = Array(repeating: 3, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 05`() { _ = Array(repeating: 4, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 06`() { _ = Array(repeating: 5, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 07`() { _ = Array(repeating: 6, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 08`() { _ = Array(repeating: 7, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 09`() { _ = Array(repeating: 8, count: 5_000) }

    @Test(.timed(maxAllocations: 800_000))
    func `test 10`() { _ = Array(repeating: 9, count: 5_000) }
}
