import XCTest
@testable import MacUtilityKit

final class MUKPasteInjectorTests: XCTestCase {
    func testPasteKeyFollowsTheCurrentLayout() {
        // Resolved with ⌘ held, so "Dvorak – QWERTY ⌘" style layouts get the key that is V with ⌘.
        XCTAssertEqual(MUKPasteInjector.pasteKeyCode, MUKKeyboardLayout.keyCode(for: "v", commandHeld: true) ?? 9)
    }
}
