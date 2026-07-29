#!/usr/bin/env node
/**
 * gsd-reproject-compat.mjs — regenerate missing `.gsd/.compat.json` projection
 * entries for a milestone's rendered artifacts.
 *
 * WHY THIS EXISTS
 * ---------------
 * `gsd_plan_slice` (gsd-pi) writes the DB rows (slices + tasks) and renders the
 * slice-PLAN markdown to disk, but does NOT record those files' projection
 * entries in `.gsd/.compat.json`. In gsd-pi's `markdown-renderer.js`,
 * `writeAndStore()` only records a projection when a `basePath` arg is passed,
 * and the PLAN / slice-artifact renderers omit it. `gsd_plan_milestone` DOES
 * record the ROADMAP projection, so typically only `NN-ROADMAP.md` ends up
 * indexed. Neither `gsd_checkpoint_db` nor an MCP reload backfills the rest.
 *
 * `gsd-smoke.py:resolve_slice_plan` locates slice PLANs ONLY via
 * `.compat.json` projections (entity `M###/S##` -> path). A missing entry makes
 * the resolver return "missing" -> plan-coherence reports `md=0 db=N DRIFT`
 * even though the DB and the rendered markdown fully agree. This is a stale
 * projection INDEX, never a markdown<->DB content conflict.
 *
 * WHAT THIS DOES
 * --------------
 * Uses gsd-pi's own compat-marker API (readCompatMarker / computeProjectionSha
 * / writeCompatMarker) to (re)write the projection entries for the target
 * milestone's rendered ROADMAP + slice artifacts, derived from the on-disk
 * files. Additive and idempotent: it only re-sets entries for the requested
 * milestone(s) and preserves every other projection. This mirrors exactly what
 * the renderer's own `flushProjectionWritesToMarker()` would have written.
 *
 * USAGE
 * -----
 *   node .workflow/scripts/gsd-reproject-compat.mjs M012   # one milestone (recommended)
 *   node .workflow/scripts/gsd-reproject-compat.mjs        # all phase folders
 *
 * Override the gsd-pi extension path with GSD_PI_EXT if it is not at the
 * default global npm location.
 *
 * Run from the repo root, then re-run `.workflow/scripts/gsd-smoke.sh
 * --milestone <M###>` to confirm plan-coherence is OK.
 */
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const root = process.cwd();
const argMilestone = process.argv.slice(2).find((a) => /^M\d+$/.test(a)) || null;

const GSD_EXT =
  process.env.GSD_PI_EXT ||
  join(
    process.env.HOME ?? '',
    '.npm-global/lib/node_modules/@opengsd/gsd-pi/dist/resources/extensions/gsd',
  );

const compatPath = join(GSD_EXT, 'compat/compat-marker.js');
if (!existsSync(compatPath)) {
  console.error(
    `[reproject] gsd-pi compat-marker not found at ${compatPath}.\n` +
      `Set GSD_PI_EXT to the gsd-pi .../extensions/gsd directory.`,
  );
  process.exit(2);
}
const { readCompatMarker, writeCompatMarker, computeProjectionSha } = await import(compatPath);

const phasesDir = join(root, '.gsd', 'phases');
if (!existsSync(phasesDir)) {
  console.error(`[reproject] No ${phasesDir} — nothing to reproject (legacy layout?).`);
  process.exit(2);
}

const marker = readCompatMarker(root);
let wrote = 0;
const touched = [];
const milestonesSeen = new Set();

for (const phase of readdirSync(phasesDir, { withFileTypes: true })) {
  if (!phase.isDirectory()) continue;
  const folderAbs = join(phasesDir, phase.name);
  const files = readdirSync(folderAbs).filter((f) => f.endsWith('.md'));

  // Milestone id is the authoritative anchor: read it from the ROADMAP heading
  // (`# M012: ...`), not the folder slug (which is not always the id).
  const roadmap = files.find((f) => /-ROADMAP\.md$/.test(f));
  if (!roadmap) continue;
  const roadmapText = readFileSync(join(folderAbs, roadmap), 'utf-8');
  const mid = (roadmapText.match(/^#\s*(M\d+)\b/m) || [])[1];
  if (!mid) continue;
  if (argMilestone && mid !== argMilestone) continue;
  milestonesSeen.add(mid);

  const relRoadmap = `phases/${phase.name}/${roadmap}`;
  marker.projections[relRoadmap] = { sha: computeProjectionSha(roadmapText), entities: [mid] };
  wrote++;
  touched.push(relRoadmap);

  // Slice-scoped artifacts: `NN-MM-<TYPE>.md` -> entities [mid, `${mid}/S<MM>`].
  for (const f of files) {
    const m = f.match(/^\d+-(\d+)-(PLAN|SUMMARY|UAT|REPLAN|ASSESSMENT)\.md$/);
    if (!m) continue;
    const sliceId = `S${m[1]}`;
    const rel = `phases/${phase.name}/${f}`;
    const text = readFileSync(join(folderAbs, f), 'utf-8');
    marker.projections[rel] = {
      sha: computeProjectionSha(text),
      entities: [mid, `${mid}/${sliceId}`],
    };
    wrote++;
    touched.push(rel);
  }
}

if (wrote === 0) {
  console.error(
    `[reproject] No matching artifacts found` +
      (argMilestone ? ` for ${argMilestone}` : '') +
      `. Nothing written.`,
  );
  process.exit(1);
}

marker.lastWriter = 'gsd-pi';
marker.lastProjectedAt = new Date().toISOString();
writeCompatMarker(root, marker);

console.log(JSON.stringify({ milestones: [...milestonesSeen], wrote, touched }, null, 2));
