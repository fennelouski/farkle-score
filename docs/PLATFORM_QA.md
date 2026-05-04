# Multiplatform smoke checklist

Run before each store submission.

## iPadOS

- Split View and Slide Over: narrow column uses stacked layout; score entry and history remain reachable.
- Stage Manager: resize window through compact width; sheets show drag indicator and dismiss predictably.
- External keyboard: **⌘Z** undoes the last score entry (from the app menu).

## macOS

- Window resize: `GameRootView` two-column layout appears at adequate width.
- Settings sheet respects minimum size (`SettingsView`).
- Avatar images save under Application Support inside the sandbox (same paths as `AvatarImageStore`).

## visionOS

- Launch app window; confirm main score UI and Settings open.
- Photo-based avatars: `PhotosPicker` path; camera UI is iOS-only by design.

## App Store Connect assets

- Capture screenshots per required size classes: iPhone, iPad Pro (12.9" and 11" as required), Mac (windowed), Apple Vision (if listing on visionOS store).
- Match **Privacy Policy URL** and **Support URL** with `FarklePrivacyPolicyURL` / `FarkleSupportURL` in Info.plist and with the Nutrition Labels (iCloud, optional photos for avatars, no third-party trackers).
