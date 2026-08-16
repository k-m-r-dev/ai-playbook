---
MILESTONE ID: MXXX
SLICE ID: SXX
---

# SXX: TITLE

**Goal:**
**Demo:**

## Must-Haves

## Threat Surface

## Proof Level

## Integration Closure

## Verification

- Run the task and slice verification checks for this slice.

<tasks>
</tasks>

## Files Likely Touched

### Guardrails
- Do not mark tasks complete by editing checkboxes. Use `.w2c/scripts/w2c.sh complete`.
- A task is not done until Verify passes, requesting-code-review is clean, and `S##-T##-SUMMARY.md` is written.
- After the last task in this slice: re-run Verify, write `S##-UAT.md` + `S##-SUMMARY.md`, then `slice-complete`.
- After the last slice: write `M###-VALIDATION.md` + `M###-SUMMARY.md`, then `milestone-complete`.
- No push or PR without explicit user approval.
