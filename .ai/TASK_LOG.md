# CaffeinateBar Task Log

Keep this concise. Record outcomes and decisions, not full chat transcripts.

## 2026-06-26
- Generated Claude/context handoff files.
- Added `.ai/` documentation structure for project continuity.

## 2026-09-17
- Date: 2026-09-17
- Request: Compare remote branch vs local, unify changes, resolve conflicts; determine app status re: multi-language localization and review-request feature.
- Files changed: Fast-forwarded `main` to `origin/main` (schemes, English strings). Merged `origin/claude/caffeinate-cancel-notifications-vjy5jr` into `main` — adds 34-language `Localizable.strings` for app+widget, cancellation notifications, xcodeproj registration fixes.
- Decisions: User approved merging the unmerged localization branch into local `main` after a clean dry-run (`git merge-tree`). Merge itself required no manual conflict resolution. Left push to `origin/main` for a separate explicit approval. Also fixed `~/.claude/settings.json` `DEVELOPER_DIR` (pointed at a removed Xcode beta) so `git`/`xcodebuild` work again this session.
- Verification: `xcodebuild ... CaffeinateBar ... build` → BUILD SUCCEEDED post-merge.
- Follow-ups: push to origin (pending approval), fix duplicate `en.lproj/Localizable.strings` group membership in pbxproj (cosmetic), decide on untracked `.ai/`/`CLAUDE.md`/`icon/*` files, consider deleting merged remote branch after push.

## 2026-09-17 (follow-up)
- Date: 2026-09-17
- Request: "haz el commit con el push, agrega los archivos no trackeados, limpia" — commit+push, add untracked files, clean up the pbxproj warning.
- Files changed: Committed `.ai/*`, `CLAUDE.md`, `icon/image.png`, `icon/images/iconcaffeinatebar.png`, `icon/instalaltion background.png`, `icon/promo.png` (commit `6bb9c8f`). Fixed `CaffeinateBar.xcodeproj/project.pbxproj`: removed duplicate direct-group children for the app/widget "en" file references (they now live only inside their `PBXVariantGroup`), and removed two stray `PBXBuildFile` entries (`A10000029`, `A10000030`) that had each target's Resources phase building the *other* target's raw English strings file (commit `ac5997d`).
- Decisions: Split into two commits (docs/assets vs. pbxproj fix) for a cleaner history. Pushed both to `origin/main`.
- Verification: Rebuilt both `CaffeinateBar` and `CaffeinateBarWidget` schemes (Debug/macOS) after the fix — BUILD SUCCEEDED, no more "member of multiple groups" warning.
- Follow-ups: none required; optionally delete the now-merged remote branch `claude/caffeinate-cancel-notifications-vjy5jr` (ask first).

