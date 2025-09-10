import XCTest
@testable import GuitarAccuracy

final class PatternSwitchingTests: XCTestCase {
    func testPatternMultiplierValues() {
        XCTAssertEqual(MetronomeMath.multiplier(for: .quarter), 1)
        XCTAssertEqual(MetronomeMath.multiplier(for: .eighth), 2)
        XCTAssertEqual(MetronomeMath.multiplier(for: .eighthTriplet), 3)
        XCTAssertEqual(MetronomeMath.multiplier(for: .sixteenth), 4)
        XCTAssertEqual(MetronomeMath.multiplier(for: .sixteenthTriplet), 6)
    }
}
