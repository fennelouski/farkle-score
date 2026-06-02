# App Store Screenshot Automation

This project uses Fastlane `snapshot` + `ScreenshotTests` to generate deterministic App Store screenshots for iPhone, iPad, and macOS.

## Prerequisites

- Xcode 26.x (26.4.1 recommended to match CI)
- Ruby + Bundler
- Available simulators matching `fastlane/Snapfile`

## One-time setup

From repository root:

```bash
bundle install
```

If simulator names drift after Xcode updates, inspect and update `fastlane/Snapfile`:

```bash
xcrun simctl list devices available | grep -E "iPhone|iPad Pro|Mac"
```

## Generate screenshots

```bash
bundle exec fastlane screenshots
```

This runs:

- scheme: `Farkle Score. Screenshots`
- test plan: `Farkle Score.Screenshots`
- tests: `Farkle Score.UITests/ScreenshotTests`

## Output

Generated images are written under:

- `screenshots/en-US/`

Each device folder contains named captures:

- `01_ScoreKeypad`
- `02_MidGame`
- `03_Players`
- `04_Settings`
- `05_RulesLibrary`

## Uploading to App Store Connect

- Open App Store Connect media manager for your version.
- Drag images from `screenshots/en-US/` into matching device slots.
- Keep only the best shots if more than one variant is generated for a size class.

## Troubleshooting

- **No screenshots generated:** verify `ScreenshotTests` is discovered (`xcodebuild -showTestPlans -scheme "Farkle Score. Screenshots"`).
- **App launches with personal state:** ensure launch arg `-screenshotMode` is present (configured in `Snapfile` and tests), and no custom UI test overrides remove it.
- **Cloud sync popups/spinners in shots:** screenshot mode disables CloudKit sync paths; if this reappears, check `ScreenshotMode.isEnabled` usage in `Farkle_Score_App`.
- **Mac screenshot sizing inconsistent:** `ScreenshotMode.configureMacWindowIfNeeded()` enforces a fixed window frame on launch.
