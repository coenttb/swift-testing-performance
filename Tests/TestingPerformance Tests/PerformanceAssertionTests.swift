// PerformanceAssertionTests.swift
// TestingPerformance Tests
//
// Performance assertion API tests

import Testing
import TestingPerformance

extension PerformanceTests {
    @Suite(.serialized)
    struct PerformanceAssertions {

        @Test
        func `expectPerformance with passing threshold`() {
            let (result, measurement) = TestingPerformance.expectPerformance(
                lessThan: .milliseconds(100),
                iterations: 10
            ) {
                let numbers = Array(1...5_000)
                return numbers.reduce(0, +)
            }

            #expect(result > 0)
            #expect(measurement.median < .milliseconds(100))
        }

        @Test
        func `expectPerformance with custom metric`() {
            let (_, measurement) = TestingPerformance.expectPerformance(
                lessThan: .milliseconds(100),
                iterations: 10,
                metric: .p95
            ) {
                let numbers = Array(1...5_000)
                return numbers.reduce(0, +)
            }

            #expect(measurement.p95 < .milliseconds(100))
        }

        @Test
        func `expectNoRegression with improvement`() {
            let baseline = TestingPerformance.Measurement(
                durations: Array(repeating: .milliseconds(10), count: 10)
            )

            let current = TestingPerformance.Measurement(
                durations: Array(repeating: .milliseconds(8), count: 10)
            )

            // Should not throw - performance improved
            TestingPerformance.expectNoRegression(
                current: current,
                baseline: baseline,
                tolerance: 0.10
            )
        }

        @Test
        func `expectNoRegression within tolerance`() {
            let baseline = TestingPerformance.Measurement(
                durations: Array(repeating: .milliseconds(10), count: 10)
            )

            let current = TestingPerformance.Measurement(
                durations: Array(repeating: .milliseconds(10.5), count: 10)
            )

            // 5% regression, within 10% tolerance
            TestingPerformance.expectNoRegression(
                current: current,
                baseline: baseline,
                tolerance: 0.10
            )
        }
    }
}
