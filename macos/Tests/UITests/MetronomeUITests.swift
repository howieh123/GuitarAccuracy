import XCTest

final class MetronomeUITests: XCTestCase {
    func testControlsExist() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start"].exists || app.buttons["Stop"].exists)
        XCTAssertTrue(app.sliders.firstMatch.exists)
        // Look for any element with the identifier set on the Picker
        XCTAssertTrue(app.descendants(matching: .any)["patternPicker"].waitForExistence(timeout: 2))
    }
}
