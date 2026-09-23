# CLAUDE.md

You are working in `CaffeinateBar`.

## First Steps
1. Read `.ai/PROJECT_BRIEF.md`.
2. Read `.ai/CURRENT_STATE.md`.
3. Inspect relevant source files before editing.
4. Briefly state the intended change before modifying files.

## Working Rules
- Keep changes scoped to the user's request.
- Prefer existing patterns and local helper APIs.
- Do not add dependencies, services, or broad rewrites without explicit approval.
- Do not revert user changes unless explicitly requested.
- Preserve app/product copy and visual direction unless the task asks to change it.
- Run the most relevant available verification before finishing.
- If verification cannot run, explain why and what remains unverified.

## Context Files
Use these files for project memory:
- `.ai/PROJECT_BRIEF.md`
- `.ai/ARCHITECTURE.md`
- `.ai/CODING_RULES.md`
- `.ai/CURRENT_STATE.md`
- `.ai/TASK_LOG.md`
- `.ai/PROMPTS.md`

## End Of Session
When meaningful changes are made, update `.ai/CURRENT_STATE.md` and `.ai/TASK_LOG.md` with the outcome, verification, and follow-ups.

<!-- BOTMONITOR_REPORTING_BEGIN -->
## BotMonitor Reporting

This repository reports agent work to BotMonitor through GitHub issues. When Claude starts, advances, blocks, or finishes a task, keep the related issue current.

Required workflow:
- Before implementation or review, find or create a GitHub issue for the task.
- Add label `agent:claude` and `status:in-progress` while actively working.
- Add label `owner:misael` when the task belongs to Misael or requires his final decision.
- Add a short progress comment when a meaningful milestone is reached.
- If the task includes images, screenshots, App Store copy, or other context, keep those paths/text in the issue body or latest progress comment under a `Context` section.
- If user input is required, add label `status:needs-intervention`, remove `status:in-progress`, and comment with the exact decision or asset needed.
- When complete, comment with changed files and verification, then close the issue or label it `status:done`.

Preferred commands:
```sh
gh issue list --state open --limit 30
gh issue create --title "<task>" --body "<scope, plan, acceptance>" --label "agent:claude,status:in-progress"
gh issue comment <number> --body "<progress update>"
gh issue edit <number> --add-label "status:needs-intervention" --remove-label "status:in-progress"
gh issue close <number> --comment "<summary and tests>"
```

Keep updates concise and factual. Do not include secrets, tokens, private keys, or credential file contents in issues.
<!-- BOTMONITOR_REPORTING_END -->