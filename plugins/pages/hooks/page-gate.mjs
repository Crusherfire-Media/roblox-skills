// PreToolUse gate on Write: a new HTML page is denied until the html-kit skill is loaded, and
// until it loads kit/kit.js or opts out with <html data-kit="off">. The deny reason goes back to
// the model, which fixes the page and retries. Existing pages pass, so older freeform pages can
// still be edited.
//
// Every failure fails open: on any error the hook prints nothing and the write goes ahead.

import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, join } from 'node:path';

const SKILL = 'html-kit';
const SKILL_NAME = /^\/?(?:pages:)?html-kit$/;
const HTML_FILE = /\.html?$/i;
const LOADS_KIT = /<script\b[^>]*\bsrc\s*=\s*["']?[^"'\s>]*kit\/kit\.js\b/i;
const OPTED_OUT = /<html\b[^>]*\bdata-kit\s*=\s*["']?off\b/i;
// Compaction re-attaches each loaded skill cut at 20,000 characters and ends a cut one with this.
const TRUNCATED_SKILL_MARKER = 'skill content truncated for compaction';
const AGENT_ID = /^[A-Za-z0-9_-]{1,64}$/;
const STATE_KEY = /^[A-Za-z0-9_-]{1,100}$/;
// Denials in a row after which the gate steps aside: by then it is likely misreading the transcript.
const MAX_DENIAL_STREAK = 3;

// The transcript of the agent the hook fires in: a subagent's own file when there is one.
function transcriptPathFor(input) {
  const main = input?.transcript_path;
  if (typeof main !== 'string' || main === '') {
    return undefined;
  }
  const agentId = input.agent_id;
  if (agentId === undefined || agentId === null || agentId === '') {
    return main;
  }
  if (typeof agentId !== 'string' || !AGENT_ID.test(agentId)) {
    return undefined;
  }
  const name = `agent-${agentId}.jsonl`;
  if (basename(main) === name) {
    return main;
  }
  const dir = join(main.replace(/\.jsonl$/, ''), 'subagents');
  const runs = join(dir, 'workflows');
  const folders = [dir, ...(existsSync(runs) ? readdirSync(runs).map((run) => join(runs, run)) : [])];
  return folders.map((folder) => join(folder, name)).find((path) => existsSync(path));
}

// Entries since the last compaction (a compact_boundary entry), or the whole transcript.
function entriesSinceCompaction(path) {
  const entries = readFileSync(path, 'utf8').split('\n').flatMap((line) => {
    if (line.trim() === '') {
      return [];
    }
    try {
      return [JSON.parse(line)];
    } catch {
      return [];
    }
  });
  const boundary = entries.findLastIndex((entry) => entry?.type === 'system' && entry.subtype === 'compact_boundary');
  return boundary < 0 ? entries : entries.slice(boundary);
}

function blocksOf(entry) {
  const content = entry?.message?.content;
  if (Array.isArray(content)) {
    return content;
  }
  return typeof content === 'string' ? [{ type: 'text', text: content }] : [];
}

// Loaded with the Skill tool, typed or preloaded (both appear as <command-name>), or re-attached
// in full by compaction.
function skillLoaded(entries) {
  return entries.some((entry) => {
    if (entry?.type === 'attachment' && entry.attachment?.type === 'invoked_skills' && Array.isArray(entry.attachment.skills)) {
      return entry.attachment.skills.some((skill) => SKILL_NAME.test(String(skill?.name ?? ''))
        && !String(skill?.content ?? '').includes(TRUNCATED_SKILL_MARKER));
    }
    return blocksOf(entry).some((block) => {
      if (entry.type === 'assistant' && block?.type === 'tool_use' && block.name === 'Skill') {
        return SKILL_NAME.test(String(block.input?.skill ?? ''));
      }
      if (entry.type === 'user' && block?.type === 'text' && typeof block.text === 'string') {
        return [...block.text.matchAll(/<command-name>([^<\s]+)<\/command-name>/g)].some((match) => SKILL_NAME.test(match[1]));
      }
      return false;
    });
  });
}

// Session state lives in the OS temp folder. Keys come from hook input, so they are checked to
// keep the file name inside that folder; with a bad key there is no state.
function streakFile(input) {
  const keys = [input.session_id, input.agent_id ?? 'main'];
  if (!keys.every((key) => typeof key === 'string' && STATE_KEY.test(key))) {
    return undefined;
  }
  return join(tmpdir(), 'claude-page-gate', `${keys.join('-')}.json`);
}

function readStreak(file) {
  try {
    const value = JSON.parse(readFileSync(file, 'utf8'));
    return Number.isInteger(value) ? value : 0;
  } catch {
    return 0;
  }
}

function writeStreak(file, value) {
  if (file === undefined) {
    return;
  }
  mkdirSync(join(tmpdir(), 'claude-page-gate'), { recursive: true });
  writeFileSync(file, JSON.stringify(value));
}

function problemsWith(input) {
  const path = input.tool_input?.file_path;
  const content = input.tool_input?.content;
  if (typeof path !== 'string' || typeof content !== 'string' || !HTML_FILE.test(path) || existsSync(path)) {
    return [];
  }
  const problems = [];
  const transcript = transcriptPathFor(input);
  if (transcript !== undefined && existsSync(transcript) && !skillLoaded(entriesSinceCompaction(transcript))) {
    problems.push(`Load \`pages:${SKILL}\` with the Skill tool first: it sets up the kit folder and lists the components.`);
  }
  if (!LOADS_KIT.test(content) && !OPTED_OUT.test(content)) {
    problems.push(
      'New pages are written with the html-kit: start the file with the first line the skill gives, which loads ' +
      'kit/kit.js, and write the content as kit components. A page that has to be freeform (a game-UI mockup) ' +
      'adds data-kit="off" to its <html> tag instead.',
    );
  }
  return problems;
}

function main() {
  let input;
  try {
    input = JSON.parse(readFileSync(0, 'utf8'));
  } catch {
    return;
  }
  const problems = problemsWith(input);
  const file = streakFile(input);
  const streak = file === undefined ? 0 : readStreak(file);
  if (problems.length === 0 || streak >= MAX_DENIAL_STREAK) {
    if (streak !== 0) {
      writeStreak(file, 0);
    }
    return;
  }
  writeStreak(file, streak + 1);
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: `${problems.join(' ')} Then retry this write.`,
    },
  }));
}

try {
  main();
} catch (error) {
  process.stderr.write(`page gate skipped: ${error?.message ?? error}\n`);
}
