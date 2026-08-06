/**
 * Bridge health: gsd-pi version pin + schema floor + DB presence.
 */
import {
  resolveGsdPiRoot,
  readGsdPiPackage,
  assertSupportedGsdPiVersion,
  SUPPORTED_GSD_PI_RANGE,
  resolveProjectRoot,
} from "./resolve-gsd.mjs";
import {
  openProjectDb,
  schemaVersion,
  SCHEMA_VERSION_FLOOR,
} from "./project.mjs";
import { existsSync } from "node:fs";
import { join, resolve } from "node:path";

export async function bridgeHealth(params = {}) {
  const issues = [];
  let gsdRoot;
  let version;
  try {
    gsdRoot = resolveGsdPiRoot();
    version = readGsdPiPackage(gsdRoot).version;
    assertSupportedGsdPiVersion(version);
  } catch (err) {
    issues.push(String(err.message || err));
  }

  const projectRoot = resolve(resolveProjectRoot(params.projectRoot));
  const dbPath = join(projectRoot, ".gsd", "gsd.db");
  let schema = 0;
  if (!existsSync(dbPath)) {
    issues.push(`Missing DB at ${dbPath}`);
  } else {
    try {
      const ctx = await openProjectDb(projectRoot);
      schema = await schemaVersion(ctx.adapter);
      if (schema < SCHEMA_VERSION_FLOOR) {
        issues.push(
          `schema_version ${schema} < floor ${SCHEMA_VERSION_FLOOR} (Attempt model)`,
        );
      }
    } catch (err) {
      issues.push(String(err.message || err));
    }
  }

  const ok = issues.length === 0;
  return {
    status: ok ? "ok" : "degraded",
    ok,
    gsdPiRoot: gsdRoot,
    gsdPiVersion: version,
    supportedRange: SUPPORTED_GSD_PI_RANGE,
    projectRoot,
    schemaVersion: schema,
    schemaFloor: SCHEMA_VERSION_FLOOR,
    issues,
  };
}
