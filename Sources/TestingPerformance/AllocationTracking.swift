// AllocationTracking.swift
// TestingPerformance
//
// Memory allocation tracking for performance tests

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

extension TestingPerformance {
    /// Memory allocation statistics
    public struct AllocationStats: Sendable {
        public let allocations: Int
        public let deallocations: Int
        public let bytesAllocated: Int

        public var netAllocations: Int {
            allocations - deallocations
        }

        init(allocations: Int = 0, deallocations: Int = 0, bytesAllocated: Int = 0) {
            self.allocations = allocations
            self.deallocations = deallocations
            self.bytesAllocated = bytesAllocated
        }

        static func delta(from start: AllocationStats, to end: AllocationStats) -> AllocationStats {
            AllocationStats(
                allocations: end.allocations - start.allocations,
                deallocations: end.deallocations - start.deallocations,
                bytesAllocated: end.bytesAllocated - start.bytesAllocated
            )
        }
    }
}

extension TestingPerformance {
    /// Capture current allocation statistics
    ///
    /// Platform-specific implementation that tracks memory allocations.
    /// Returns zero stats if allocation tracking is unavailable.
    static func captureAllocationStats() -> TestingPerformance.AllocationStats {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            return captureAllocationStatsDarwin()
        #elseif os(Linux)
            return captureAllocationStatsLinux()
        #else
            return Performance.AllocationStats()
        #endif
    }

    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        private static func captureAllocationStatsDarwin() -> TestingPerformance.AllocationStats {
            var stats = malloc_statistics_t()
            malloc_zone_statistics(nil, &stats)

            return TestingPerformance.AllocationStats(
                allocations: Int(stats.blocks_in_use),
                deallocations: 0,  // Not directly available from malloc_statistics_t
                bytesAllocated: Int(stats.size_in_use)
            )
        }
    #endif

    #if os(Linux)
        private static func captureAllocationStatsLinux() -> TestingPerformance.AllocationStats {
            // On Linux, we use mallinfo2 if available (glibc 2.33+)
            // This is a simplified implementation
            // In production, might want to use jemalloc statistics or similar
            #if canImport(Glibc)
                let info = mallinfo()
                return Performance.AllocationStats(
                    allocations: 0,  // mallinfo doesn't track count
                    deallocations: 0,
                    bytesAllocated: Int(info.uordblks)
                )
            #else
                return Performance.AllocationStats()
            #endif
        }
    #endif
}
