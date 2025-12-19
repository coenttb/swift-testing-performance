// Threshold.swift
// TestingPerformance
//
// Platform-specific performance thresholds

/// Platform-specific performance threshold
///
/// Allows different performance budgets per platform:
/// ```swift
/// @Test(.timed(threshold: .platform(
///     macOS: .milliseconds(30),
///     iOS: .milliseconds(50),
///     linux: .milliseconds(25)
/// )))
/// ```
///
/// - Note: Available on platforms with Duration support (macOS 13+, iOS 16+, watchOS 9+, tvOS 16+)
public struct Threshold: Sendable {
    public let macOS: Duration?
    public let iOS: Duration?
    public let watchOS: Duration?
    public let tvOS: Duration?
    public let linux: Duration?
    public let windows: Duration?

    /// Create a platform-specific threshold
    public init(
        macOS: Duration? = nil,
        iOS: Duration? = nil,
        watchOS: Duration? = nil,
        tvOS: Duration? = nil,
        linux: Duration? = nil,
        windows: Duration? = nil
    ) {
        self.macOS = macOS
        self.iOS = iOS
        self.watchOS = watchOS
        self.tvOS = tvOS
        self.linux = linux
        self.windows = windows
    }
}

extension Threshold {
    /// Create a threshold that applies to all platforms
    public static func all(_ duration: Duration) -> Threshold {
        Threshold(
            macOS: duration,
            iOS: duration,
            watchOS: duration,
            tvOS: duration,
            linux: duration,
            windows: duration
        )
    }

    /// Create a threshold for Apple platforms only
    public static func apple(_ duration: Duration) -> Threshold {
        Threshold(
            macOS: duration,
            iOS: duration,
            watchOS: duration,
            tvOS: duration
        )
    }

    /// Create a threshold for Darwin platforms (macOS, iOS, watchOS, tvOS)
    public static func darwin(_ duration: Duration) -> Threshold {
        apple(duration)
    }

    /// Get the threshold for the current platform
    public var current: Duration? {
        #if os(macOS)
            return macOS
        #elseif os(iOS)
            return iOS
        #elseif os(watchOS)
            return watchOS
        #elseif os(tvOS)
            return tvOS
        #elseif os(Linux)
            return linux
        #elseif os(Windows)
            return windows
        #else
            return nil
        #endif
    }
}

extension Threshold: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init()
    }
}
