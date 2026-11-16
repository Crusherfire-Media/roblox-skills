// Soft skill reminders, added to the model's context. The skill gate is what enforces skills at
// edit time; these hints get them loaded earlier, while planning.
//   UserPromptSubmit           prompt wording that points at a skill not loaded yet.
//   PostToolUse (Read)         a Read of a Rojo repo's Luau file returned Vide UI or a spec.
//   SessionStart (compact)     skills loaded before compaction that it cut short or dropped.

import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { listSkills, responseText, runHook } from './lib/hook-io.mjs';
import { buildsVideUi, isSpecPath, isStoryPath, looksLikeCharm, looksLikeVide } from './lib/luau.mjs';
import { findRojoProject, instancePathOfFile, isLuauFile } from './lib/rojo.mjs';
import {
  isCompactBoundary,
  loadedSkills,
  readEntries,
  reattachedSkills,
  transcriptPathFor,
} from './lib/transcript.mjs';

// Compaction cuts each re-attached skill at this many characters.
const REATTACH_LIMIT = 20000;

const PROMPT_HINTS = [
  { pattern: /\b(vide|ui|gui|hud|screens?|menus?|buttons?|panels?|stor(y|ies)|ui labs)\b/i, skills: ['vide', 'vide-ui-labs', 'game-ui-design'], topic: 'UI' },
  { pattern: /\bcharm\b/i, skills: ['vide-charm'], topic: 'Charm state' },
  { pattern: /\bfigma\b/i, skills: ['figma-to-roblox'], topic: 'a Figma design' },
  { pattern: /\b(lag|laggy|fps|stutter\w*|slow|optimi[sz]\w*|perf|performance|profil\w*|memory|ping|benchmark\w*)\b/i, skills: ['roblox-performance'], topic: 'performance' },
  { pattern: /\b(specs?|jest|unit tests?|tdd|test-first|regression tests?)\b/i, skills: ['roblox-testing'], topic: 'specs' },
  { pattern: /\b(new (system|module|service|script)s?|module ?loader|cyclic|relocat\w*)\b/i, skills: ['game-architecture'], topic: 'module structure' },
  { pattern: /\b(rojo|pesde|syncback)\b/i, skills: ['rojo-workflow'], topic: 'the Rojo workflow' },
];

// Subagent reports and background-task notices arrive as prompts too; only the user's own
// wording says what the task is.
const NOT_FROM_USER = /<agent-message\b|<task-notification>|\[SYSTEM NOTIFICATION/;

function promptHint(input) {
  const prompt = String(input.prompt ?? '');
  if (NOT_FROM_USER.test(prompt.slice(0, 500))) {
    return undefined;
  }
  const matched = PROMPT_HINTS.filter((hint) => hint.pattern.test(prompt));
  if (matched.length === 0) {
    return undefined;
  }
  const loaded = loadedSkills(readEntries(transcriptPathFor(input), { since: 'compaction' }));
  const parts = matched
    .map((hint) => ({ ...hint, skills: hint.skills.filter((skill) => !loaded.has(skill)) }))
    .filter((hint) => hint.skills.length > 0)
    .map((hint) => `${hint.topic}: ${listSkills(hint.skills)}`);
  if (parts.length === 0) {
    return undefined;
  }
  return context(
    'UserPromptSubmit',
    `Skill hint from this prompt's wording (${parts.join('; ')}). If the task touches Luau game code, ` +
    'load the ones that apply before planning it.',
  );
}

// The DataModel path a Read of a Rojo repo's Luau file showed, else undefined.
function readPath(input) {
  const file = input.tool_input?.file_path;
  if (input.tool_name !== 'Read' || !isLuauFile(file)) {
    return undefined;
  }
  const project = findRojoProject(file);
  return project ? instancePathOfFile(project, file) : undefined;
}

function scriptReadHint(input) {
  const path = readPath(input);
  if (path === undefined) {
    return undefined;
  }
  const source = responseText(input.tool_response);
  const spec = isSpecPath(path);
  const needed = [];
  if (looksLikeVide(source) || isStoryPath(path)) {
    needed.push('vide');
    if ((buildsVideUi(source) || isStoryPath(path)) && !spec) {
      needed.push('vide-ui-labs');
    }
    if (looksLikeCharm(source)) {
      needed.push('vide-charm');
    }
  }
  if (spec) {
    needed.push('roblox-testing');
  }
  const transcript = transcriptPathFor(input);
  if (needed.length === 0 || transcript === undefined) {
    return undefined;
  }
  const loaded = loadedSkills(readEntries(transcript, { since: 'compaction' }));
  const missing = needed.filter((skill) => !loaded.has(skill));
  if (missing.length === 0) {
    return undefined;
  }
  return context(
    'PostToolUse',
    `${path} is ${spec ? 'a spec' : 'Vide code'}. Load ${listSkills(missing)} before editing it; the skill gate requires them.`,
  );
}

function skillTextLength(name) {
  if (!/^[a-z0-9-]{1,64}$/.test(name)) {
    return 0;
  }
  const file = fileURLToPath(new URL(`../skills/${name}/SKILL.md`, import.meta.url));
  if (!existsSync(file)) {
    return 0;
  }
  return readFileSync(file, 'utf8').replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '').length;
}

function compactionHint(input) {
  if (input.source !== 'compact') {
    return undefined;
  }
  const entries = readEntries(transcriptPathFor(input));
  const boundary = entries.findLastIndex(isCompactBoundary);
  if (boundary < 0) {
    return undefined;
  }
  const before = [...loadedSkills(entries.slice(0, boundary))];
  const reattached = entries.slice(boundary).flatMap(reattachedSkills);
  let lost;
  if (reattached.length > 0) {
    const whole = new Set(reattached.filter((skill) => !skill.truncated).map((skill) => skill.name));
    lost = before.filter((skill) => !whole.has(skill));
  } else {
    lost = before.filter((skill) => skillTextLength(skill) >= REATTACH_LIMIT);
  }
  if (lost.length === 0) {
    return undefined;
  }
  return context(
    'SessionStart',
    `Compaction cut short or dropped these skills that were loaded before it: ${listSkills(lost)}. ` +
    'Reload the ones the remaining work needs with the Skill tool before relying on them; the skill gate treats them as not loaded.',
  );
}

function context(hookEventName, additionalContext) {
  return { hookSpecificOutput: { hookEventName, additionalContext } };
}

runHook((input) => {
  switch (input.hook_event_name) {
    case 'UserPromptSubmit':
      return promptHint(input);
    case 'PostToolUse':
      return scriptReadHint(input);
    case 'SessionStart':
      return compactionHint(input);
    default:
      return undefined;
  }
});
