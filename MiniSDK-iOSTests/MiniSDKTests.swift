import XCTest

@testable import MiniSDK_iOS

// MARK: - Mock Implementations

class MockLogger: Logger {
    var loggedMessages: [String] = []

    func log(_ message: String) {
        loggedMessages.append(message)
    }
}

class MockTokenStore: TokenStore {
    private var storedToken: String?

    func storeToken(_ token: String) {
        storedToken = token
    }

    func getToken() -> String? {
        return storedToken
    }
}

// MARK: - Test Cases

final class MiniSDKTests: XCTestCase {

    var mockLogger: MockLogger!
    var mockTokenStore: MockTokenStore!
    var testSDK: MiniSDK!

    override func setUp() {
        super.setUp()
        mockLogger = MockLogger()
        mockTokenStore = MockTokenStore()
        testSDK = MiniSDK(testLogger: mockLogger, testTokenStore: mockTokenStore)
    }

    override func tearDown() {
        testSDK = nil
        mockLogger = nil
        mockTokenStore = nil
        super.tearDown()
    }

    func testTrackEventWithoutPayload() {
        let expectation = XCTestExpectation(description: "Event logged")
        let eventName = "test_event"

        testSDK.trackEvent(name: eventName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockLogger.loggedMessages.contains("Event: \(eventName)"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testTrackEventWithPayload() {
        let expectation = XCTestExpectation(description: "Event with payload logged")
        let eventName = "button_clicked"
        let payload = ["screen": "Main", "timestamp": "2025-08-03"]

        testSDK.trackEvent(name: eventName, payload: payload)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let hasEventLog = self.mockLogger.loggedMessages.contains { message in
                message.contains("Event: \(eventName)") && message.contains("screen")
            }
            XCTAssertTrue(hasEventLog)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testInitializeSDK() {
        let apiKey = "test-api-key"
        let expectation = XCTestExpectation(description: "SDK initialized")

        testSDK.initialize(apiKey: apiKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(
                self.mockLogger.loggedMessages.contains("Initialized with API Key: \(apiKey)"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSendPushToken() {
        let token = "test-fcm-token"
        let expectation = XCTestExpectation(description: "Push token sent")

        testSDK.sendPushToken(token: token)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.mockTokenStore.getToken(), token)
            XCTAssertTrue(self.mockLogger.loggedMessages.contains("Push Token Sent: \(token)"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testReinitializeWarning() {
        let apiKey = "test-api-key"
        let expectation = XCTestExpectation(description: "Reinitialize warning")
        testSDK.initialize(apiKey: apiKey)
        testSDK.initialize(apiKey: apiKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let hasReinitMessage = self.mockLogger.loggedMessages.contains(
                "SDK was already initialized. Reinitializing...")
            XCTAssertTrue(hasReinitMessage)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testBase64Encoding() {
        let token = "abc123\n"
        let expectedBase64 = "YWJjMTIzCg=="
        let expectation = XCTestExpectation(description: "Base64 encoding")

        MiniSDK.shared.initialize(apiKey: "test", enableBase64: true)
        MiniSDK.shared.sendPushToken(token: token)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testPushEventTracking() {
        let payload = ["title": "Test Push", "body": "Test message"]
        let expectation = XCTestExpectation(description: "Push events tracked")

        MiniSDK.shared.trackPushReceived(payload: payload)
        MiniSDK.shared.trackPushOpened(payload: payload)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
