#!/usr/bin/env node
/**
 * Cursor-safe wrapper around Ruflo/Claude Flow hook-handler.cjs.
 * SoT: ai-playbook/config/cursor-hooks/ruflo-cursor-adapter.cjs
 * Install: bash scripts/install-ruflo-cursor-hooks.sh
 *
 * Claude Code accepts human text on stdout. Cursor preToolUse requires
 * valid JSON or it blocks the tool. This adapter:
 *   1. Runs the real project/home hook-handler
 *   2. Sends that handler's stdout to stderr
 *   3. Emits Cursor/Claude-compatible JSON on stdout
 *
 * Usage: ruflo-cursor-adapter.cjs <pre-edit|pre-bash|post-edit|...>
 */
'use strict';

const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ADAPTER_MARKER = 'RUFLO_CURSOR_ADAPTER';
const command = process.argv[2] || 'pre-edit';
const PRE_COMMANDS = new Set(['pre-edit', 'pre-bash', 'pre-task']);
const CHILD_TIMEOUT_MS = 4000;

function readStdin() {
  if (process.stdin.isTTY) return Promise.resolve('');
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

function isAdapterFile(file) {
  if (path.resolve(file) === path.resolve(__filename)) return true;
  try {
    const head = fs.readFileSync(file, 'utf8').slice(0, 500);
    return head.includes(ADAPTER_MARKER);
  } catch {
    return false;
  }
}

function resolveHandler() {
  const roots = [
    process.env.CURSOR_PROJECT_DIR,
    process.env.CLAUDE_PROJECT_DIR,
    process.cwd(),
  ].filter(Boolean);
  for (const root of roots) {
    const candidate = path.join(root, '.claude', 'helpers', 'hook-handler.cjs');
    if (fs.existsSync(candidate) && !isAdapterFile(candidate)) return candidate;
  }
  const home = path.join(os.homedir(), '.claude', 'helpers', 'hook-handler.cjs');
  if (fs.existsSync(home) && !isAdapterFile(home)) return home;
  return null;
}

function emit(payload) {
  process.stdout.write(JSON.stringify(payload) + '\n');
}

function allow() {
  if (command === 'route') {
    emit({ continue: true });
    return;
  }
  if (PRE_COMMANDS.has(command)) {
    emit({
      permission: 'allow',
      hookSpecificOutput: {
        hookEventName: 'PreToolUse',
        permissionDecision: 'allow',
      },
    });
    return;
  }
  emit({});
}

function deny(reason) {
  const msg = reason || 'Blocked by Ruflo hook';
  if (command === 'route') {
    emit({ continue: false, user_message: msg });
    return;
  }
  emit({
    permission: 'deny',
    user_message: msg,
    agent_message: msg,
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: msg,
    },
  });
}

function finish(innerText, exitCode) {
  const blockedLine = String(innerText || '')
    .split('\n')
    .find((line) => line.includes('[BLOCKED]'));
  if (blockedLine || exitCode === 2) {
    deny(blockedLine || 'Blocked by Ruflo hook');
    return;
  }
  allow();
}

async function main() {
  const stdinData = await readStdin();
  const handler = resolveHandler();
  if (!handler) {
    allow();
    return;
  }

  await new Promise((resolve) => {
    const child = spawn(process.execPath, [handler, command], {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, RUFLO_CURSOR_ADAPTER: '1' },
      windowsHide: true,
    });
    let out = '';
    let err = '';
    const timer = setTimeout(() => {
      try { child.kill('SIGTERM'); } catch { /* ignore */ }
    }, CHILD_TIMEOUT_MS);
    child.stdout.on('data', (chunk) => {
      out += chunk;
      process.stderr.write(chunk);
    });
    child.stderr.on('data', (chunk) => {
      err += chunk;
      process.stderr.write(chunk);
    });
    child.on('error', () => {
      clearTimeout(timer);
      allow();
      resolve();
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      finish(out + err, code);
      resolve();
    });
    child.stdin.end(stdinData);
  });
}

main().catch(() => {
  allow();
}).finally(() => {
  process.exit(0);
});
