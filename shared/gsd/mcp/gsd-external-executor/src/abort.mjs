/**
 * Interrupt a running Attempt claimed by the playbook bridge.
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

export async function taskAbort(params) {
  const {
    milestoneId,
    sliceId,
    taskId,
    attemptId: attemptIdInput,
    reason = "Playbook external executor aborted",
    projectRoot: projectRootInput,
  } = params;
  if (!milestoneId || !sliceId || !taskId) {
    throw new Error("milestoneId, sliceId, and taskId are required");
  }

  const ctx = await openProjectDb(projectRootInput);
  const { projectRoot, gsdRoot } = ctx;
  const { readLatestTaskAttempt, settleTaskAttempt } = await importGsd(
    "task-execution-domain-operation.js",
    gsdRoot,
  );
  const { releaseMilestoneLease } = await importGsd(
    "db/milestone-leases.js",
    gsdRoot,
  );

  const task = { milestoneId, sliceId, taskId };
  const latest = readLatestTaskAttempt(task);
  const attemptId = attemptIdInput || latest?.attemptId;
  if (!attemptId || !latest) {
    return {
      status: "noop",
      reason: "no-attempt",
      unitId: `${milestoneId}/${sliceId}/${taskId}`,
      projectRoot,
    };
  }
  if (latest.state !== "running") {
    return {
      status: "noop",
      reason: `attempt-state-${latest.state}`,
      attemptId,
      unitId: `${milestoneId}/${sliceId}/${taskId}`,
      projectRoot,
    };
  }

  const settled = settleTaskAttempt({
    invocation: inv(`playbook/abort/${attemptId}/${randomUUID()}`),
    attemptId,
    outcome: "interrupted",
    failureClass: "executor-interrupted",
    summary: reason,
    output: { reason, abortedBy: "playbook-gsd-external-executor" },
    recovery: {
      workerId: latest.workerId,
      milestoneLeaseToken: latest.milestoneLeaseToken,
    },
  });

  try {
    releaseMilestoneLease(
      latest.workerId,
      milestoneId,
      latest.milestoneLeaseToken,
    );
  } catch {
    /* lease may already be released by settle */
  }

  return {
    status: "aborted",
    attemptId,
    resultId: settled.resultId,
    nextStage: settled.nextStage,
    unitId: `${milestoneId}/${sliceId}/${taskId}`,
    projectRoot,
  };
}
