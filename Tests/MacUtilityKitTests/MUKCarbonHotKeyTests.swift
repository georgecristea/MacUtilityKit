import Carbon.HIToolbox
import XCTest
@testable import MacUtilityKit

@MainActor
final class MUKCarbonHotKeyTests: XCTestCase {
    func testCarbonModifierMapping() {
        XCTAssertEqual(MUKCarbonHotKey.carbonModifiers([.command, .shift]), UInt32(cmdKey | shiftKey))
        XCTAssertEqual(MUKCarbonHotKey.carbonModifiers([.control, .option]), UInt32(controlKey | optionKey))
        XCTAssertEqual(MUKCarbonHotKey.carbonModifiers([]), 0)
    }

    func testRegistersAndStops() {
        // A combination nobody uses: ⌃⌥⇧⌘F19.
        let rare = MUKHotkey(keyCode: UInt16(kVK_F19), modifiers: [.control, .option, .shift, .command])
        let hotKey = MUKCarbonHotKey(binding: rare) {}
        XCTAssertTrue(hotKey.isRegistered)
        hotKey.stop()
        XCTAssertFalse(hotKey.isRegistered)
        XCTAssertTrue(hotKey.update(binding: rare))
        XCTAssertTrue(hotKey.isRegistered)
        hotKey.stop()
    }

    func testOnlyOwnSignatureDispatches() {
        let rare = MUKHotkey(keyCode: UInt16(kVK_F18), modifiers: [.control, .option, .shift, .command])
        var fired = 0
        let hotKey = MUKCarbonHotKey(binding: rare) { fired += 1 }
        defer { hotKey.stop() }
        let ours = EventHotKeyID(signature: MUKCarbonHotKey.signature, id: hotKey.id)
        let foreign = EventHotKeyID(signature: OSType(0x4F54_4852), id: hotKey.id) // another library, same id
        XCTAssertNil(MUKCarbonHotKey.action(for: foreign))
        MUKCarbonHotKey.action(for: ours)?()
        XCTAssertEqual(fired, 1)
    }

    func testModifierOnlyBindingIsNotRegistered() {
        let hotKey = MUKCarbonHotKey(binding: MUKHotkey(keyCode: nil, modifiers: [.command])) {}
        XCTAssertFalse(hotKey.isRegistered)
    }
}

final class MUKHotkeyRecorderTests: XCTestCase {
    func testModifierOnlyCandidatesFollowTheOption() {
        let modifierOnly = MUKHotkey(keyCode: nil, modifiers: [.control, .function])
        let withKey = MUKHotkey(keyCode: 9, modifiers: [.command, .shift])
        XCTAssertTrue(MUKHotkeyRecorder.accepts(modifierOnly, allowsModifierOnly: true))
        XCTAssertFalse(MUKHotkeyRecorder.accepts(modifierOnly, allowsModifierOnly: false))
        XCTAssertTrue(MUKHotkeyRecorder.accepts(withKey, allowsModifierOnly: false))
    }
}
