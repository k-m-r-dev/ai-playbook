# How to use do-chores

Say `do chores` to do the next small task in the `.w2c/` plan. Add `M011` or `S02` to stay inside that scope. Add `--max-units 5` to do several tasks in a row. Add `--dry-run` to see the next task without doing it.

Scope only picks the queue. Without `--max-units` the skill always stops after one task.

**Need first:** requesting-code-review. If it is missing, the skill stops and tells you to add it.

**Need in the repo:** `.w2c/scripts/` from `scripts/install-w2c-to-project.sh`.

Progress logs stay on the machine under `.w2c/runtime/` and are not committed.
