// DurationFormattingTests.swift
// TestingPerformance
//
// Duration formatting tests

import Testing
import TestingPerformance

extension PerformanceTests {
    @Suite(.serialized)
    struct DurationFormatting {

        @Test
        func `auto format nanoseconds`() {
            let formatted = TestingPerformance.formatDuration(.nanoseconds(500))
            #expect(formatted.contains("ns"))
        }

        @Test
        func `auto format microseconds`() {
            let formatted = TestingPerformance.formatDuration(.microseconds(500))
            #expect(formatted.contains("µs"))
        }

        @Test
        func `auto format milliseconds`() {
            let formatted = TestingPerformance.formatDuration(.milliseconds(500))
            #expect(formatted.contains("ms"))
        }

        @Test
        func `auto format seconds`() {
            let formatted = TestingPerformance.formatDuration(.seconds(2))
            #expect(formatted.hasSuffix("s"))
            #expect(!formatted.contains("ms"))
        }

        @Test
        func `explicit nanoseconds format`() {
            let formatted = TestingPerformance.formatDuration(
                .microseconds(1),
                .nanoseconds
            )
            #expect(formatted.contains("ns"))
        }

        @Test
        func `explicit milliseconds format`() {
            let formatted = TestingPerformance.formatDuration(
                .seconds(1),
                .milliseconds
            )
            #expect(formatted.contains("ms"))
        }
    }
}
