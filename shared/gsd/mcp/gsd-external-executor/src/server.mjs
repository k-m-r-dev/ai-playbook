#!/usr/bin/env node
/**
 * playbook-gsd MCP — external executor bridge for gsd-pi Attempt lifecycle.
 */
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";
import { existsSync, readFileSync } from "node:fs";
import { bridgeHealth } from "./health.mjs";
import { taskBegin } from "./begin.mjs";
import { taskPublish } from "./publish.mjs";
import { taskAbort } from "./abort.mjs";
import { resolveGsdPiRoot } from "./resolve-gsd.mjs";

const require = createRequire(import.meta.url);

function resolvePkg(name) {
  try {
    const resolved = require.resolve(`${name}/package.json`);
    let dir = dirname(resolved);
    // Dual ESM/CJS packages sometimes ship a nested marker package.json
    // (e.g. dist/cjs/package.json with {"type":"commonjs"}) that resolves
    // before the real package root. Walk up until the name field matches.
    for (let i = 0; i < 6; i++) {
      try {
        const pkg = JSON.parse(readFileSync(join(dir, "package.json"), "utf8"));
        if (pkg.name === name) return dir;
      } catch {
        /* not a valid/matching package.json here */
      }
      const parent = dirname(dir);
      if (parent === dir) break;
      dir = parent;
    }
    return dirname(resolved);
  } catch {
    /* fall through */
  }
  try {
    const gsd = resolveGsdPiRoot();
    const nested = join(gsd, "node_modules", name);
    if (existsSync(join(nested, "package.json"))) return nested;
  } catch {
    /* fall through */
  }
  throw new Error(`Cannot resolve ${name}`);
}

async function loadDeps() {
  const sdkRoot = resolvePkg("@modelcontextprotocol/sdk");
  const zodRoot = resolvePkg("zod");
  const { McpServer } = await import(
    pathToFileURL(join(sdkRoot, "dist/esm/server/mcp.js")).href
  );
  const { StdioServerTransport } = await import(
    pathToFileURL(join(sdkRoot, "dist/esm/server/stdio.js")).href
  );
  const zodMod = await import(pathToFileURL(join(zodRoot, "index.js")).href);
  const z = zodMod.z || zodMod.default;
  return { McpServer, StdioServerTransport, z };
}

function textResult(obj, isError = false) {
  return {
    content: [{ type: "text", text: JSON.stringify(obj, null, 2) }],
    structuredContent: obj,
    isError,
  };
}

async function main() {
  const { McpServer, StdioServerTransport, z } = await loadDeps();
  const server = new McpServer({
    name: "playbook-gsd",
    version: "0.1.0",
  });

  server.tool(
    "playbook_gsd_bridge_health",
    "Check playbook↔gsd-pi bridge readiness (version pin, schema floor, DB).",
    { projectRoot: z.string().optional() },
    async (args) => {
      try {
        const health = await bridgeHealth(args || {});
        return textResult(health, !health.ok);
      } catch (err) {
        return textResult(
          { status: "error", error: String(err.message || err) },
          true,
        );
      }
    },
  );

  server.tool(
    "playbook_gsd_task_begin",
    "Claim a running Attempt for an existing task. Call before implementing; then gsd_task_complete; then playbook_gsd_task_publish.",
    {
      milestoneId: z.string().min(1),
      sliceId: z.string().min(1),
      taskId: z.string().min(1),
      projectRoot: z.string().optional(),
    },
    async (args) => {
      try {
        return textResult(await taskBegin(args));
      } catch (err) {
        return textResult(
          { status: "error", error: String(err.message || err) },
          true,
        );
      }
    },
  );

  server.tool(
    "playbook_gsd_task_publish",
    "After gsd_task_complete returns nextStage=verify: record host Technical Verdict and publish completion.",
    {
      milestoneId: z.string().min(1),
      sliceId: z.string().min(1),
      taskId: z.string().min(1),
      attemptId: z.string().optional(),
      verifyCommand: z.string().optional(),
      exitCode: z.number().optional(),
      observation: z.enum(["passed", "failed"]).optional(),
      projectRoot: z.string().optional(),
    },
    async (args) => {
      try {
        return textResult(await taskPublish(args));
      } catch (err) {
        return textResult(
          { status: "error", error: String(err.message || err) },
          true,
        );
      }
    },
  );

  server.tool(
    "playbook_gsd_task_abort",
    "Interrupt a running playbook-claimed Attempt and release lease when possible.",
    {
      milestoneId: z.string().min(1),
      sliceId: z.string().min(1),
      taskId: z.string().min(1),
      attemptId: z.string().optional(),
      reason: z.string().optional(),
      projectRoot: z.string().optional(),
    },
    async (args) => {
      try {
        return textResult(await taskAbort(args));
      } catch (err) {
        return textResult(
          { status: "error", error: String(err.message || err) },
          true,
        );
      }
    },
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error("[playbook-gsd] fatal:", err);
  process.exit(1);
});
