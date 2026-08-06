/**
 * Claim a running Attempt for external (non-auto) execution.
 * Execution-only — never mutates plan milestone/slice/task content rows beyond lifecycle claim.
 */
import { randomUUID } from "node:crypto";
import { hostname } from "node:os";
import { importGsd } from "./resolve-gsd.mjs";
import { openProjectDb } from "./project.mjs";

function inv(key) {
  return {
    idempotencyKey: key,
    sourceTransport: "workflow-mcp",
    actorType: "agent",
    actorId: `playbook-ext-${hostname()}-${process.pid}`,
    traceId: key,
    turnId: `playbook-${process.pid}`,
  };
}

export async function taskBegin(params) {
  const { milestoneId, sliceId, taskId, projectRoot: projectRootInput } =
    params;
  if (!milestoneId || !sliceId || !taskId) {
    throw new Error("milestoneId, sliceId, and taskId are required");
  }

  const ctx = await openProjectDb(projectRootInput);
  const { projectRoot, gsdRoot, adapter } = ctx;
  const {
    registerAutoWorker,
    heartbeatAutoWorker,
    getAutoWorker,
  } = await importGsd("db/auto-workers.js", gsdRoot);
  const { claimMilestoneLease } = await importGsd(
    "db/milestone-leases.js",
    gsdRoot,
  );
  const { recordDispatchClaim } = await importGsd(
    "db/unit-dispatches.js",
    gsdRoot,
  );
  const { claimTaskAttempt, readLatestTaskAttempt } = await importGsd(
    "task-execution-domain-operation.js",
    gsdRoot,
  );

  const unitId = `${milestoneId}/${sliceId}/${taskId}`;
  const taskRow = adapter()
    .prepare(
      `SELECT id, status FROM tasks
       WHERE milestone_id = ? AND slice_id = ? AND id = ?`,
    )
    .get(milestoneId, sliceId, taskId);
  if (!taskRow) {
    throw new Error(`Task not found in DB: ${unitId}`);
  }
  if (["complete", "done", "closed"].includes(String(taskRow.status))) {
    throw new Error(`Task already complete: ${unitId} status=${taskRow.status}`);
  }

  const latest = readLatestTaskAttempt({ milestoneId, sliceId, taskId });
  if (latest?.state === "running") {
    return {
      status: "already-running",
      attemptId: latest.attemptId,
      workerId: latest.workerId,
      coordinationDispatchId: latest.coordinationDispatchId,
      milestoneLeaseToken: latest.milestoneLeaseToken,
      unitId,
      projectRoot,
    };
  }

  const workerId = registerAutoWorker({ projectRootRealpath: projectRoot });
  // Prefer playbook namespace in diagnostics; registry still uses auto-* ids from gsd-pi.
  heartbeatAutoWorker(workerId);

  const lease = claimMilestoneLease(workerId, milestoneId);
  if (!lease.ok) {
    const detail =
      lease.error === "held_by"
        ? `held by ${lease.byWorker} until ${lease.expiresAt}`
        : JSON.stringify(lease);
    throw new Error(
      `Milestone lease unavailable for ${milestoneId}: ${detail}. Abort other auto workers or wait.`,
    );
  }

  const attemptN =
    latest && typeof latest.attemptNumber === "number"
      ? latest.attemptNumber + 1
      : 1;

  const dispatch = recordDispatchClaim({
    traceId: `playbook-ext-${randomUUID()}`,
    turnId: `playbook-${process.pid}`,
    workerId,
    milestoneLeaseToken: lease.token,
    milestoneId,
    sliceId,
    taskId,
    unitType: "execute-task",
    unitId,
    attemptN,
  });
  if (!dispatch.ok) {
    throw new Error(`recordDispatchClaim failed: ${JSON.stringify(dispatch)}`);
  }

  const claim = claimTaskAttempt({
    invocation: inv(`playbook/claim/${unitId}/${randomUUID()}`),
    task: { milestoneId, sliceId, taskId },
    workerId,
    milestoneLeaseToken: lease.token,
    coordinationDispatchId: dispatch.dispatchId,
    ...(latest?.attemptId && latest.state === "settled"
      ? { retryOfAttemptId: latest.attemptId }
      : {}),
  });

  // Touch worker so getAutoWorker stays meaningful for health/debug
  void getAutoWorker?.(workerId);

  return {
    status: "claimed",
    attemptId: claim.attemptId,
    attemptNumber: claim.attemptNumber,
    workerId,
    coordinationDispatchId: dispatch.dispatchId,
    milestoneLeaseToken: lease.token,
    unitId,
    projectRoot,
  };
}
