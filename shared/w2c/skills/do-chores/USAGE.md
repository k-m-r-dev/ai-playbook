# How to use do-chores

Say `do chores` to do the next small task in the `.w2c/` plan. Add `M011` or `S02` to stay inside that scope. Add `--max-units 5` to do several tasks in a row. Add `--dry-run` to see the next task and planned git isolation (worktree vs branch) without doing either.

Scope only picks the queue. Without `--max-units` the skill always stops after one task.

The skill follows the plan’s **Git Operation Plan**: on the first unit it sets up or reuses the ticket worktree/branch, then implements only inside that isolation. After a milestone is verified it will remind you to push — only with your explicit approval, and only to the planned remote branch name (ticket id / confirmed slug).

**Need first:** requesting-code-review. If it is missing, the skill stops and tells you to add it. If the plan’s Isolation mode is `worktree`, **using-git-worktrees** must also be invocable.

**Need in the repo:** `.w2c/scripts/` from `scripts/install-w2c-to-project.sh`.

Progress logs stay on the machine under `.w2c/runtime/` and are not committed. Task/slice/milestone summaries and UAT/validation reports live in the plan folder and are committed.
