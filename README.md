# MiniSDK iOS

A lightweight, thread-safe SDK for push notification handling and event tracking with dependency injection support.

## Features

- **Singleton Pattern**: Thread-safe implementation with concurrent queue
- **Firebase Integration**: FCM token management and notification handling  
- **Event Tracking**: Custom events with optional JSON payloads
- **Lifecycle Tracking**: Automatic app foreground/background detection
- **Base64 Encoding**: Optional token encoding for enhanced security
- **Testable Architecture**: Protocol-based dependency injection
- **Memory Safe**: Proper cleanup and weak references

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.0.0")
]
```

### Setup

1. **Firebase Configuration:**
   - Download `GoogleService-Info.plist` from your Firebase Console
   - Add the file to `MiniSDK-iOS/` directory in your Xcode project
   
2. **Initialize SDK:**

```swift
import Firebase

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    MiniSDK.shared.initialize(apiKey: "sample-key", enableBase64: true)
    return true
}
```

## Usage

### Initialize SDK
```swift
// Basic initialization
MiniSDK.shared.initialize(apiKey: "your-api-key")

// With Base64 encoding enabled
MiniSDK.shared.initialize(apiKey: "your-api-key", enableBase64: true)
```

### Track Events
```swift
// Simple event
MiniSDK.shared.trackEvent(name: "button_clicked")

// Event with payload
MiniSDK.shared.trackEvent(name: "user_action", payload: [
    "screen": "main",
    "timestamp": ISO8601DateFormatter().string(from: Date())
])
```

### Push Notifications
```swift
// Send FCM token
MiniSDK.shared.sendPushToken(token: fcmToken)

// Handle push events (automatically triggered)
// - push_received: When notification arrives
// - push_opened: When user taps notification
```

## Testing

### Unit Tests
```bash
swift test
# Or via Xcode: Product → Test (⌘U)
```

### Coverage
- ✅ Event tracking with/without payloads
- ✅ SDK initialization and reinitialization
- ✅ Push token handling with Base64 encoding
- ✅ Push notification event simulation
- ✅ Mock dependency injection

## Requirements

- iOS 15.0+
- Xcode 16.0+
- Swift 6.0+
- Firebase iOS SDK 12.0+