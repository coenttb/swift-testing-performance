// ManualMeasurementTests.swift
// TestingPerformance
//
// Manual measurement API tests

import Testing
import TestingPerformance

extension PerformanceTests {
    @Suite(.serialized)
    struct ManualMeasurement {

        @Test
        func `measure sync operation`() {
            let (result, measurement) = TestingPerformance.measure(iterations: 10) {
                let numbers = Array(1...5_000)
                return numbers.reduce(0, +)
            }

            #expect(result > 0)
            #expect(measurement.durations.count == 10)
            #expect(measurement.median > .zero)
            #expect(measurement.min > .zero)
            #expect(measurement.max >= measurement.min)
        }

        @Test
        func `measure with warmup`() {
            let (_, measurement) = TestingPerformance.measure(warmup: 3, iterations: 10) {
                let numbers = Array(1...5_000)
                return numbers.reduce(0, +)
            }

            #expect(measurement.durations.count == 10)
        }

        @Test
        func `time single execution`() {
            let (result, duration) = TestingPerformance.time {
                let numbers = Array(1...5_000)
                return numbers.reduce(0, +)
            }

            #expect(result > 0)
            #expect(duration > .zero)
        }

        @Test
        func `measurement statistics`() {
            let (_, measurement) = TestingPerformance.measure(iterations: 20) {
                let numbers = Array(1...5_000)
                return numbers.reduce(0, +)
            }

            // Verify statistical properties
            #expect(measurement.min <= measurement.median)
            #expect(measurement.median <= measurement.max)
            #expect(measurement.p95 <= measurement.max)
            #expect(measurement.p99 <= measurement.max)
            #expect(measurement.standardDeviation >= .zero)
        }

        @Test
        func `async measurement`() async {
            let (result, measurement) = await TestingPerformance.measure(iterations: 5) {
                try? await Task.sleep(for: .milliseconds(1))
                return 42
            }

            #expect(result == 42)
            #expect(measurement.durations.count == 5)
            #expect(measurement.median > .milliseconds(0.5))
        }

        @Test
        func `async time single execution`() async {
            let (result, duration) = await TestingPerformance.time {
                try? await Task.sleep(for: .milliseconds(1))
                return 42
            }

            #expect(result == 42)
            #expect(duration > .milliseconds(0.5))
        }
    }
}
