#!/usr/bin/env node
/**
 * Claude Flow Hook Handler (Cross-Platform)
 * Dispatches hook events to the appropriate helper modules.
 *
 * Usage: node hook-handler.cjs <command> [args...]
 *
 * Commands:
 *   route          - Route a task to optimal agent (reads PROMPT from env/stdin)
 *   pre-bash       - Validate command safety before execution
 *   post-edit      - Record edit outcome for learning
 *   session-restore - Restore previous session state
 *   session-end    - End session and persist state
 */

const path = require('path');
const fs = require('fs');

const helpersDir = __dirname;
const LOG_PREFIX = '[HOOK_HANDLER]';
const GLOBAL_TIMEOUT_MS = Number(process.env.HOOK_HANDLER_GLOBAL_TIMEOUT_MS || 5000);
const INTELLIGENCE_TIMEOUT_MS = Number(process.env.HOOK_HANDLER_INTELLIGENCE_TIMEOUT_MS || 3000);
let hasResponded = false;

// Output valid JSON decision to stdout — Cursor/Claude Code requires this format.
function jsonOut(decision, reason) {
  if (hasResponded) return;
  hasResponded = true;
  const obj = decision === 'block'
    ? { decision: 'block', reason: reason || 'blocked' }
    : { decision: 'approve' };
  process.stdout.write(JSON.stringify(obj) + '\n');
}

// Safe require with stdout suppression - the helper modules have CLI
// sections that run unconditionally on require(), so we mute console
// during the require to prevent noisy output.
function safeRequire(modulePath) {
  try {
    if (fs.existsSync(modulePath)) {
      const origLog = console.log;
      const origError = console.error;
      console.log = () => {};
      console.error = () => {};
      try {
        const mod = require(modulePath);
        return mod;
      } finally {
        console.log = origLog;
        console.error = origError;
      }
    }
  } catch (e) {
    // silently fail
  }
  return null;
}

const router = safeRequire(path.join(helpersDir, 'router.js'));
const session = safeRequire(path.join(helpersDir, 'session.js'));
const memory = safeRequire(path.join(helpersDir, 'memory.js'));
const intelligence = safeRequire(path.join(helpersDir, 'intelligence.cjs'));

// ── Intelligence timeout protection (fixes #1530, #1531) ───────────────────
async function runWithTimeout(fn, label, timeoutMs = INTELLIGENCE_TIMEOUT_MS) {
  let timer;
  try {
    return await Promise.race([
      Promise.resolve().then(fn),
      new Promise((resolve) => {
        timer = setTimeout(() => {
          process.stderr.write(`${LOG_PREFIX}[WARN] ${label} timed out after ${timeoutMs}ms, skipping\n`);
          resolve(null);
        }, timeoutMs);
      }),
    ]);
  } catch (e) {
    process.stderr.write(`${LOG_PREFIX}[WARN] ${label} failed: ${(e && e.message) || String(e)}\n`);
    return null;
  } finally {
    if (timer) clearTimeout(timer);
  }
}


// Get the command from argv
const [,, command, ...args] = process.argv;

// Read stdin with timeout — Claude Code sends hook data as JSON via stdin.
async function readStdin() {
  if (process.stdin.isTTY) return '';
  return new Promise((resolve) => {
    let data = '';
    const timer = setTimeout(() => {
      process.stdin.removeAllListeners();
      process.stdin.pause();
      resolve(data);
    }, 500);
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (chunk) => { data += chunk; });
    process.stdin.on('end', () => { clearTimeout(timer); resolve(data); });
    process.stdin.on('error', () => { clearTimeout(timer); resolve(data); });
    process.stdin.resume();
  });
}

