# CaffeinateBar Coding Rules

Last updated: 2026-06-26

## General Rules
- Read relevant files before editing.
- Keep changes narrowly scoped.
- Prefer existing project patterns over introducing new abstractions.
- Do not revert user changes unless explicitly asked.
- Avoid unrelated formatting churn.
- Add comments only when they clarify non-obvious logic.
- Update tests or verification notes when behavior changes.

## Verification
Before finishing, run the cheapest useful validation available for this repo. Examples:
- Swift/iOS: Xcode build, Swift Package tests, or `swiftc -parse` when Xcode is unavailable.
- JavaScript/TypeScript: lint, typecheck, or tests from `package.json`.
- Android/Kotlin: Gradle build or targeted tests.
- Python: unit tests or import/type checks.

If verification cannot run, explain exactly why.

## Documentation Hygiene
When the project changes meaningfully, update:
- `.ai/CURRENT_STATE.md`
- `.ai/TASK_LOG.md`
- Any relevant README or product docs.
