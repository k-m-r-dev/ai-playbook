/**
 * Host-verify + publish after gsd_task_complete returns nextStage=verify.
 */
import { randomUUID } from "node:crypto";
import { hostname } from "node:os";
import { importGsd } from "./resolve-gsd.mjs";
import { openProjectDb, assertInsideProject } from "./project.mjs";

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

export async function taskPublish(params) {
  const {
    milestoneId,
    sliceId,
    taskId,
    attemptId: attemptIdInput,
    projectRoot: projectRootInput,
    verifyCommand,
    exitCode = 0,
    observation,
  } = params;
  if (!milestoneId || !sliceId || !taskId) {
    throw new Error("milestoneId, sliceId, and taskId are required");
  }

  const ctx = await openProjectDb(projectRootInput);
  const { projectRoot, gsdRoot } = ctx;
  assertInsideProject(projectRoot, projectRoot);

  const { readLatestTaskAttempt, readTaskAttempt } = await importGsd(
    "task-execution-domain-operation.js",
    gsdRoot,
  );
  const { recordTaskTechnicalVerdict } = await importGsd(
    "task-verification-domain-operation.js",
    gsdRoot,
  );
  const { publishVerifiedTaskCompletion } = await importGsd(
    "task-completion-compatibility-adapter.js",
    gsdRoot,
  );
  const { captureVerificationSourceSnapshot } = await importGsd(
    "verification-source-integrity.js",
    gsdRoot,
  );

  const task = { milestoneId, sliceId, taskId };
  const latest = readLatestTaskAttempt(task);
  const attemptId = attemptIdInput || latest?.attemptId;
  if (!attemptId) {
    throw new Error(`No Attempt found for ${milestoneId}/${sliceId}/${taskId}`);
  }
  const attempt = readTaskAttempt(attemptId) || latest;
  if (!attempt) {
    throw new Error(`Attempt ${attemptId} not found`);
  }
  if (attempt.nextStage !== "verify") {
    throw new Error(
      `Attempt ${attemptId} nextStage=${attempt.nextStage}; publish requires verify (call gsd_task_complete first)`,
    );
  }

  const source = captureVerificationSourceSnapshot([
    { id: "project", cwd: projectRoot },
  ]);
  if (!source.ok) {
    throw new Error(`Verification source snapshot failed: ${source.error}`);
  }

  const passed =
    observation === "passed" ||
    (observation == null && Number(exitCode) === 0);
  const startedAt = new Date().toISOString();
  const endedAt = new Date().toISOString();
  const command = verifyCommand || "playbook-host-verify";

  recordTaskTechnicalVerdict({
    invocation: inv(`playbook/verdict/${attemptId}/${randomUUID()}`),
    attemptId,
    testedSourceRevision: source.snapshot.aggregateRevision,
    verdict: passed ? "pass" : "fail",
    rationale: passed
      ? "Playbook external host verification passed."
      : "Playbook external host verification failed.",
    evidence: {
      evidenceClass: "command",
      commandOrTool: command,
      workingDirectory: projectRoot,
      startedAt,
      endedAt,
      exitCode: Number(exitCode),
      observation: passed ? "passed" : "failed",
      durableOutputRef: `db://host-verification/${attemptId}`,
      environment: {
        runner: "playbook-gsd-external-executor",
        host: hostname(),
      },
    },
  });

  if (!passed) {
    return {
      status: "verify-failed",
      attemptId,
      unitId: `${milestoneId}/${sliceId}/${taskId}`,
      projectRoot,
    };
  }

  const published = await publishVerifiedTaskCompletion({
    invocation: inv(`playbook/publish/${attemptId}/${randomUUID()}`),
    basePath: projectRoot,
    task,
    attemptId,
  });

  return {
    status: published.status || "published",
    attemptId,
    summaryPath: published.summaryPath,
    unitId: `${milestoneId}/${sliceId}/${taskId}`,
    projectRoot,
  };
}