async function main() {
  // Global safety timeout: hooks must NEVER hang (#1530, #1531)
  const safetyTimer = setTimeout(() => {
    process.stderr.write(`${LOG_PREFIX}[WARN] Global timeout (${GLOBAL_TIMEOUT_MS}ms), forcing approve\n`);
    jsonOut('approve');
    process.exit(0);
  }, GLOBAL_TIMEOUT_MS);
  safetyTimer.unref();

  let stdinData = '';
  try { stdinData = await readStdin(); } catch (e) { /* ignore stdin errors */ }

  let hookInput = {};
  if (stdinData.trim()) {
    try { hookInput = JSON.parse(stdinData); } catch (e) { /* ignore parse errors */ }
  }

  const toolInput = hookInput.toolInput || hookInput.tool_input || {};
  const toolName = hookInput.toolName || hookInput.tool_name || '';

  const prompt = hookInput.prompt || hookInput.command || toolInput
    || process.env.PROMPT || process.env.TOOL_INPUT_command || args.join(' ') || '';

const handlers = {
  'route': () => {
    if (intelligence && intelligence.getContext) {
      try {
        const ctx = intelligence.getContext(prompt);
        if (ctx) process.stderr.write(ctx + '\n');
      } catch (e) { /* non-fatal */ }
    }
    if (router && router.routeTask) {
      try { router.routeTask(prompt); } catch (e) { /* non-fatal */ }
    }
    jsonOut('approve');
  },

  'pre-bash': () => {
    const cmd = (hookInput.command || prompt).toLowerCase();
    const dangerous = ['rm -rf /', 'format c:', 'del /s /q c:\\', ':(){:|:&};:'];
    for (const d of dangerous) {
      if (cmd.includes(d)) {
        process.stderr.write(`[BLOCKED] Dangerous command detected: ${d}\n`);
        jsonOut('block', `Dangerous command detected: ${d}`);
        return;
      }
    }
    jsonOut('approve');
  },

  'pre-edit': () => {
    jsonOut('approve');
  },

  'post-edit': () => {
    if (session && session.metric) {
      try { session.metric('edits'); } catch (e) { /* no active session */ }
    }
    if (intelligence && intelligence.recordEdit) {
      try {
        const file = hookInput.file_path || toolInput.file_path
          || process.env.TOOL_INPUT_file_path || args[0] || '';
        intelligence.recordEdit(file);
      } catch (e) { /* non-fatal */ }
    }
    jsonOut('approve');
  },

  'post-bash': () => {
    jsonOut('approve');
  },

  'session-restore': async () => {
    if (session) {
      const existing = session.restore && session.restore();
      if (!existing) {
        session.start && session.start();
      }
    } else {
      process.stderr.write(`${LOG_PREFIX}[INFO] Session restore: no session module available\n`);
    }
    if (intelligence && intelligence.init) {
      const initResult = await runWithTimeout(() => intelligence.init(), 'intelligence.init()');
      if (initResult && initResult.nodes > 0) {
        process.stderr.write(`${LOG_PREFIX}[INTELLIGENCE] Loaded ${initResult.nodes} patterns, ${initResult.edges} edges\n`);
      }
    }
    jsonOut('approve');
  },

  'session-end': async () => {
    if (intelligence && intelligence.consolidate) {
      const consResult = await runWithTimeout(() => intelligence.consolidate(), 'intelligence.consolidate()');
      if (consResult && consResult.entries > 0) {
        process.stderr.write(`${LOG_PREFIX}[INTELLIGENCE] Consolidated: ${consResult.entries} entries, ${consResult.edges} edges${consResult.newEntries > 0 ? `, ${consResult.newEntries} new` : ''}, PageRank recomputed\n`);
      }
    }
    if (session && session.end) {
      session.end();
    } else {
      process.stderr.write(`${LOG_PREFIX}[INFO] Session ended\n`);
    }
    jsonOut('approve');
  },

  'pre-task': () => {
    if (session && session.metric) {
      try { session.metric('tasks'); } catch (e) { /* no active session */ }
    }
    if (router && router.routeTask && prompt) {
      try {
        const result = router.routeTask(prompt);
        process.stderr.write(`${LOG_PREFIX}[INFO] Task routed to: ${result.agent} (confidence: ${result.confidence})\n`);
      } catch (e) { /* non-fatal */ }
    }
    jsonOut('approve');
  },

  'post-task': () => {
    if (intelligence && intelligence.feedback) {
      try { intelligence.feedback(true); } catch (e) { /* non-fatal */ }
    }
    jsonOut('approve');
  },

  'stats': () => {
    if (intelligence && intelligence.stats) {
      try { intelligence.stats(args.includes('--json')); } catch (e) { /* non-fatal */ }
    } else {
      process.stderr.write(`${LOG_PREFIX}[WARN] Intelligence module not available. Run session-restore first.\n`);
    }
    jsonOut('approve');
  },
  'self-test-timeout': async () => {
    await runWithTimeout(
      () => new Promise((resolve) => setTimeout(resolve, INTELLIGENCE_TIMEOUT_MS + 1000)),
      'self-test-timeout',
      Math.min(INTELLIGENCE_TIMEOUT_MS, 1000),
    );
    jsonOut('approve');
  },

  'status': () => { jsonOut('approve'); },
  'notify': () => { jsonOut('approve'); },
  'compact-manual': () => { jsonOut('approve'); },
  'compact-auto': () => { jsonOut('approve'); },
};

  if (command && handlers[command]) {
    try {
      await Promise.resolve(handlers[command]());
    } catch (e) {
      process.stderr.write(`${LOG_PREFIX}[WARN] Hook ${command} encountered an error: ${e.message}\n`);
      jsonOut('approve');
    }
  } else if (command) {
    jsonOut('approve');
  } else {
    process.stderr.write('Usage: hook-handler.cjs <route|pre-bash|pre-edit|post-edit|post-bash|session-restore|session-end|pre-task|post-task|stats|status|notify|compact-manual|compact-auto|self-test-timeout>\n');
    jsonOut('approve');
  }
}

process.exitCode = 0;
main().catch((e) => {
  try { process.stderr.write(`${LOG_PREFIX}[WARN] Hook handler error: ${e.message}\n`); } catch (_) {}
  try { jsonOut('approve'); } catch (_) {}
}).finally(() => {
  process.exit(0);
});
