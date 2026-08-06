/**
 * Resolve installed @opengsd/gsd-pi root and import helpers.
 */
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";
import { readFileSync, existsSync } from "node:fs";

const require = createRequire(import.meta.url);

export const SUPPORTED_GSD_PI_RANGE = {
  min: "1.12.0",
  maxExclusive: "1.13.0",
};

export function resolveGsdPiRoot() {
  if (process.env.GSD_PI_ROOT && existsSync(join(process.env.GSD_PI_ROOT, "package.json"))) {
    return process.env.GSD_PI_ROOT;
  }
  try {
    return dirname(require.resolve("@opengsd/gsd-pi/package.json"));
  } catch {
    const fallback = join(
      process.env.HOME || "",
      ".npm-global/lib/node_modules/@opengsd/gsd-pi",
    );
    if (existsSync(join(fallback, "package.json"))) return fallback;
    throw new Error(
      "Cannot resolve @opengsd/gsd-pi. Set GSD_PI_ROOT or install globally.",
    );
  }
}

export function readGsdPiPackage(root = resolveGsdPiRoot()) {
  return JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
}

/** Semver compare: a < b → -1, a==b → 0, a > b → 1 (major.minor.patch only). */
export function cmpSemver(a, b) {
  const pa = String(a).split(".").map((n) => parseInt(n, 10) || 0);
  const pb = String(b).split(".").map((n) => parseInt(n, 10) || 0);
  for (let i = 0; i < 3; i++) {
    const d = (pa[i] || 0) - (pb[i] || 0);
    if (d !== 0) return d < 0 ? -1 : 1;
  }
  return 0;
}

export function assertSupportedGsdPiVersion(version) {
  if (
    cmpSemver(version, SUPPORTED_GSD_PI_RANGE.min) < 0 ||
    cmpSemver(version, SUPPORTED_GSD_PI_RANGE.maxExclusive) >= 0
  ) {
    throw new Error(
      `playbook-gsd bridge requires @opengsd/gsd-pi ${SUPPORTED_GSD_PI_RANGE.min}..<${SUPPORTED_GSD_PI_RANGE.maxExclusive}; found ${version}`,
    );
  }
}

export function gsdDistUrl(relPath, root = resolveGsdPiRoot()) {
  return pathToFileURL(join(root, "dist/resources/extensions/gsd", relPath)).href;
}

export async function importGsd(relPath, root = resolveGsdPiRoot()) {
  return import(gsdDistUrl(relPath, root));
}

export function resolveProjectRoot(explicit) {
  const root =
    explicit ||
    process.env.GSD_WORKFLOW_PROJECT_ROOT ||
    process.env.PLAYBOOK_GSD_PROJECT_ROOT ||
    process.cwd();
  if (!root || root.includes("\0") || root.includes("..")) {
    // Allow absolute paths with .. normalized later via realpath in open
  }
  return root;
}
