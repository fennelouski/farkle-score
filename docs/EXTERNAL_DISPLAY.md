# External Display (AirPlay / HDMI) Setup

How this app shows a different layout on a second screen than on the phone, and how to replicate it in any SwiftUI-lifecycle app. No storyboards required.

## Why this is confusing

By default, iOS mirrors the phone to an AirPlay or wired display. To show *different* content, the system must hand your app a scene with the role `.windowExternalDisplayNonInteractive` (iOS 16+ name). Most tutorials show a UIKit + storyboard setup; SwiftUI apps have a gotcha that makes the usual delegate-only approach fail silently: **with the SwiftUI `App` lifecycle, `application(_:configurationForConnecting:options:)` is not reliably called for the external-display role unless the scene configuration is also declared in the Info.plist scene manifest.** Miss that and the system just mirrors, with no error anywhere.

## The three pieces

### 1. Info.plist scene manifest (the piece everyone misses)

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleExternalDisplayNonInteractive</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>External Scoreboard</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).ExternalSceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

Notes:

- `UISceneDelegateClassName` must be module-qualified. `$(PRODUCT_MODULE_NAME)` expands at build time (here to `Farkle_Score_`). Verify the built product with `plutil -p <app>/Info.plist` — if the name is wrong there is no runtime error, just mirroring.
- Do not declare the main window role; SwiftUI keeps managing it.
- If the target generates its Info.plist, make sure your custom plist is set as `INFOPLIST_FILE` and remove `INFOPLIST_KEY_UIApplicationSceneManifest_Generation` so the two don't fight.
- Deployment targets below iOS 16 also need the legacy `UIWindowSceneSessionRoleExternalDisplay` key. This app targets 17.6, so it is omitted.

### 2. App delegate routing (belt and suspenders)

`FarkleAppDelegate.swift` — attached with `@UIApplicationDelegateAdaptor` in `Farkle_Score_App`:

```swift
func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
) -> UISceneConfiguration {
    if connectingSceneSession.role == .windowExternalDisplayNonInteractive {
        let configuration = UISceneConfiguration(
            name: "External Scoreboard",   // must match the plist name
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = ExternalSceneDelegate.self
        return configuration
    }
    return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
}
```

Keep both this and the plist entry, with matching configuration names. Whichever path iOS takes, it lands on the same delegate.

### 3. Scene delegate + window controller

`ExternalDisplay/ExternalSceneDelegate.swift` receives connect/disconnect and forwards to `ExternalDisplayController.shared`, which owns the `UIWindow`:

```swift
let host = UIHostingController(rootView: ExternalScoreboardView()
    .environment(gameStore)
    .environment(profileStore))
let window = UIWindow(windowScene: scene)
window.rootViewController = host
window.isHidden = false   // not makeKeyAndVisible(); the external window must not steal key status
```

`ExternalDisplayController` also handles: stores registered once at app launch (`register(gameStore:profileStore:)` from `Farkle_Score_App.init`), the user toggle (`AppSettings.externalDisplayEnabled`, Settings → "Apple TV & External Screens"), and appearance overrides. When the toggle is off it tears the window down and the system falls back to mirroring.

## Testing

- **Simulators cannot attach external displays.** Use the DEBUG launch arguments instead: `-externalDisplayPreview` renders `ExternalScoreboardView` in the main window; `-externalDisplayPreviewIdle` shows the idle state. Add `-farkle.appearanceMode dark` for the TV look.
- **Hardware:** run the app on a device, Control Center → Screen Mirroring → Apple TV, foreground the app. The TV should switch from mirror to the scoreboard.
- If it still mirrors: check the merged Info.plist in the built product first, then the settings toggle (an empty scene looks identical to mirroring).
