#!/usr/bin/env node
/**
 * Make Ruflo/Claude Flow hooks Cursor-safe in this repo.
 *
 * Cursor preToolUse requires JSON on stdout. Ruflo's hook-handler.cjs prints
 * human text, so Cursor blocks the tool. This script:
 *   1. Checks the user-global adapter at ~/.cursor/hooks/ruflo-cursor-adapter.cjs
 *   2. Ensures ~/.cursor/hooks.json points at that adapter
 *   3. Rewrites this project's .claude/settings.json to exec the adapter
 *
 * Usage:
 *   fix-ruflo-cursor-hooks                 # patch cwd
 *   fix-ruflo-cursor-hooks /path/to/repo
 *   fix-ruflo-cursor-hooks --dry-run
 *   fix-ruflo-cursor-hooks --global-only   # skip project settings.json
 */
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const HOME = os.homedir();
const HOOKS_DIR = path.join(HOME, '.cursor', 'hooks');
const ADAPTER = path.join(HOOKS_DIR, 'ruflo-cursor-adapter.cjs');
const USER_HOOKS = path.join(HOME, '.cursor', 'hooks.json');
const ADAPTER_CMD = './hooks/ruflo-cursor-adapter.cjs';
const PROJECT_CMD_PREFIX = 'sh -c \'exec node "$HOME/.cursor/hooks/ruflo-cursor-adapter.cjs" ';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const globalOnly = args.includes('--global-only');
const targetDir = args.find((a) => !a.startsWith('--')) || process.cwd();

function die(msg) {
  process.stderr.write(msg + '\n');
  process.exit(1);
}

function info(msg) {
  process.stderr.write(msg + '\n');
}

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writeJson(file, data) {
  const text = JSON.stringify(data, null, 2) + '\n';
  if (dryRun) {
    info('[dry-run] would write ' + file);
    return;
  }
  fs.writeFileSync(file, text, 'utf8');
}

function hasAdapterCommand(entries, command) {
  return (entries || []).some((h) => String(h.command || '').includes(command));
}

function ensureUserHooks() {
  let data = { version: 1, hooks: {} };
  if (fs.existsSync(USER_HOOKS)) {
    data = readJson(USER_HOOKS);
    if (!data.hooks || typeof data.hooks !== 'object') data.hooks = {};
  }
  data.version = data.version || 1;
  data.hooks.preToolUse = data.hooks.preToolUse || [];
  data.hooks.postToolUse = data.hooks.postToolUse || [];

  const needed = [
    {
      list: 'preToolUse',
      command: ADAPTER_CMD + ' pre-edit',
      hook: { command: ADAPTER_CMD + ' pre-edit', matcher: 'Write|Edit|MultiEdit', timeout: 5 },
    },
    {
      list: 'preToolUse',
      command: ADAPTER_CMD + ' pre-bash',
      hook: { command: ADAPTER_CMD + ' pre-bash', matcher: 'Shell|Bash', timeout: 5 },
    },
    {
      list: 'postToolUse',
      command: ADAPTER_CMD + ' post-edit',
      hook: { command: ADAPTER_CMD + ' post-edit', matcher: 'Write|Edit|MultiEdit', timeout: 10 },
    },
  ];

  let changed = false;
  for (const item of needed) {
    if (!hasAdapterCommand(data.hooks[item.list], item.command)) {
      data.hooks[item.list].unshift(item.hook);
      changed = true;
    }
  }
  if (changed) {
    writeJson(USER_HOOKS, data);
    info((dryRun ? '[dry-run] ' : '') + 'updated ' + USER_HOOKS);
  } else {
    info('user hooks already wired: ' + USER_HOOKS);
  }
}

function rewriteCommand(cmd) {
  if (typeof cmd !== 'string') return { cmd, changed: false };
  if (cmd.includes('ruflo-cursor-adapter.cjs')) return { cmd, changed: false };
  if (!cmd.includes('hook-handler.cjs')) return { cmd, changed: false };
  const match = cmd.match(/hook-handler\.cjs["']?\s+([^"'\s]+)/);
  const hookCmd = match ? match[1] : 'pre-edit';
  return {
    cmd: PROJECT_CMD_PREFIX + hookCmd + "'",
    changed: true,
  };
}

function walkCommands(node, acc) {
  if (!node || typeof node !== 'object') return;
  if (Array.isArray(node)) {
    for (const item of node) walkCommands(item, acc);
    return;
  }
  if (typeof node.command === 'string') {
    const result = rewriteCommand(node.command);
    if (result.changed) {
      acc.changed += 1;
      acc.samples.push(node.command + '  ->  ' + result.cmd);
      node.command = result.cmd;
    }
  }
  for (const value of Object.values(node)) walkCommands(value, acc);
}

function patchProject(projectRoot) {
  const settings = path.join(projectRoot, '.claude', 'settings.json');
  if (!fs.existsSync(settings)) {
    info('no .claude/settings.json in ' + projectRoot + ' (nothing to patch)');
    return;
  }
  const data = readJson(settings);
  const acc = { changed: 0, samples: [] };
  walkCommands(data, acc);
  if (!acc.changed) {
    info('already patched: ' + settings);
    return;
  }
  if (!dryRun) {
    const bak = settings + '.bak-ruflo-cursor';
    if (!fs.existsSync(bak)) fs.copyFileSync(settings, bak);
  }
  writeJson(settings, data);
  info((dryRun ? '[dry-run] ' : '') + 'patched ' + acc.changed + ' hook command(s) in ' + settings);
  for (const sample of acc.samples) info('  ' + sample);
}

function main() {
  if (!fs.existsSync(ADAPTER)) {
    die('missing adapter: ' + ADAPTER + '\ncopy ruflo-cursor-adapter.cjs into ~/.cursor/hooks/ first');
  }
  info('adapter: ' + ADAPTER);
  ensureUserHooks();
  if (globalOnly) return;
  const root = path.resolve(targetDir);
  if (!fs.existsSync(root)) die('not a directory: ' + root);
  patchProject(root);
  info('done. reload Cursor if Hooks still show the old command.');
}

main();
