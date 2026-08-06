#!/usr/bin/env node
/**
 * Spike: claim → stageTaskCompletion → technicalVerdict → publish
 * against installed @opengsd/gsd-pi. Fail-closed; prints SPIKE RESULT.
 */
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, readFileSync } from "node:fs";
import { tmpdir, hostname } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import { randomUUID } from "node:crypto";

const require = createRequire(import.meta.url);
const GSD_ROOT =
  process.env.GSD_PI_ROOT ||
  dirname(dirname(dirname(require.resolve("@opengsd/gsd-pi/package.json"))));

const dist = (...parts) =>
  pathToFileURL(join(GSD_ROOT, "dist/resources/extensions/gsd", ...parts)).href;

async function main() {
  const pkg = JSON.parse(readFileSync(join(GSD_ROOT, "package.json"), "utf8"));
  console.log(`[spike] gsd-pi=${pkg.version} root=${GSD_ROOT}`);

  const {
    openDatabase,
    closeDatabase,
    _getAdapter,
  } = await import(dist("gsd-db.js"));
  const { registerAutoWorker, heartbeatAutoWorker } = await import(
    dist("db/auto-workers.js")
  );
  const { claimMilestoneLease, releaseMilestoneLease } = await import(
    dist("db/milestone-leases.js")
  );
  const { recordDispatchClaim } = await import(dist("db/unit-dispatches.js"));
  const { claimTaskAttempt, settleTaskAttempt, readLatestTaskAttempt } =
    await import(dist("task-execution-domain-operation.js"));
  const { stageTaskCompletion, publishVerifiedTaskCompletion } = await import(
    dist("task-completion-compatibility-adapter.js")
  );
  const { recordTaskTechnicalVerdict } = await import(
    dist("task-verification-domain-operation.js")
  );
  const { captureVerificationSourceSnapshot } = await import(
    dist("verification-source-integrity.js")
  );
  const {
    executeDomainOperation,
    // fence helpers live on writers
  } = await import(dist("db/domain-operation.js"));
  const { adoptOrTransitionLifecycle, readDomainOperationFence } = await import(
    dist("db/writers/lifecycle-commands.js")
  );

  const basePath = mkdtempSync(join(tmpdir(), "playbook-gsd-ext-"));
  const gsdDir = join(basePath, ".gsd");
  const phasesDir = join(gsdDir, "phases", "01-spike");
  mkdirSync(phasesDir, { recursive: true });
  const planPath = join(phasesDir, "01-01-PLAN.md");
  writeFileSync(
    planPath,
    `# S01\n\n- [ ] T01 Stage completion\n\nVerify: true\n`,
    "utf8",
  );
  writeFileSync(join(basePath, "README.md"), "spike\n", "utf8");
  execFileSync("git", ["init"], { cwd: basePath });
  execFileSync("git", ["config", "user.email", "spike@example.com"], {
    cwd: basePath,
  });
  execFileSync("git", ["config", "user.name", "spike"], { cwd: basePath });
  execFileSync("git", ["config", "commit.gpgsign", "false"], { cwd: basePath });
  execFileSync("git", ["add", "."], { cwd: basePath });
  execFileSync("git", ["commit", "-qm", "spike init"], { cwd: basePath });

  const dbPath = join(gsdDir, "gsd.db");
  if (!openDatabase(dbPath)) {
    throw new Error("openDatabase failed");
  }
  const db = () => _getAdapter();
  const row = (sql) => db().prepare(sql).get() ?? {};

  db().exec(`
    INSERT INTO milestones (id, title, status, created_at)
    VALUES ('M001', 'Spike', 'active', '2026-08-06T00:00:00.000Z');
    INSERT INTO slices (milestone_id, id, title, status, created_at)
    VALUES ('M001', 'S01', 'Executor', 'active', '2026-08-06T00:00:00.000Z');
    INSERT INTO tasks (
      milestone_id, slice_id, id, title, status, verify, sequence
    ) VALUES (
      'M001', 'S01', 'T01', 'Stage completion', 'pending', 'true', 1
    );
  `);

  const fence = readDomainOperationFence();
  executeDomainOperation(
    {
      operationType: "test.task.ready",
      idempotencyKey: `spike/ready/${randomUUID()}`,
      expectedRevision: fence.revision,
      expectedAuthorityEpoch: fence.authorityEpoch,
      actorType: "test",
      sourceTransport: "test",
      payload: { taskId: "T01" },
    },
    (context) => {
      adoptOrTransitionLifecycle(context, {
        itemKind: "task",
        milestoneId: "M001",
        sliceId: "S01",
        taskId: "T01",
        lifecycleStatus: "ready",
      });
      return {
        events: [
          {
            eventType: "test.task.ready",
            entityType: "task",
            entityId: "M001/S01/T01",
            payload: { taskId: "T01" },
            destinations: ["test"],
          },
        ],
        projections: [
          {
            projectionKey: "test/m001/s01/t01",
            projectionKind: "test",
            rendererVersion: "1",
          },
        ],
      };
    },
  );

  const workerId = registerAutoWorker({ projectRootRealpath: basePath });
  heartbeatAutoWorker(workerId);
  const lease = claimMilestoneLease(workerId, "M001");
  if (!lease.ok) {
    throw new Error(`claimMilestoneLease failed: ${JSON.stringify(lease)}`);
  }
  const dispatch = recordDispatchClaim({
    traceId: `spike-${randomUUID()}`,
    turnId: "spike-turn-1",
    workerId,
    milestoneLeaseToken: lease.token,
    milestoneId: "M001",
    sliceId: "S01",
    taskId: "T01",
    unitType: "execute-task",
    unitId: "M001/S01/T01",
    attemptN: 1,
  });
  if (!dispatch.ok) {
    throw new Error(`recordDispatchClaim failed: ${JSON.stringify(dispatch)}`);
  }

  const inv = (key) => ({
    idempotencyKey: key,
    sourceTransport: "workflow-mcp",
    actorType: "agent",
    actorId: "playbook-spike",
    traceId: key,
    turnId: "spike-1",
  });

  const claim = claimTaskAttempt({
    invocation: inv(`spike/claim/${randomUUID()}`),
    task: { milestoneId: "M001", sliceId: "S01", taskId: "T01" },
    workerId,
    milestoneLeaseToken: lease.token,
    coordinationDispatchId: dispatch.dispatchId,
  });
  console.log(`[spike] claimed attemptId=${claim.attemptId}`);

  const staged = await stageTaskCompletion({
    invocation: inv(`spike/stage/${randomUUID()}`),
    basePath,
    task: { milestoneId: "M001", sliceId: "S01", taskId: "T01" },
    completion: {
      oneLiner: "Spike staged completion",
      narrative: "External executor spike staged a result.",
      verification: "true",
      deviations: "None.",
      knownIssues: "None.",
      keyFiles: ["README.md"],
      keyDecisions: ["Spike only"],
      blockerDiscovered: false,
      verificationEvidence: [
        {
          command: "true",
          exitCode: 0,
          verdict: "pass",
          durationMs: 1,
        },
      ],
    },
  });
  console.log(
    `[spike] staged nextStage=${staged.nextStage} resultId=${staged.resultId}`,
  );

  const source = captureVerificationSourceSnapshot([
    { id: "project", cwd: basePath },
  ]);
  if (!source.ok) {
    throw new Error(`source snapshot failed: ${source.error}`);
  }
  recordTaskTechnicalVerdict({
    invocation: inv(`spike/verdict/${randomUUID()}`),
    attemptId: claim.attemptId,
    testedSourceRevision: source.snapshot.aggregateRevision,
    verdict: "pass",
    rationale: "Spike host verification passed.",
    evidence: {
      evidenceClass: "command",
      commandOrTool: "true",
      workingDirectory: basePath,
      startedAt: new Date().toISOString(),
      endedAt: new Date().toISOString(),
      exitCode: 0,
      observation: "passed",
      durableOutputRef: `db://host-verification/${claim.attemptId}`,
      environment: { runner: "spike", host: hostname() },
    },
  });

  const published = await publishVerifiedTaskCompletion({
    invocation: inv(`spike/publish/${randomUUID()}`),
    basePath,
    task: { milestoneId: "M001", sliceId: "S01", taskId: "T01" },
    attemptId: claim.attemptId,
  });
  console.log(`[spike] published summaryPath=${published.summaryPath}`);

  const task = row(
    `SELECT status, one_liner FROM tasks WHERE milestone_id='M001' AND slice_id='S01' AND id='T01'`,
  );
  const plan = readFileSync(planPath, "utf8");
  const checked = plan.includes("[x]") || plan.includes("[X]");
  console.log(`[spike] task.status=${task.status} planChecked=${checked}`);

  try {
    releaseMilestoneLease?.(workerId, "M001", lease.token);
  } catch {
    /* optional */
  }
  closeDatabase();
  rmSync(basePath, { recursive: true, force: true });

  if (task.status !== "complete" && task.status !== "done" && task.status !== "closed") {
    // gsd may use 'complete'
    if (String(task.status) !== "complete") {
      console.error(`[spike] FAIL unexpected status=${task.status}`);
      process.exit(1);
    }
  }
  console.log("[spike] SPIKE RESULT: PASS");
}

main().catch((err) => {
  console.error("[spike] SPIKE RESULT: FAIL");
  console.error(err);
  process.exit(1);
});