## 2026-09-17 (donations)
- Date: 2026-09-17
- Request: Add a "Support CaffeinateBar" / "Apoyar CaffeinateBar" section giving access to tips for the developer.
- Files changed: New `CaffeinateBar/TipJarStore.swift` (StoreKit 2 tip products + `AppDistribution` App-Store-vs-direct-download detection). `MenuBarView.swift` got a new SUPPORT accordion section + `TipJarView`. Registered in `project.pbxproj`. Localized (en/es).
- Decisions: App Store build gets real StoreKit consumable tips (product IDs `com.local.CaffeinateBar.tip.{small,medium,large}`, proposed by me, not yet created in App Store Connect). Direct-download build gets a PayPal.me link (`https://paypal.me/landercorp`, provided by user) — user explicitly said PayPal is *only* for the non-App-Store version. Distribution detected via `appStoreReceiptURL` (kept despite macOS 15 deprecation — documented why in code comment).
- Verification: Both schemes build successfully. Could not visually test the popover UI live (see follow-up session's verification notes on AppleScript automation risk).
- Follow-ups: create the 3 IAP products in App Store Connect before this works on the App Store build.

## 2026-09-17 (interactive widget + onboarding)
- Date: 2026-09-17
- Request: Make the widget interactive (allow some actions) and add a tutorial/onboarding view for the app.
- Files changed: `CaffeinateBarWidget/WidgetIntents.swift` (new, widget target only — `ToggleCaffeinateIntent`, `CancelTimeoutIntent`), `CaffeinateBarWidget/CaffeinateBarWidget.swift` (interactive buttons on `.systemMedium`, dropped the now-dead macOS-13 `containerBackground` fallback), `CaffeinateBar/SharedWidgetState.swift` (+`PendingWidgetAction`, pending-action get/set), `CaffeinateBar/CaffeinateManager.swift` (publishes `timeoutPreset` to shared state), `CaffeinateBar/AppDelegate.swift` (consumes pending widget actions on launch/activate), `CaffeinateBar/OnboardingView.swift` + `OnboardingWindowController.swift` (new — first-ever `NSWindow` in this app), "Show Tutorial" button in Settings. `project.pbxproj`: registered new files, raised **only** `CaffeinateBarWidget` target's `MACOSX_DEPLOYMENT_TARGET` to 14.0 (app target stays 13.0).
- Decisions (user-confirmed): widget actions = Toggle + Cancel active timer; widget deployment target bumped to macOS 14 alone (app keeps macOS 13 support, widget just won't appear there); onboarding shows once automatically + reopenable from Settings. Verified via web research that `Button(intent:)` requires macOS 14+ and can crash on macOS 13 even behind `#available`, so no in-body version branching was used — the whole widget target's minimum was raised instead. Also verified (web research) that an AppIntent's `perform()` may run in either the extension or host-app process depending on app state, so `perform()` only ever touches shared UserDefaults (safe in both), never `CaffeinateManager` directly; the actual toggle/cancel happens in `AppDelegate` once the host app is confirmed active.
- Verification: both schemes build successfully after every change. **Live UI was not verified**: tried AppleScript/System Events to click the menu bar icon and screenshot, but a synthetic click nearly hit Xcode's menu bar on the user's live, cluttered multi-window desktop (Accessibility-point vs. screencapture-pixel coordinate mismatch) — stopped immediately for safety rather than keep guessing coordinates. Widget button rendering also can't be checked by just launching the .app; it needs adding/refreshing the widget from the widget gallery, which requires the user's hands.
- Follow-ups: user should manually verify the onboarding window and the widget's interactive buttons; reset onboarding for a re-test via `defaults delete com.local.CaffeinateBar onboarding.completed`.

## 2026-09-22/23 (App Store submission prep + reconciling parallel Codex work)
- Date: 2026-09-22/23
- Request: Create the 3 tip-jar IAP consumables (done via Loxi, not this repo), then "ya quedaron los consumibles en tienda que procede para subir a tienda?" — figure out what's left to submit v1.1 to the App Store.
- Files changed: Discovered and reconciled a parallel Codex session's work (issues #2/#3/#4, all closed) already in the working tree: version bump to 1.1/build 2 (`project.pbxproj`, `project.yml`), `CFBundleDisplayName` typo fix, `.gitignore` (+`.asc/artifacts/`), 32-locale translation of the SUPPORT/HELP/onboarding strings, `metadata/version/1.1/*.json` (35 locales), and a built+signed `.asc/artifacts/CaffeinateBar-1.1.pkg`. Reverted one undiscussed change: `CaffeinateManager.swift`'s `minimumCompletedSessions` (Codex had changed 2→1; reverted to 2).
- Decisions: Committed the accumulated work (mine from prior sessions + Codex's) as 3 grouped commits: (1) tip jar/widget/onboarding feature + version bump + full localization (can't cleanly split from Codex's pbxproj/localization changes — they landed in the same files), (2) App Store release metadata, (3) repo housekeeping (.gitignore, AGENTS.md, CLAUDE.md BotMonitor section, .ai/ docs).
- Verification: Rebuilt `CaffeinateBar` scheme after the revert — BUILD SUCCEEDED.
- Follow-ups: Everything for the v1.1 App Store submission is staged and blocked on one thing — `asc auth login` has never been completed on this machine (confirmed independently by this session and by Codex's). Once authenticated: `asc metadata push`, `asc validate` (check for IAP review-screenshot requirements — none exist yet), then `asc publish appstore --submit --confirm`.

## Template
- Date:
- Request:
- Files changed:
- Decisions:
- Verification:
- Follow-ups:
