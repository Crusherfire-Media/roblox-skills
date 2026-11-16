// PreToolUse gate on Luau file edits in a Rojo repo or a pesde workspace: denies the edit until
// the skills it needs are loaded, and says which ones. The deny reason goes back to the model,
// which loads them and retries, so nobody has to type the reminder. Edits to installed packages
// are denied outright.
//
// "Loaded" means loaded under this plugin's name (`roblox-dev:<skill>`) since the last
// compaction, or re-attached by it in full: compaction cuts a re-attached skill at 20,000
// characters and drops the oldest ones past its budget.

import { existsSync, readFileSync } from 'node:fs';
import { FILE_EDIT_TOOLS, listSkills, readState, runHook, stateFile, writeState } from './lib/hook-io.mjs';
import { loadedSkills, readEntries, toolCalls, transcriptPathFor } from './lib/transcript.mjs';
import {
  addsRequire,
  editText,
  isSpecPath,
  isStoryPath,
  isVideUiEdit,
  looksLikeCharm,
  looksLikeVide,
  readOf,
  scriptsRead,
} from './lib/luau.mjs';
import { findRojoProject, instancePathOfFile, isInInstalledPackages, isWatchedLuauFile } from './lib/rojo.mjs';

// Denials in a row, with no gated call let through between them, after which the gate steps
// aside: by then it is likely failing to see a skill the agent did load.
const MAX_DENIAL_STREAK = 3;

const PACKAGE_EDIT_REASON =
  'Installed packages are generated: `pesde install` rewrites every file in `roblox_packages`, so an edit here ' +
  'is lost on the next install. Change the package at its source and update its version in pesde.toml. The ' +
  '`roblox-dev:rojo-workflow` skill covers packages.';

// Adds the skills the Luau an edit writes calls for. `path` is the script's DataModel path when
// known; `isGameCode` is false for Luau outside the place (a Lune tool), which needs no
// architecture rules.
function luauSkills(need, { tool, input, path, added, replaced, calls, isGameCode }) {
  need('luau-style-guide', 'it changes Luau');
  need('code-comments', 'it changes Luau, and every Luau edit follows the comment rules');
  const reads = scriptsRead(calls);
  const read = readOf(reads, path);
  if (read.vide || looksLikeVide(added) || isStoryPath(path)) {
    need('vide', 'the script uses Vide');
    if (isVideUiEdit(tool, input, path, reads)) {
      need('vide-ui-labs', 'it is a Vide component, screen, or story, and every one gets a UI Labs story');
    }
    if (read.charm || looksLikeCharm(added)) {
      need('vide-charm', 'the UI uses Charm state');
    }
  }
  if (isSpecPath(path)) {
    need('roblox-testing', 'the script is a spec');
  }
  if (isGameCode && addsRequire(added, replaced)) {
    need('game-architecture', 'it adds a require between modules');
  }
}

function readFileOr(path, fallback) {
  try {
    return readFileSync(path, 'utf8');
  } catch {
    return fallback;
  }
}

// For a Luau file edit in a Rojo repo or pesde workspace: { required } skills (a Map of skill to
// reason), or { denyReason } for a file that must not be edited. Undefined for any other file.
function fileRequiredSkills(tool, input, calls) {
  const file = input.file_path;
  if (!isWatchedLuauFile(file)) {
    return undefined;
  }
  if (isInInstalledPackages(file)) {
    return { denyReason: PACKAGE_EDIT_REASON };
  }
  const project = findRojoProject(file);
  const instancePath = project ? instancePathOfFile(project, file) : undefined;
  const isGameCode = !project || instancePath !== undefined;
  const path = instancePath ?? String(file).replace(/\.(luau|lua)$/i, '').replace(/[\\/]/g, '.');
  const { added, replaced: edited } = editText(tool, input);
  const exists = existsSync(file);
  // A whole-file write counts every require it adds over the file's current text.
  const replaced = tool === 'Write' ? readFileOr(file, '') : edited;
  const required = new Map();
  const need = (skill, reason) => {
    if (!required.has(skill)) {
      required.set(skill, reason);
    }
  };
  luauSkills(need, { tool, input, path, added, replaced, calls, isGameCode });
  if (tool === 'Write' && !exists && instancePath !== undefined) {
    need('game-architecture', 'it creates a script');
  }
  return { required };
}

function deny(reason) {
  return {
    hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: reason },
  };
}

runHook((input) => {
  const tool = input.tool_name;
  if (!FILE_EDIT_TOOLS.has(tool)) {
    return undefined;
  }
  const toolInput = input.tool_input ?? {};
  const check = fileRequiredSkills(tool, toolInput, []);
  if (check === undefined) {
    return undefined;
  }
  if (check.denyReason) {
    return deny(check.denyReason);
  }

  const transcript = transcriptPathFor(input);
  if (transcript === undefined || !existsSync(transcript)) {
    return undefined;
  }
  const entries = readEntries(transcript, { since: 'compaction' });
  const { required } = fileRequiredSkills(tool, toolInput, toolCalls(entries));
  const loaded = loadedSkills(entries);
  const missing = [...required].filter(([skill]) => !loaded.has(skill));

  const streakFile = stateFile(input.session_id, input.agent_id ?? 'main', 'gate');
  const streak = readState(streakFile, 0);
  if (missing.length === 0 || streak >= MAX_DENIAL_STREAK) {
    if (streak !== 0) {
      writeState(streakFile, 0);
    }
    return undefined;
  }
  writeState(streakFile, (Number.isInteger(streak) ? streak : 0) + 1);

  const reasons = missing.map(([skill, reason]) => `${listSkills([skill])} because ${reason}`).join('; ');
  return deny(
    `Load ${listSkills(missing.map(([skill]) => skill))} with the Skill tool, then retry this edit unchanged. ` +
    `Needed: ${reasons}. Only skills loaded under the \`roblox-dev:\` name count, and a skill that compaction cut ` +
    'short or dropped counts as not loaded.',
  );
});
