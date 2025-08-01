import Foundation
import UIKit

// MARK: - Protocols for Dependency Injection

protocol Logger {
  func log(_ message: String)
}

protocol TokenStore {
  func storeToken(_ token: String)
  func getToken() -> String?
}

// MARK: - Default Implementations

class DefaultLogger: Logger {
  func log(_ message: String) {
    print("[SDK] \(message)")
  }
}

class DefaultTokenStore: TokenStore {
  private let userDefaults = UserDefaults.standard
  private let tokenKey = "miniSDK_pushToken"

  func storeToken(_ token: String) {
    userDefaults.set(token, forKey: tokenKey)
  }

  func getToken() -> String? {
    return userDefaults.string(forKey: tokenKey)
  }
}

// MARK: - MiniSDK Singleton

class MiniSDK {
  static let shared = MiniSDK()

  private var isInitialized = false
  private var apiKey: String?
  private var enableBase64Encoding = false

  private let logger: Logger
  private let tokenStore: TokenStore
  private let queue = DispatchQueue(label: "com.minisdk.queue", attributes: .concurrent)

  private init(logger: Logger = DefaultLogger(), tokenStore: TokenStore = DefaultTokenStore()) {
    self.logger = logger
    self.tokenStore = tokenStore
    setupLifecycleTracking()
  }

  // MARK: - Test Helper (Internal)

  internal convenience init(testLogger: Logger, testTokenStore: TokenStore) {
    self.init(logger: testLogger, tokenStore: testTokenStore)
  }

  // MARK: - Public API

  func initialize(apiKey: String, enableBase64: Bool = false) {
    queue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }

      if self.isInitialized {
        DispatchQueue.main.async {
          self.logger.log("SDK was already initialized. Reinitializing...")
        }
      }

      self.apiKey = apiKey
      self.enableBase64Encoding = enableBase64
      self.isInitialized = true

      DispatchQueue.main.async {
        self.logger.log("Initialized with API Key: \(apiKey)")
      }
    }
  }

  func sendPushToken(token: String) {
    queue.async { [weak self] in
      guard let self = self else { return }

      self.tokenStore.storeToken(token)

      let finalToken = self.enableBase64Encoding ? token.toBase64() : token

      DispatchQueue.main.async {
        self.logger.log("Push Token Sent: \(finalToken)")
      }
    }
  }

  func trackEvent(name: String, payload: [String: Any]? = nil) {
    queue.async { [weak self] in
      guard let self = self else { return }

      DispatchQueue.main.async {
        if let payload = payload {
          let payloadString = self.formatPayload(payload)
          self.logger.log("Event: \(name), Payload: \(payloadString)")
        } else {
          self.logger.log("Event: \(name)")
        }
      }
    }
  }

  // MARK: - Internal Methods

  internal func trackPushReceived(payload: [String: Any]? = nil) {
    trackEvent(name: "push_received", payload: payload)
  }

  internal func trackPushOpened(payload: [String: Any]? = nil) {
    trackEvent(name: "push_opened", payload: payload)
  }

  // MARK: - Private Methods

  private func setupLifecycleTracking() {
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.trackEvent(name: "app_foregrounded")
    }

    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.trackEvent(name: "app_backgrounded")
    }
  }

  private func formatPayload(_ payload: [String: Any]) -> String {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
      return String(data: jsonData, encoding: .utf8) ?? "{}"
    } catch {
      return "{}"
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

// MARK: - String Extension for Base64

private extension String {
  func toBase64() -> String {
    return Data(utf8).base64EncodedString()
  }
}
