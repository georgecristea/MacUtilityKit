import XCTest
@testable import MacUtilityKit

final class MUKPasteInjectorTests: XCTestCase {
    func testPasteKeyFollowsTheCurrentLayout() {
        XCTAssertEqual(MUKPasteInjector.pasteKeyCode, MUKKeyboardLayout.keyCode(for: "v") ?? 9)
    }
}
