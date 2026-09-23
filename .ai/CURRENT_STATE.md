# CaffeinateBar Current State

Last updated: 2026-09-17

## Status
macOS menu bar app (CaffeinateBar) + CaffeinateBarWidget extension. Version bumped to **1.1 (build 2)**. Builds successfully on Debug/macOS for both schemes. A release archive + signed `.pkg` already exist locally (`.asc/artifacts/CaffeinateBar-1.1.pkg`, built by a parallel Codex session — see TASK_LOG), and App Store release metadata for 35 locales is staged in `metadata/version/1.1/`. The 3 tip-jar consumables were created directly in App Store Connect via Loxi (not via this repo's tooling). Blocked only on `asc auth login` (no ASC API credentials configured anywhere on this machine yet) before the actual upload/submit step.

## What Works
- Non-intrusive App Store review prompt (`RatingPromptController` in `CaffeinateBar/CaffeinateManager.swift`): triggers only after ≥2 completed sessions, once per app version, 90-day cooldown, via `SKStoreReviewController.requestReview()`.
- Localization: app + widget now have `Localizable.strings` for 34 languages (en, es, ar, ca, cs, da, de, el, fi, fr, he, hi, hr, hu, id, it, ja, ko, ms, nb, nl, pl, pt-BR, pt-PT, ro, ru, sk, sv, th, tr, uk, vi, zh-Hans, zh-Hant), registered in the xcodeproj. New "SUPPORT"/"HELP" copy is localized in en/es only; other 32 languages fall back to English until translated.
- Cancellation notifications (sleep/shutdown/low battery) with translated strings.
- macOS status widget (SharedWidgetState) and shared Xcode schemes.
- **Tip jar / "Apoyar CaffeinateBar" section** (`TipJarStore.swift`, wired in `MenuBarView.swift`): App Store build shows StoreKit 2 consumable tip tiers (`com.local.CaffeinateBar.tip.{small,medium,large}` — **must still be created in App Store Connect**, currently placeholders); non-App-Store build shows a PayPal.me link (`https://paypal.me/landercorp`) via `AppDistribution.isAppStoreBuild` (receipt-presence check).
- **Interactive widget** (macOS 14+ only — `CaffeinateBarWidget` target's deployment target was raised to 14.0, app stays at 13.0): `.systemMedium` widget shows Toggle (play/stop) and, when a timed session is running, a Cancel-timer button, via `ToggleCaffeinateIntent`/`CancelTimeoutIntent` (`CaffeinateBarWidget/WidgetIntents.swift`). Both intents just record a `PendingWidgetAction` in the shared App Group defaults and rely on `openAppWhenRun` to activate the (LSUIElement, so invisible) host app; `AppDelegate.consumePendingWidgetAction()` (called from `applicationDidFinishLaunching` and `applicationDidBecomeActive`) performs the actual toggle/cancel via `CaffeinateManager`. macOS 13 users simply won't see the widget at all (extension deployment target above their OS).
- **Onboarding** (`OnboardingView.swift` + `OnboardingWindowController.swift`): the app's first-ever real `NSWindow` (everything else lives in the status-item `NSPopover`). 5-page walkthrough, shown automatically on first launch (`UserDefaults` key `onboarding.completed`), reopenable via "Show Tutorial" in SETTINGS → HELP (posts `.showOnboardingRequested`, observed in `AppDelegate`).

## Known Issues
- Widget interactivity and onboarding were implemented but **not visually verified live** — see Verification Notes. `appStoreReceiptURL` (used by `AppDistribution`) is deprecated in macOS 15 in favor of `AppTransaction`; kept intentionally (see comment in `TipJarStore.swift`) since the replacement is async/throwing with unclear behavior for non-App-Store builds.
- **Fixed 2026-09-23**: only `en`/`es` were ever registered as children of the `Localizable.strings` `PBXVariantGroup` (app + widget) despite all 34 `.lproj` folders existing on disk since the original localization merge — the other 32 languages, including Codex's SUPPORT/HELP translations, were never actually copied into the built app bundle. Confirmed by inspecting `.asc/artifacts/CaffeinateBar-1.1.xcarchive` (only 2 `.lproj` folders present). Fixed by registering all 32 missing locales in both `PBXVariantGroup`s; verified the rebuilt app/widget bundles now contain all 34 `.lproj` folders. **The staged `.asc/artifacts/CaffeinateBar-1.1.pkg` is now stale and must be rebuilt** (`asc xcode archive` + `asc xcode export`) before submitting — it was exported before this fix.
- No IAP review screenshots exist yet for the 3 tip-jar consumables — Apple may require one per new in-app purchase before it can go to review. Not confirmed either way; `asc validate` (once authenticated) should surface this if it's blocking.
- `asc auth` has no stored credentials on this machine (confirmed independently by this session and by a separate Codex session — same blocker across both) — nothing that touches the App Store Connect API (metadata push, `asc validate`, `asc publish appstore`) can run until an API key is added via `asc auth login`.
- Consider deleting the now-merged remote branch `claude/caffeinate-cancel-notifications-vjy5jr` on GitHub (not done — ask before deleting a remote branch).

## In Progress
- Final push to submit v1.1 to the App Store — everything is staged (archive, pkg, metadata, IAPs), waiting only on ASC API auth.

## Next Steps
1. **Rebuild the release archive/pkg** — the current `.asc/artifacts/CaffeinateBar-1.1.pkg` predates the localization fix and only has en/es baked in.
2. Run `asc auth login` (API key with Admin role — needed for certs too, see earlier IAP/Developer-ID work).
3. `asc metadata push --app <APP_ID> --version "1.1" --platform MAC_OS --dir ./metadata` (dry-run first).
4. `asc validate --app <APP_ID> --version "1.1"` — canonical readiness report; check specifically for IAP review-screenshot requirements.
5. `asc publish appstore --app <APP_ID> --pkg .asc/artifacts/CaffeinateBar-1.1.pkg --version 1.1 --build-number 2 --metadata-dir ./metadata --submit --confirm`.
5. Manually verify onboarding (reset via `defaults delete com.local.CaffeinateBar onboarding.completed` then relaunch, or SETTINGS → HELP → "Show Tutorial") and the widget's buttons (add/refresh from the widget gallery on macOS 14+) — still not done via automation, see Verification Notes.
6. Consider deleting the merged remote branch `claude/caffeinate-cancel-notifications-vjy5jr` (ask first).

## Verification Notes
- 2026-09-17: `xcodebuild -project CaffeinateBar.xcodeproj -scheme 'CaffeinateBar' -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED** after merge, and again after the pbxproj cleanup with no warnings.
- 2026-09-17: `xcodebuild ... -scheme 'CaffeinateBarWidget' ... build` → **BUILD SUCCEEDED**, no warnings.
- 2026-09-17: Pushed `main` to `origin/main` (`c45adbd..ac5997d`). Local and remote `main` are in sync.
- 2026-09-17: Added tip jar (StoreKit 2 + PayPal fallback), interactive widget (macOS 14+, `Button(intent:)`), and first-launch onboarding window. Both app and widget schemes rebuilt successfully after each change (`BUILD SUCCEEDED`, no new warnings).
- 2026-09-17: Attempted live UI verification (menu bar popover) via AppleScript/System Events synthetic clicks — a synthetic click nearly landed on Xcode's menu bar on the user's live, multi-window desktop instead of the app's status item (coordinate-space mismatch between Accessibility points and `screencapture` pixels). Stopped immediately rather than continue blind coordinate clicking; the tip jar/support section and onboarding/widget UI are **verified by successful compilation only**, not by interacting with the running app. The widget's interactive buttons additionally can't be verified by simply launching the .app — they require adding/refreshing the widget from the actual widget gallery (Notification Center), which needs the user to do manually.
- Note: `~/.claude/settings.json` had `DEVELOPER_DIR` pointing at a no-longer-installed `Xcode-27.0.0-Beta.2.app`; updated to `/Applications/Xcode.app/Contents/Developer` (only Xcode currently installed). Takes effect in new sessions.
- 2026-09-23: A parallel Codex session (GitHub issues #2, #3, #4, all closed) bumped the version to 1.1/build 2, fixed a `CFBundleDisplayName` typo ("Caffeinate Bat" → "CaffeinateBar"), built and signed the release archive/pkg, translated the SUPPORT/HELP/onboarding strings into all 32 remaining locales, and staged App Store metadata for 35 locales — all verified working. It also changed the rating prompt's `minimumCompletedSessions` from 2 to 1 without discussion; reverted back to 2 in this session.
