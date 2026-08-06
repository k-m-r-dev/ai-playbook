/**
 * Open project .gsd/gsd.db with path jail to project root.
 */
import { realpathSync, existsSync, mkdirSync } from "node:fs";
import { join, resolve, sep } from "node:path";
import { importGsd, resolveGsdPiRoot, resolveProjectRoot } from "./resolve-gsd.mjs";

let openedRoot = null;

export function assertInsideProject(projectRoot, candidatePath) {
  const root = realpathSync(projectRoot);
  const candidate = resolve(candidatePath);
  const realCandidate = existsSync(candidate)
    ? realpathSync(candidate)
    : candidate;
  const prefix = root.endsWith(sep) ? root : root + sep;
  const insideRoot =
    realCandidate === root || realCandidate.startsWith(prefix);
  // GSD may store project state outside the repo and symlink it in as
  // <root>/.gsd (e.g. ~/.gsd/projects/<hash>). Allow paths that resolve
  // inside that symlink target too -- still a closed jail, just a second
  // allowed root, not an open escape.
  let insideGsdLink = false;
  const gsdLink = join(root, ".gsd");
  if (existsSync(gsdLink)) {
    const gsdReal = realpathSync(gsdLink);
    const gsdPrefix = gsdReal.endsWith(sep) ? gsdReal : gsdReal + sep;
    insideGsdLink = realCandidate === gsdReal || realCandidate.startsWith(gsdPrefix);
  }
  if (!insideRoot && !insideGsdLink) {
    throw new Error(
      `Path escapes project root: ${candidatePath} (root: ${projectRoot})`,
    );
  }
  return realCandidate;
}

export async function openProjectDb(projectRootInput) {
  const root = resolve(resolveProjectRoot(projectRootInput));
  if (!existsSync(root)) {
    throw new Error(`Project root does not exist: ${root}`);
  }
  const projectRoot = realpathSync(root);
  const gsdDir = join(projectRoot, ".gsd");
  const dbPath = join(gsdDir, "gsd.db");
  assertInsideProject(projectRoot, dbPath);
  if (!existsSync(dbPath)) {
    throw new Error(
      `Missing ${dbPath}. Bootstrap GSD first (gsd init / --init-gsd).`,
    );
  }

  const gsdRoot = resolveGsdPiRoot();
  const { openDatabase, closeDatabase, _getAdapter, isDbAvailable } =
    await importGsd("gsd-db.js", gsdRoot);

  if (openedRoot && openedRoot !== projectRoot) {
    try {
      closeDatabase();
    } catch {
      /* ignore */
    }
    openedRoot = null;
  }

  if (!isDbAvailable() || openedRoot !== projectRoot) {
    if (!openDatabase(dbPath)) {
      throw new Error(`openDatabase failed for ${dbPath}`);
    }
    openedRoot = projectRoot;
  }

  return {
    projectRoot,
    dbPath,
    gsdRoot,
    adapter: () => _getAdapter(),
    close: () => {
      closeDatabase();
      openedRoot = null;
    },
  };
}

export async function schemaVersion(adapter) {
  try {
    const row = adapter()
      .prepare("SELECT MAX(version) AS v FROM schema_version")
      .get();
    return Number(row?.v ?? 0);
  } catch {
    return 0;
  }
}

export const SCHEMA_VERSION_FLOOR = 36;
