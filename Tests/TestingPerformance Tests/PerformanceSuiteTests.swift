// PerformanceSuiteTests.swift
// TestingPerformance
//
// PerformanceSuite tests

import Testing
import TestingPerformance

extension PerformanceTests {
    @Suite(.serialized)
    struct PerformanceSuiteTests {

        @Test
        func `performance suite basic usage`() {
            var suite = PerformanceSuite(name: "Array Operations")

            let sumResult = suite.benchmark("sum") {
                let numbers = Array(1...5_000)
                return numbers.reduce(0, +)
            }

            let mapResult = suite.benchmark("map") {
                let numbers = Array(1...5_000)
                return numbers.map { $0 * 2 }
            }

            #expect(sumResult > 0)
            #expect(mapResult.count == 5_000)

            // Print report (for manual inspection)
            suite.printReport()
        }

        @Test
        func `performance suite with custom iterations`() {
            var suite = PerformanceSuite(name: "String Operations")

            _ = suite.benchmark("concatenation", iterations: 20) {
                var result = ""
                for i in 1...100 {
                    result += String(i)
                }
                return result
            }

            _ = suite.benchmark("interpolation", iterations: 20) {
                var result = ""
                for i in 1...100 {
                    result += "\(i)"
                }
                return result
            }

            suite.printReport(metric: .median)
        }

        @Test
        func `performance suite async operations`() async {
            var suite = PerformanceSuite(name: "Async Operations")

            let result = await suite.benchmark("async delay", iterations: 5) {
                try? await Task.sleep(for: .milliseconds(1))
                return 42
            }

            #expect(result == 42)
            suite.printReport()
        }
    }
}
