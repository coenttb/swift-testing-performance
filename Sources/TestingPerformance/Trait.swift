// Trait.swift
// TestingPerformance
//
// Performance measurement traits for Swift Testing

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

#if canImport(Testing)
    @_exported import Testing

    #if compiler(>=6.0)

        @_documentation(visibility: private)
        @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
        public struct _PerformanceTrait: TestScoping, TestTrait, SuiteTrait {
            let configuration: TestingPerformance.Configuration

            @TaskLocal static var currentConfig: TestingPerformance.Configuration?

            public var isRecursive: Bool { true }

            public func provideScope(
                for test: Test,
                testCase: Test.Case?,
                performing function: @Sendable () async throws -> Void
            ) async throws {
                // Merge configurations (parent + current)
                let effectiveConfig =
                    Self.currentConfig?.merged(with: configuration) ?? configuration

                try await Self.$currentConfig.withValue(effectiveConfig) {
                    // Run test with performance measurement
                    try await measureTest(
                        name: test.name,
                        config: effectiveConfig,
                        performing: function
                    )
                }
            }

            private func measureTest(
                name: String,
                config: TestingPerformance.Configuration,
                performing function: @Sendable () async throws -> Void
            ) async throws {
                guard config.enabled else {
                    try await function()
                    return
                }

                // Initialize leak detector if requested
                let leakDetector: MemoryAllocation.LeakDetector? =
                    config.detectLeaks ? LeakDetector() : nil

                // Initialize peak memory tracker if requested or needed
                let peakTracker: MemoryAllocation.PeakMemoryTracker? =
                    (config.peakMemoryLimit != nil || config.printResults)
                    ? PeakMemoryTracker() : nil

                #if os(Linux)
                    // Start tracking on Linux if we need allocation stats
                    if config.maxAllocations != nil || config.detectLeaks || peakTracker != nil {
                        MemoryAllocation.AllocationStats.startTracking()
                    }
                #endif

                // Warmup
                for _ in 0..<config.warmup {
                    try await function()
                }

                // Measure
                var durations: [Duration] = []
                var allocationDeltas: [Int] = []

                for _ in 0..<config.iterations {
                    // Use AllocationTracker.measure() for cleaner allocation tracking
                    let result = try await measureWithAllocations(function)

                    durations.append(result.duration)

                    // Track allocation delta if monitoring allocations
                    if config.maxAllocations != nil {
                        allocationDeltas.append(result.stats.bytesAllocated)
                    }

                    // Sample peak memory if tracking
                    peakTracker?.sample()
                }

                let measurement = TestingPerformance.Measurement(durations: durations)

                // Print and validate results
                let context = ValidationContext(
                    measurement: measurement,
                    allocationDeltas: allocationDeltas,
                    leakDetector: leakDetector,
                    peakTracker: peakTracker
                )
                try reportAndValidateResults(name: name, config: config, context: context)
            }

            private struct ValidationContext {
                let measurement: TestingPerformance.Measurement
                let allocationDeltas: [Int]
                let leakDetector: MemoryAllocation.LeakDetector?
                let peakTracker: MemoryAllocation.PeakMemoryTracker?
            }

            private func reportAndValidateResults(
                name: String,
                config: TestingPerformance.Configuration,
                context: ValidationContext
            ) throws {
                // Print if requested
                if config.printResults {
                    let peakBytes = context.peakTracker?.peakBytes
                    TestingPerformance.printPerformance(
                        name,
                        context.measurement,
                        allocations: context.allocationDeltas.isEmpty
                            ? nil : context.allocationDeltas,
                        peakMemory: peakBytes
                    )
                }

                // Validate performance threshold
                try validatePerformanceThreshold(
                    name: name,
                    config: config,
                    measurement: context.measurement
                )

                // Validate allocation limit
                try validateAllocationLimit(
                    name: name,
                    config: config,
                    allocationDeltas: context.allocationDeltas
                )

                // Validate no memory leaks
                try validateNoMemoryLeaks(name: name, detector: context.leakDetector)

                // Validate peak memory limit
                try validatePeakMemoryLimit(
                    name: name,
                    config: config,
                    tracker: context.peakTracker
                )
            }

            private func validatePerformanceThreshold(
                name: String,
                config: TestingPerformance.Configuration,
                measurement: TestingPerformance.Measurement
            ) throws {
                guard let threshold = config.threshold else { return }
                let metric = config.metric.extract(from: measurement)
                guard metric <= threshold else {
                    throw TestingPerformance.Error.thresholdExceeded(
                        test: name,
                        metric: config.metric,
                        expected: threshold,
                        actual: metric
                    )
                }
            }

            private func validateAllocationLimit(
                name: String,
                config: TestingPerformance.Configuration,
                allocationDeltas: [Int]
            ) throws {
                guard let maxAllocations = config.maxAllocations, !allocationDeltas.isEmpty else {
                    return
                }

                // Use median instead of max to be robust to parallel test interference
                // On Darwin, malloc_zone_statistics returns process-wide stats
                // In parallel execution, some iterations may capture allocations from other tests
                // Median filters out interference while still catching real allocation issues
                let sortedAllocations = allocationDeltas.sorted()
                let medianIndex = sortedAllocations.count / 2
                let medianAllocationBytes: Int

                if sortedAllocations.count % 2 == 0 {
                    // Even number of samples: average the two middle values
                    medianAllocationBytes = (sortedAllocations[medianIndex - 1] + sortedAllocations[medianIndex]) / 2
                } else {
                    // Odd number of samples: take the middle value
                    medianAllocationBytes = sortedAllocations[medianIndex]
                }

                guard medianAllocationBytes <= maxAllocations else {
                    throw TestingPerformance.Error.allocationLimitExceeded(
                        test: name,
                        limit: maxAllocations,
                        actual: medianAllocationBytes
                    )
                }
            }

            private func validateNoMemoryLeaks(
                name: String,
                detector: MemoryAllocation.LeakDetector?
            ) throws {
                guard let detector = detector else { return }
                if detector.hasLeaks() {
                    throw TestingPerformance.Error.memoryLeakDetected(
                        test: name,
                        netAllocations: detector.netAllocations,
                        netBytes: detector.netBytes
                    )
                }
            }

            private func validatePeakMemoryLimit(
                name: String,
                config: TestingPerformance.Configuration,
                tracker: MemoryAllocation.PeakMemoryTracker?
            ) throws {
                guard let limit = config.peakMemoryLimit, let tracker = tracker else { return }
                guard tracker.peakBytes <= limit else {
                    throw TestingPerformance.Error.peakMemoryExceeded(
                        test: name,
                        limit: limit,
                        actual: tracker.peakBytes
                    )
                }
            }

            // Helper to measure both duration and allocations using AllocationTracker
            private func measureWithAllocations(
                _ function: @Sendable () async throws -> Void
            ) async throws -> MeasurementResult {
                let start = ContinuousClock.now
                let (_, stats) = try await MemoryAllocation.AllocationTracker.measure {
                    try await function()
                }
                let duration = ContinuousClock.now - start
                return MeasurementResult(duration: duration, stats: stats)
            }

            private struct MeasurementResult {
                let duration: Duration
                let stats: MemoryAllocation.AllocationStats
            }
        }

        @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
        extension TestingPerformance {
            struct Configuration: Sendable {
                var enabled: Bool
                var iterations: Int
                var warmup: Int
                var printResults: Bool
                var threshold: Duration?
                var metric: Metric
                var maxAllocations: Int?
                var detectLeaks: Bool
                var peakMemoryLimit: Int?

                init(
                    enabled: Bool = true,
                    iterations: Int = 10,
                    warmup: Int = 0,
                    printResults: Bool = false,
                    threshold: Duration? = nil,
                    metric: Metric = .median,
                    maxAllocations: Int? = nil,
                    detectLeaks: Bool = false,
                    peakMemoryLimit: Int? = nil
                ) {
                    self.enabled = enabled
                    self.iterations = iterations
                    self.warmup = warmup
                    self.printResults = printResults
                    self.threshold = threshold
                    self.metric = metric
                    self.maxAllocations = maxAllocations
                    self.detectLeaks = detectLeaks
                    self.peakMemoryLimit = peakMemoryLimit
                }

                func merged(with other: Configuration) -> Configuration {
                    Configuration(
                        enabled: other.enabled,
                        iterations: other.iterations,
                        warmup: other.warmup,
                        printResults: other.printResults,
                        threshold: other.threshold ?? self.threshold,
                        metric: other.metric,
                        maxAllocations: other.maxAllocations ?? self.maxAllocations,
                        detectLeaks: other.detectLeaks,
                        peakMemoryLimit: other.peakMemoryLimit ?? self.peakMemoryLimit
                    )
                }
            }
        }

        // MARK: - Public API

        @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
        extension Trait where Self == _PerformanceTrait {
            /// Measure test execution time with detailed statistics
            ///
            /// Automatically prints performance measurements and optionally enforces
            /// a performance threshold.
            ///
            /// Basic usage:
            /// ```swift
            /// @Test(.timed())
            /// func operation() {
            ///     numbers.sum()
            /// }
            /// ```
            ///
            /// With threshold enforcement:
            /// ```swift
            /// @Test(.timed(threshold: .milliseconds(50)))
            /// func fastOperation() {
            ///     numbers.sum()
            /// }
            /// ```
            ///
            /// Custom configuration:
            /// ```swift
            /// @Test(.timed(iterations: 100, warmup: 5, threshold: .milliseconds(10)))
            /// func preciseOperation() {
            ///     numbers.sum()
            /// }
            /// ```
            ///
            /// With allocation limit:
            /// ```swift
            /// @Test(.timed(threshold: .milliseconds(30), maxAllocations: 1024))
            /// func noExtraAllocations() {
            ///     numbers.sum()  // Should iterate without copying
            /// }
            /// ```
            ///
            /// - Parameters:
            ///   - iterations: Number of measurement runs (default: 10)
            ///   - warmup: Number of untimed warmup runs (default: 0)
            ///   - threshold: Optional performance budget - test fails if exceeded
            ///   - maxAllocations: Optional memory allocation limit in bytes - test fails if exceeded
            ///   - metric: Metric to check against threshold (default: .median)
            ///
            /// - Note: Always prints performance statistics. Use `.serialized` on suite
            ///   to avoid interference between tests.
            public static func timed(
                iterations: Int = 10,
                warmup: Int = 0,
                threshold: Duration? = nil,
                maxAllocations: Int? = nil,
                metric: TestingPerformance.Metric = .median,
                detectLeaks: Bool = false,
                peakMemoryLimit: Int? = nil
            ) -> Self {
                Self(
                    configuration: TestingPerformance.Configuration(
                        iterations: iterations,
                        warmup: warmup,
                        printResults: true,
                        threshold: threshold,
                        metric: metric,
                        maxAllocations: maxAllocations,
                        detectLeaks: detectLeaks,
                        peakMemoryLimit: peakMemoryLimit
                    )
                )
            }

            /// Enable memory leak detection for performance tests
            ///
            /// Automatically detects memory leaks during test execution.
            /// Test fails if net allocations remain after completion.
            ///
            /// ```swift
            /// @Test(.timed(), .detectLeaks())
            /// func `no memory leaks`() {
            ///     // Test automatically fails if memory leaks
            /// }
            /// ```
            public static func detectLeaks() -> Self {
                Self(
                    configuration: TestingPerformance.Configuration(
                        detectLeaks: true
                    )
                )
            }

            /// Track peak memory usage with optional limit
            ///
            /// Monitors peak memory throughout test iterations.
            /// Test fails if peak exceeds specified limit.
            ///
            /// ```swift
            /// @Test(.timed(), .trackPeakMemory(limit: 10_000_000))
            /// func `stay under memory budget`() {
            ///     // Test fails if peak memory exceeds 10MB
            /// }
            /// ```
            ///
            /// - Parameter limit: Optional maximum peak memory in bytes
            public static func trackPeakMemory(limit: Int? = nil) -> Self {
                Self(
                    configuration: TestingPerformance.Configuration(
                        peakMemoryLimit: limit
                    )
                )
            }
        }

    #endif  // compiler(>=6.0)
#endif  // canImport(Testing)
