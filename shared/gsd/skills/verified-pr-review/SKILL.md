---
name: verified-pr-review
description: Use when asked to review a GitHub (or similar) pull request, especially against linked tickets (Linear/Jira). Performs deep source-level verification beyond the diff — traces claims in code comments, docstrings, and author replies back to the actual implementation (including native/platform code) instead of trusting them — then writes prioritized P0/P1/P2 findings to a markdown doc with per-item approval checkboxes, produces a copy-paste-ready companion doc for manual posting, and only posts comments to the PR after explicit per-item human approval, correctly anchored to what the platform's diff actually allows.
---

## When to use this

Triggered by requests like "review this PR", "review PR #N against ticket X", or any ask to produce PR feedback that should NOT be posted automatically. Also applies to Azure DevOps PRs (same principles, different API surface — use the `azure_devops_repo_*` tools instead of `gh`).

Two hard defaults unless the user says otherwise:
1. **Never post to the PR without explicit, per-item approval.** Write findings to a file first.
2. **Verify everything against primary sources.** A docstring, PR description, or author reply is a claim to check, not a fact to repeat.

## Phase A — Gather ground truth

1. Fetch the PR itself, including its **full existing review-thread history** (every prior bot/human comment, not just the current diff). Use `pr://<owner>/<repo>/<N>` (read tool) or `gh pr view <N> --json ...`.
2. Fetch any linked tickets (Linear/Jira/etc.) via the proper API/MCP tool — `mcp__linear_get_issue`, not a raw browser fetch of the ticket URL (SPA ticket trackers are usually JS-rendered and auth-walled; raw fetch returns nothing useful).
3. Cross-check the PR title/description against the ticket's actual title — flag a mismatch as a P2 (e.g. PR cites the wrong ticket number).
4. Pull the **full unified diff**: `gh pr diff <N> --repo <owner>/<repo> > /tmp/prN.diff`, then read it completely (paginate with `:N-M` selectors if long — never guess at collapsed regions).
5. Confirm the local checkout's branch **and exact commit SHA** match the PR's head commit — this isn't optional bookkeeping, Phase B's whole approach (reading full current files for context, trusting local line numbers) only produces correct results when local files actually reflect the PR's state:
   ```bash
   git branch --show-current; git log -1 --oneline
   gh pr view <N> --json headRefOid -q .headRefOid
   ```
   If they don't match, **never force a checkout**. Instead:
   - Run `git status --short`. If there are uncommitted changes, stop and ask the user how they want to proceed (stash, commit, or work diff-only) — do not stash or discard anything yourself.
   - If the tree is clean, ask permission before checking out the PR's branch/commit (a plain "review this PR" doesn't imply consent to switch branches out from under other work the user may have queued in that same checkout).
   - If they decline, or you're working somewhere checkout isn't possible, fall back to diff-only analysis: read file content via `gh api`/the platform's file-content endpoint instead of the local filesystem, and translate every line reference through the diff's hunk headers rather than local line numbers.

## Phase B — Verify beyond the diff

6. For every changed function/file, read the **full current source**, not just the diff hunk — you need real surrounding context, not a 3-line window.
7. Grep for every production call site of any changed function/hook/component. Do not stop at the first hit — confirm you've found the *primary* entry point, not just *an* entry point (a floating "resume" button and a menu item that both call the same hook are not equally important).
8. **Trace every claim to its source before repeating it.** If a docstring says "X can't happen because Y," or the author replies "we'll fix this later," or the PR description says "this fixes Z" — go read the actual implementation (including native iOS/Android/backend code if relevant) and confirm or refute it explicitly. Never write a finding that rests on an untraced claim; mark anything you genuinely can't verify as `[INFERENCE]`.
9. Check tooling/config assumptions (lint rules, feature flags, env gating) by reading the actual config file — don't assume a rule exists or doesn't.

## Phase B.5 — Optional cross-check with the `code-review` skill

Once the local checkout is confirmed on the PR's head commit (Phase A, step 5), you can optionally dispatch the separate `code-review` skill against the same PR as an independent second opinion. It runs two parallel sub-agents in isolated context (a Standards axis and a Spec axis), so it won't just echo back what you already found — it's a genuinely different pass, not a summary of this one.

- Fixed point = the PR's base branch (e.g. `origin/master`, `origin/develop` — whatever the PR is opened against). Head = the checkout from Phase A.
- Spec source = the linked ticket(s) from Phase A, step 2.
- **This is additive, never a replacement.** Keep doing Phases B and C yourself regardless of what it returns.
- Fold its Standards/Spec output into your own P0/P1/P2 buckets (Phase C) using the *same* verification discipline as everything else — a finding from the sub-agents still needs source-level confirmation before it goes in the doc. Being machine-generated is not a pass.
- Skip this phase by default. Only run it when the user explicitly asks for extra rigor (e.g. "make this state of the art," "double-check with code-review too") — it roughly doubles the review's cost for a second, more mechanical pass, so don't spend that budget unasked.

## Phase C — Synthesize into prioritized findings

