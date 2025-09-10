import XCTest
@testable import GuitarAccuracy

final class MetronomeMathTests: XCTestCase {
    private func assertApproxEqual(_ a: Double, _ b: Double, tolerance: Double = 1e-6, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertLessThanOrEqual(abs(a - b), tolerance, file: file, line: line)
    }

    func testTicksPerSecond_quarter_notes() {
        let hz = MetronomeMath.ticksPerSecond(bpm: 120, pattern: .quarter)
        assertApproxEqual(hz, 2.0)
    }

    func testTicksPerSecond_eighth_notes() {
        let hz = MetronomeMath.ticksPerSecond(bpm: 120, pattern: .eighth)
        assertApproxEqual(hz, 4.0)
    }

    func testTicksPerSecond_eighth_triplets() {
        let hz = MetronomeMath.ticksPerSecond(bpm: 120, pattern: .eighthTriplet)
        assertApproxEqual(hz, 6.0)
    }

    func testTicksPerSecond_sixteenth_notes() {
        let hz = MetronomeMath.ticksPerSecond(bpm: 120, pattern: .sixteenth)
        assertApproxEqual(hz, 8.0)
    }

    func testTicksPerSecond_sixteenth_triplets() {
        let hz = MetronomeMath.ticksPerSecond(bpm: 120, pattern: .sixteenthTriplet)
        assertApproxEqual(hz, 12.0)
    }
}
