# Agent Instructions

<!-- BOTMONITOR_REPORTING_BEGIN -->
## BotMonitor Reporting

This repository reports agent work to BotMonitor through GitHub issues. When Codex starts, advances, blocks, or finishes a task, keep the related issue current.

Required workflow:
- Before implementation, find or create a GitHub issue for the task.
- Add label `agent:codex` and `status:in-progress` while actively working.
- Add label `owner:misael` when the task belongs to Misael or requires his final decision.
- Add a short progress comment when a meaningful milestone is reached.
- If the task includes images, screenshots, App Store copy, or other context, keep those paths/text in the issue body or latest progress comment under a `Context` section.
- If user input is required, add label `status:needs-intervention`, remove `status:in-progress`, and comment with the exact decision or asset needed.
- When complete, comment with changed files and verification, then close the issue or label it `status:done`.

Preferred commands:
```sh
gh issue list --state open --limit 30
gh issue create --title "<task>" --body "<scope, plan, acceptance>" --label "agent:codex,status:in-progress"
gh issue comment <number> --body "<progress update>"
gh issue edit <number> --add-label "status:needs-intervention" --remove-label "status:in-progress"
gh issue close <number> --comment "<summary and tests>"
```

Keep updates concise and factual. Do not include secrets, tokens, private keys, or credential file contents in issues.
<!-- BOTMONITOR_REPORTING_END -->