10. Bucket findings by severity — `P0` (blocking, breaks the PR's own stated purpose or ships a user-visible failure), `P1` (should fix, not blocking), `P2` (minor/nice-to-have). Number them `P0-1`, `P0-2`, `P1-1`, etc. — these IDs are the cross-reference key for every other artifact in this workflow.
11. Each finding gets: what's wrong (plain statement), the evidence trail (files/lines/what you read to confirm it), a suggested fix, honest confidence (if something can't be verified from this repo alone, say so) — **and a ready-to-post reply comment**, always, for every postable finding (not just when a manual-posting companion is requested). The reply comment must be:
    - Plain, simple language — no jargon, no P0/P1/severity labels, no "traced/verified/confirmed" narration.
    - Precise and concise — lead with the user-visible symptom, one sentence on the fix if there is one.
    - Written for the PR author to read once and immediately understand, with zero back-and-forth needed.
    Keep the technical evidence trail and the reply comment as two clearly separate blocks under the same finding — the evidence trail is for the reviewer's own reference; only the reply comment ever gets posted.
12. **Before finalizing any suggested code fix, trace every other consumer of anything you're about to change.** A shared gating function used by three call sites can't be "fixed" for one without checking what it breaks for the other two — this is the single most common way a well-intentioned suggestion introduces a regression.
13. Include a "what's already good" section — findings-only reviews read as one-sided and erode trust. Close with a one-paragraph bottom line.

## Phase D — Write the review doc (approval-gated)

14. **Before picking a path, check for an existing convention** — glob for prior review docs (`docs/reviews/*.md`, `reviews/*.md`, or similar). If the repo already has any, match that location and naming pattern exactly; don't introduce a second convention beside an existing one. If nothing turns up, ask the user where they'd like it saved, defaulting to `docs/reviews/PR-<N>-review.md` only if they have no preference. Write the file, explicitly stating at the top: **not posted anywhere yet**.
15. Give every postable finding two checkboxes plus its reply text, unchecked/blank by default:
    ```md
    - [ ] Approved and post
    - [ ] Review posted

    **Reply to post:**
    > (plain-language text goes here)
    ```
    `Approved and post` = human greenlights it. `Review posted` = you check this yourself, with a link, only after actually posting.
 3. If one finding needs multiple separate PR comments (e.g. three call sites needing the same one-line fix), split it into labeled sub-items (`P1-1a`, `P1-1b`, `P1-1c`), each with its own checkbox pair **and its own `Reply to post` text** — they're independent postable units, and each one's reply should be scoped to what's true at that specific file/line, not a copy-pasted shared blurb.

## Phase E — Anchor every suggestion to what the platform actually allows

17. **Before promising an inline comment/suggestion location, verify the platform's real constraint — don't infer it from a hunk's context header.** For GitHub:
    ```bash
    gh api /repos/<owner>/<repo>/pulls/<N>/files --jq '.[] | select(.filename=="<path>") | .patch'
    ```
    Read the `@@ -a,b +c,d @@` header literally: only new-file lines `c` through `c+d-1` are in the diff. The function/class name GitHub prints after `@@` is a navigation aid, not proof those lines are visible — a hunk can start well inside a function body.
18. If a fix needs edits in two places that land in different (or no) hunks, **split into separate comments** rather than one suggestion block spanning both — a single suggestion block is a literal line-range replacement; stitching unrelated regions together corrupts the file (e.g. dropping a new `import` in the middle of a file full of other statements instead of at the top).
19. If the correct fix location isn't in the diff at all (common when the real root cause is in a file the PR didn't touch), don't force an inline anchor — make it a **general PR comment** instead and say so explicitly in the doc.

## Phase F — Produce a manual-posting companion (on request)

20. If the human wants to post by hand rather than have you post via API, write a **second, separate file** (e.g. `docs/reviews/PR-<N>-manual-comments.md`):
    - Same `P0-N`/`P1-N` IDs as the main doc, so the two stay cross-referenced.
    - Same two checkboxes per item, explicitly noted as tracking *their* manual posting, separate from checkboxes that track *your* API posting.
    - Literal click-by-click platform UI steps once at the top (where to click, "Start a review" vs "Add single comment," how to submit).
    - Plain, ready-to-paste comment text per item — no jargon, no priority-tier language, no code-review vocabulary. Lead with the user-facing symptom, not the technical mechanism.

## Phase G — Post and record

21. Before posting anything, re-read the doc to find which items have `Approved and post` checked **and** `Review posted` still unchecked — that's the exact set to post, nothing else.
22. Get the exact head commit SHA (`gh pr view <N> --json headRefOid`), build the API payload using the finding's **Reply to post** text verbatim as the comment body (never the technical write-up) with correct `path`/`start_line`/`line`/`side` (GitHub: `POST /repos/<owner>/<repo>/pulls/<N>/comments`), post it.
23. Immediately mark `Review posted` for that item with a link to the live comment/thread as proof — in every doc that tracks it.
24. Never batch-post items that aren't approved, even if they seem obviously correct.

## Communication adaptation (orthogonal to the above)

If the audience shifts (e.g. reviewer wants technical detail, PR author needs plain language), rewrite the *explanation*, never the underlying finding — same evidence, same fix, same `P0-N` ID, just different framing. Lead with the user-visible symptom before the code-level mechanism when writing for a non-reviewer audience.

## Anti-patterns this workflow exists to prevent

- Reviewing the diff summary/description instead of the actual current source.
- Repeating a docstring's or author's claim without checking it against the implementation.
- Suggesting a fix to a shared/shared-dependency function without checking its other consumers.
- Assuming a line is commentable because it's near a diff hunk, without checking the literal hunk boundaries.
- Posting anything before explicit per-item approval.
- One suggestion block spanning two unrelated edits, corrupting file structure when applied.
- Treating a sub-agent's (e.g. `code-review` skill's) output as pre-verified just because it came from a separate pass.
