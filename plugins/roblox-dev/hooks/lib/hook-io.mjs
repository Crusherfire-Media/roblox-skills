// Shared plumbing for the plugin's Claude Code hooks: read the event JSON from stdin, run the
// handler, print its JSON answer. Every hook fails open: on any error it prints nothing and
// exits 0, so a broken hook never blocks a tool call or a turn.

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const STATE_DIR = join(tmpdir(), 'roblox-dev-hooks');
const STATE_KEY = /^[A-Za-z0-9_-]{1,100}$/;

// Claude Code's own file tools, which edit a Rojo repo's Luau files.
export const FILE_EDIT_TOOLS = new Set(['Edit', 'Write', 'MultiEdit']);

export function runHook(handler) {
  let output;
  try {
    const input = JSON.parse(readFileSync(0, 'utf8'));
    output = handler(input);
  } catch (error) {
    process.stderr.write(`roblox-dev hook skipped: ${error?.message ?? error}\n`);
    return;
  }
  if (output) {
    process.stdout.write(JSON.stringify(output));
  }
}

// All text inside a tool response, whatever shape it arrives in.
export function responseText(response) {
  if (typeof response === 'string') {
    return response;
  }
  const parts = [];
  const visit = (value) => {
    if (typeof value === 'string') {
      parts.push(value);
    } else if (Array.isArray(value)) {
      value.forEach(visit);
    } else if (value && typeof value === 'object') {
      if (typeof value.text === 'string') {
        parts.push(value.text);
      } else {
        Object.values(value).forEach(visit);
      }
    }
  };
  visit(response);
  return parts.join('\n');
}

// One spelling for a DataModel path: bracket-quoted segments become dotted ones and a leading
// "game" is dropped, so `game.A["B.spec"]` and `A.B.spec` compare equal. The whole place is "".
export function normalizePath(path) {
  if (typeof path !== 'string') {
    return '';
  }
  return path.trim().replace(/\[\s*(["'])(.*?)\1\s*\]/g, '.$2').replace(/^game(\.|$)/, '');
}

// A small per-session state file in the OS temp folder. Keys come from hook input, so they are
// checked to keep the file name inside that folder; with a bad key there is no state.
export function stateFile(...keys) {
  if (!keys.every((key) => typeof key === 'string' && STATE_KEY.test(key))) {
    return undefined;
  }
  return join(STATE_DIR, `${keys.join('-')}.json`);
}

export function readState(file, fallback) {
  if (file === undefined) {
    return fallback;
  }
  try {
    return JSON.parse(readFileSync(file, 'utf8'));
  } catch {
    return fallback;
  }
}

export function writeState(file, value) {
  if (file === undefined) {
    return;
  }
  mkdirSync(STATE_DIR, { recursive: true });
  writeFileSync(file, JSON.stringify(value));
}

// Claude Code names a plugin's skills "<plugin>:<name>". Only this plugin's spelling counts as
// loaded: another plugin can ship a skill with the same bare name (the private `roblox:` plugin
// does), and its copy may say something different.
const PLUGIN_PREFIX = 'roblox-dev:';

// The bare skill name when the name carries this plugin's prefix, otherwise undefined.
export function ownSkillName(name) {
  if (typeof name !== 'string') {
    return undefined;
  }
  const trimmed = name.trim().replace(/^\//, '');
  return trimmed.startsWith(PLUGIN_PREFIX) && trimmed.length > PLUGIN_PREFIX.length
    ? trimmed.slice(PLUGIN_PREFIX.length)
    : undefined;
}

export function listSkills(names) {
  return names.map((name) => `\`${PLUGIN_PREFIX}${name}\``).join(', ');
}
