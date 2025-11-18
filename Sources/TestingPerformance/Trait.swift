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
    import Testing

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

                // Warmup
                for _ in 0..<config.warmup {
                    try await function()
                }

                // Measure
                var durations: [Duration] = []
                var allocationDeltas: [Int] = []

                for _ in 0..<config.iterations {
                    #if os(Linux)
                    if config.maxAllocations != nil {
                        TestingPerformance.startTracking()
                    }
                    #endif

                    let startStats = TestingPerformance.captureAllocationStats()
                    let start = ContinuousClock.now
                    try await function()
                    let duration = ContinuousClock.now - start
                    let endStats = TestingPerformance.captureAllocationStats()

                    durations.append(duration)

                    // Track allocation delta if we're monitoring allocations
                    if config.maxAllocations != nil {
                        let delta = TestingPerformance.AllocationStats.delta(
                            from: startStats,
                            to: endStats
                        )
                        allocationDeltas.append(delta.bytesAllocated)
                    }
                }

                let measurement = TestingPerformance.Measurement(durations: durations)

                // Print if requested
                if config.printResults {
                    TestingPerformance.printPerformance(
                        name,
                        measurement,
                        allocations: allocationDeltas.isEmpty ? nil : allocationDeltas
                    )
                }

                // Check threshold if set
                if let threshold = config.threshold {
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

                // Check allocation limit if set
                if let maxAllocations = config.maxAllocations, !allocationDeltas.isEmpty {
                    let maxAllocationBytes = allocationDeltas.max() ?? 0
                    guard maxAllocationBytes <= maxAllocations else {
                        throw TestingPerformance.Error.allocationLimitExceeded(
                            test: name,
                            limit: maxAllocations,
                            actual: maxAllocationBytes
                        )
                    }
                }

                // TODO: Baseline tracking not yet implemented
                // if let baselineName = config.baselineName {
                //     try await checkBaseline(...)
                // }
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

                init(
                    enabled: Bool = true,
                    iterations: Int = 10,
                    warmup: Int = 0,
                    printResults: Bool = false,
                    threshold: Duration? = nil,
                    metric: Metric = .median,
                    maxAllocations: Int? = nil
                ) {
                    self.enabled = enabled
                    self.iterations = iterations
                    self.warmup = warmup
                    self.printResults = printResults
                    self.threshold = threshold
                    self.metric = metric
                    self.maxAllocations = maxAllocations
                }

                func merged(with other: Configuration) -> Configuration {
                    Configuration(
                        enabled: other.enabled,
                        iterations: other.iterations,
                        warmup: other.warmup,
                        printResults: other.printResults,
                        threshold: other.threshold ?? self.threshold,
                        metric: other.metric,
                        maxAllocations: other.maxAllocations ?? self.maxAllocations
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
                metric: TestingPerformance.Metric = .median
            ) -> Self {
                Self(
                    configuration: TestingPerformance.Configuration(
                        iterations: iterations,
                        warmup: warmup,
                        printResults: true,
                        threshold: threshold,
                        metric: metric,
                        maxAllocations: maxAllocations
                    )
                )
            }
        }

    #endif  // compiler(>=6.0)
#endif  // canImport(Testing)
