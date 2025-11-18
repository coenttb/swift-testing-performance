// Duration.swift
// TestingPerformance
//
// Internal extensions for Swift standard library Duration

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension Duration {
    /// Create a Duration from seconds (internal utility)
    static func seconds(_ value: Double) -> Duration {
        let components = value.splitIntegerAndFraction()
        return .seconds(Int64(components.integer))
            + .nanoseconds(Int64(components.fraction * 1_000_000_000))
    }

    /// Convert Duration to seconds as Double (internal utility)
    var inSeconds: Double {
        let (seconds, attoseconds) = self.components
        return Double(seconds) + (Double(attoseconds) / 1_000_000_000_000_000_000.0)
    }

    /// Convert Duration to milliseconds (internal utility)
    var inMilliseconds: Double {
        inSeconds * 1000
    }

    /// Convert Duration to microseconds (internal utility)
    var inMicroseconds: Double {
        inSeconds * 1_000_000
    }

    /// Convert Duration to nanoseconds (internal utility)
    var inNanoseconds: Double {
        inSeconds * 1_000_000_000
    }
}

extension Double {
    fileprivate func splitIntegerAndFraction() -> (integer: Int64, fraction: Double) {
        let integer = Int64(self)
        let fraction = self - Double(integer)
        return (integer, fraction)
    }
}
