// Threshold Tests.swift
// TestingPerformance

import Testing
import TestingPerformance

extension PerformanceTests {
    @Test("Threshold - platform-specific init")
    func thresholdPlatformSpecificInit() {
        let threshold = Threshold(
            macOS: .milliseconds(30),
            iOS: .milliseconds(50),
            linux: .milliseconds(25)
        )

        #expect(threshold.macOS == .milliseconds(30))
        #expect(threshold.iOS == .milliseconds(50))
        #expect(threshold.linux == .milliseconds(25))
        #expect(threshold.watchOS == nil)
        #expect(threshold.tvOS == nil)
        #expect(threshold.windows == nil)
    }

    @Test("Threshold - all platforms")
    func thresholdAll() {
        let threshold = Threshold.all(.milliseconds(100))

        #expect(threshold.macOS == .milliseconds(100))
        #expect(threshold.iOS == .milliseconds(100))
        #expect(threshold.watchOS == .milliseconds(100))
        #expect(threshold.tvOS == .milliseconds(100))
        #expect(threshold.linux == .milliseconds(100))
        #expect(threshold.windows == .milliseconds(100))
    }

    @Test("Threshold - Apple platforms")
    func thresholdApple() {
        let threshold = Threshold.apple(.milliseconds(50))

        #expect(threshold.macOS == .milliseconds(50))
        #expect(threshold.iOS == .milliseconds(50))
        #expect(threshold.watchOS == .milliseconds(50))
        #expect(threshold.tvOS == .milliseconds(50))
        #expect(threshold.linux == nil)
        #expect(threshold.windows == nil)
    }

    @Test("Threshold - Darwin platforms")
    func thresholdDarwin() {
        let threshold = Threshold.darwin(.milliseconds(75))

        #expect(threshold.macOS == .milliseconds(75))
        #expect(threshold.iOS == .milliseconds(75))
        #expect(threshold.watchOS == .milliseconds(75))
        #expect(threshold.tvOS == .milliseconds(75))
        #expect(threshold.linux == nil)
        #expect(threshold.windows == nil)
    }

    @Test("Threshold - current platform returns non-nil on macOS")
    func thresholdCurrentMacOS() {
        let threshold = Threshold(macOS: .milliseconds(100))

        #if os(macOS)
        #expect(threshold.current == .milliseconds(100))
        #else
        #expect(threshold.current == nil)
        #endif
    }

    @Test("Threshold - current platform with all set")
    func thresholdCurrentAllSet() {
        let threshold = Threshold.all(.milliseconds(200))

        // Current platform should always have a value
        #expect(threshold.current == .milliseconds(200))
    }

    @Test("Threshold - current platform with none set")
    func thresholdCurrentNoneSet() {
        let threshold = Threshold()

        // Current platform should be nil when nothing is set
        #expect(threshold.current == nil)
    }

    @Test("Threshold - nil literal")
    func thresholdNilLiteral() {
        let threshold: Threshold = nil

        #expect(threshold.macOS == nil)
        #expect(threshold.iOS == nil)
        #expect(threshold.watchOS == nil)
        #expect(threshold.tvOS == nil)
        #expect(threshold.linux == nil)
        #expect(threshold.windows == nil)
        #expect(threshold.current == nil)
    }

    @Test("Threshold - mixed platforms")
    func thresholdMixed() {
        let threshold = Threshold(
            macOS: .milliseconds(10),
            iOS: .milliseconds(20),
            watchOS: .milliseconds(30),
            tvOS: .milliseconds(40),
            linux: .milliseconds(50),
            windows: .milliseconds(60)
        )

        #expect(threshold.macOS == .milliseconds(10))
        #expect(threshold.iOS == .milliseconds(20))
        #expect(threshold.watchOS == .milliseconds(30))
        #expect(threshold.tvOS == .milliseconds(40))
        #expect(threshold.linux == .milliseconds(50))
        #expect(threshold.windows == .milliseconds(60))
    }
}
