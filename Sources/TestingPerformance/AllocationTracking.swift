// AllocationTracking.swift
// TestingPerformance
//
// Memory allocation tracking for performance tests

@_exported import MemoryAllocation

extension TestingPerformance {
    /// Memory allocation statistics
    ///
    /// Type alias to `MemoryAllocation.AllocationStats` for convenience.
    public typealias AllocationStats = MemoryAllocation.AllocationStats

    /// Capture current allocation statistics
    ///
    /// Delegates to `MemoryAllocation.AllocationStats.capture()`.
    static func captureAllocationStats() -> AllocationStats {
        return AllocationStats.capture()
    }

    #if os(Linux)
        /// Enable allocation tracking on Linux
        ///
        /// Delegates to `MemoryAllocation.AllocationStats.startTracking()`.
        public static func startTracking() {
            AllocationStats.startTracking()
        }

        /// Disable allocation tracking on Linux
        ///
        /// Delegates to `MemoryAllocation.AllocationStats.stopTracking()`.
        public static func stopTracking() -> AllocationStats {
            return AllocationStats.stopTracking()
        }
    #endif
}
