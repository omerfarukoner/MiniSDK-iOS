import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    MiniSDK.shared.initialize(apiKey: "sample-key", enableBase64: true)

    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    requestNotificationPermission()
    application.registerForRemoteNotifications()

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = ViewController()
    window?.makeKeyAndVisible()

    return true
  }

  private func requestNotificationPermission() {
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions) { _, error in
        if let error = error {
          print("[SDK] Notification permission error: \(error)")
        }
      }
  }

  // MARK: - Remote Notifications

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("[SDK] Failed to register for remote notifications: \(error)")
  }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken = fcmToken else { return }
    MiniSDK.shared.sendPushToken(token: fcmToken)
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    let payload = convertToStringAnyDict(userInfo)
    MiniSDK.shared.trackPushReceived(payload: payload)

    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    let payload = convertToStringAnyDict(userInfo)
    MiniSDK.shared.trackPushOpened(payload: payload)
    completionHandler()
  }

  private func convertToStringAnyDict(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
    var payload: [String: Any] = [:]
    for (key, value) in userInfo {
      if let stringKey = key as? String {
        payload[stringKey] = value
      }
    }
    return payload
  }
}
