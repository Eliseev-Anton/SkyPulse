import XCTest
@testable import SkyPulse

final class KeychainServiceTests: XCTestCase {

    private var mockKeychain: MockKeychainService!

    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychainService()
    }

    override func tearDown() {
        mockKeychain.clearAll()
        super.tearDown()
    }

    func testSaveAndRetrieve() {
        mockKeychain.save(key: "api_key", value: "12345")
        XCTAssertEqual(mockKeychain.retrieve(key: "api_key"), "12345")
    }

    func testUpdate() {
        mockKeychain.save(key: "token", value: "old")
        mockKeychain.update(key: "token", newValue: "new")
        XCTAssertEqual(mockKeychain.retrieve(key: "token"), "new")
    }

    func testDelete() {
        mockKeychain.save(key: "secret", value: "val")
        mockKeychain.delete(key: "secret")
        XCTAssertNil(mockKeychain.retrieve(key: "secret"))
    }

    func testContains() {
        XCTAssertFalse(mockKeychain.contains(key: "x"))
        mockKeychain.save(key: "x", value: "y")
        XCTAssertTrue(mockKeychain.contains(key: "x"))
    }

    func testRetrieveNonExistent() {
        XCTAssertNil(mockKeychain.retrieve(key: "missing"))
    }
}
