import XCTest
@testable import MacUtilityKit

final class MUKKeyboardLayoutTests: XCTestCase {
    func testVHasAKeyInTheCurrentLayout() {
        XCTAssertNotNil(MUKKeyboardLayout.keyCode(for: "v"))
    }

    func testLetterKeysRoundTrip() {
        var letters = 0
        for code in CGKeyCode(0)..<128 {
            guard let c = MUKKeyboardLayout.character(for: code), c.count == 1, c.first!.isLetter else { continue }
            letters += 1
            let back = MUKKeyboardLayout.keyCode(for: c)
            XCTAssertNotNil(back)
            XCTAssertEqual(back.flatMap(MUKKeyboardLayout.character(for:)), c)
        }
        XCTAssertGreaterThanOrEqual(letters, 20, "the current layout should type at least 20 letters")
    }

    func testCharactersAreLowercase() {
        guard let code = MUKKeyboardLayout.keyCode(for: "v") else { return XCTFail("no v") }
        XCTAssertEqual(MUKKeyboardLayout.character(for: code), "v")
    }
}
