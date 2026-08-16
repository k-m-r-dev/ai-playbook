# MXXX: TITLE

**Vision:**

## Success Criteria

## Slices

## Boundary Map

## In scope

## Out of scope

## Soft dependency

## Delivery & Guardrails
| Field | Value |
| --- | --- |
| Milestone / planning ID | MXXX |
| Human-readable scope slug | SLUG |
| Workstream name | |
| External ticket ID | |
| Integration strategy | trunk-direct |
| Integration branch | |
| Commit cadence | milestone |
| Review unit | none |
| Git/PR checkpoint mode | none |
| Branch name | N/A |
| Execution sequence | |
| Validation commands | |
| Completion condition | All slices verified; single commit after milestone verification; push only with explicit approval |
| Size budget (LOC diff) | |

### Guardrails
- **Commit cadence** — one commit after the milestone is verified unless this table says otherwise. Do not commit per slice by default.
- **Remote mutation** — no push, PR, or remote git mutation without explicit user approval.
- **Validation** — run the validation commands in this table before each commit and before each push.
- **Status writes** — never hand-edit STATE.md, QUEUE.md, ROADMAP status emojis, or task checkboxes. Use `.w2c/scripts/w2c.sh`.
- **Verify loop** — a task is not complete until its Verify commands pass and requesting-code-review is clean.
