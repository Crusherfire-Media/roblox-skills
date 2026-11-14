// Reads Claude Code session transcripts (JSONL, one entry per line). Transcript entries are
// an internal format, not a documented API: every reader here tolerates missing fields, and
// callers fail open when nothing can be read.

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { basename, join, resolve } from 'node:path';
import { FILE_EDIT_TOOLS, ownSkillName } from './hook-io.mjs';
import { findRojoProject, instancePathOfFile, isWatchedLuauFile } from './rojo.mjs';

const COMPACT_BOUNDARY = '"subtype":"compact_boundary"';
const HUMAN_ORIGIN = '"origin":{"kind":"human"';
// Compaction re-attaches each loaded skill cut at 20,000 characters and ends a cut one with this.
const TRUNCATED_SKILL_MARKER = 'skill content truncated for compaction';
const COMMAND_NAME = /<command-name>\/?([^<\s]+)<\/command-name>/g;
const AGENT_ID = /^[A-Za-z0-9_-]{1,64}$/;

// The transcript of the agent a hook fires in. In a subagent that is its own file, found among
// plain subagents or workflow runs; undefined when it can't be found, so callers fail open
// instead of judging the subagent by the main transcript.
export function transcriptPathFor(input) {
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
  if (basename(main) === `agent-${agentId}.jsonl`) {
    return main;
  }
  return agentTranscripts(main).find((path) => basename(path) === `agent-${agentId}.jsonl`);
}

// The session's subagent transcripts, plain and workflow, optionally only those written since
// a time (milliseconds).
export function agentTranscripts(mainPath, { modifiedSince = 0 } = {}) {
  if (typeof mainPath !== 'string' || !mainPath.endsWith('.jsonl')) {
    return [];
  }
  const dir = join(mainPath.replace(/\.jsonl$/, ''), 'subagents');
  const runs = join(dir, 'workflows');
  const folders = [dir, ...(existsSync(runs) ? readdirSync(runs).map((run) => join(runs, run)) : [])];
  return folders.flatMap((folder) => (existsSync(folder) ? readdirSync(folder) : [])
    .filter((name) => name.startsWith('agent-') && name.endsWith('.jsonl'))
    .map((name) => join(folder, name)))
    .filter((path) => modifiedSince === 0 || statSync(path).mtimeMs >= modifiedSince);
}

// The text from the line holding the last entry that contains the marker and passes the
// check, so marker text quoted inside some other entry is never taken for it.
function sliceFromLast(text, marker, accept) {
  let searchFrom = text.length;
  for (;;) {
    const at = text.lastIndexOf(marker, searchFrom);
    if (at < 0) {
      return undefined;
    }
    const start = text.lastIndexOf('\n', at) + 1;
    const end = text.indexOf('\n', at);
    try {
      if (accept(JSON.parse(text.slice(start, end < 0 ? undefined : end)))) {
        return text.slice(start);
      }
    } catch {
      // Not a whole entry; keep looking.
    }
    if (start === 0) {
      return undefined;
    }
    searchFrom = start - 1;
  }
}

// Entries in order. `since: 'compaction'` starts at the last compaction, `since: 'turn'` at the
// user's latest prompt; with neither marker present, the whole transcript is read.
export function readEntries(path, { since } = {}) {
  if (typeof path !== 'string' || !existsSync(path)) {
    return [];
  }
  let text = readFileSync(path, 'utf8');
  if (since === 'compaction') {
    text = sliceFromLast(text, COMPACT_BOUNDARY, isCompactBoundary) ?? text;
  } else if (since === 'turn') {
    text = sliceFromLast(text, HUMAN_ORIGIN, isHumanPrompt) ?? text;
  }
  const entries = [];
  for (const line of text.split('\n')) {
    if (line.trim() === '') {
      continue;
    }
    try {
      entries.push(JSON.parse(line));
    } catch {
      // A line still being written.
    }
  }
  return entries;
}

export function isCompactBoundary(entry) {
  return entry?.type === 'system' && entry.subtype === 'compact_boundary';
}

function blocksOf(entry) {
  const content = entry?.message?.content;
  if (Array.isArray(content)) {
    return content;
  }
  return typeof content === 'string' ? [{ type: 'text', text: content }] : [];
}

function textOf(content) {
  if (typeof content === 'string') {
    return content;
  }
  if (!Array.isArray(content)) {
    return '';
  }
  return content.map((block) => (typeof block?.text === 'string' ? block.text : '')).join('\n');
}

// The text of user-side entries that aren't tool results: prompts, and notes such as a
// "Stop hook feedback" message.
export function userTexts(entries) {
  return entries
    .filter((entry) => entry.type === 'user' && !blocksOf(entry).some((block) => block?.type === 'tool_result'))
    .map((entry) => textOf(entry.message?.content));
}

// Every tool call in order, each with its result once one was recorded.
export function toolCalls(entries) {
  const calls = [];
  const byId = new Map();
  for (const entry of entries) {
    for (const block of blocksOf(entry)) {
      if (entry.type === 'assistant' && block?.type === 'tool_use') {
        const call = {
          id: block.id,
          name: String(block.name ?? ''),
          input: block.input ?? {},
          timestamp: Date.parse(entry.timestamp ?? '') || 0,
          result: undefined,
          isError: false,
        };
        calls.push(call);
        byId.set(block.id, call);
      } else if (entry.type === 'user' && block?.type === 'tool_result') {
        const call = byId.get(block.tool_use_id);
        if (call) {
          call.result = textOf(block.content);
          call.isError = block.is_error === true;
        }
      }
    }
  }
  return calls;
}

// This plugin's skills whose full text is in the context these entries describe, by bare name:
// loaded with the Skill tool, typed as /name, preloaded from agent frontmatter (both appear as
// <command-name>), or re-attached by compaction without being cut short. Only names spelled
// `roblox-dev:<name>` count (see ownSkillName).
export function loadedSkills(entries) {
  const skills = new Set();
  const add = (name) => {
    const own = ownSkillName(name);
    if (own !== undefined) {
      skills.add(own);
    }
  };
  for (const call of toolCalls(entries)) {
    if (call.name === 'Skill' && !call.isError) {
      add(call.input.skill);
    }
  }
  for (const entry of entries) {
    if (entry.type === 'user') {
      for (const block of blocksOf(entry)) {
        if (block?.type === 'text' && typeof block.text === 'string') {
          for (const match of block.text.matchAll(COMMAND_NAME)) {
            add(match[1]);
          }
        }
      }
    }
    for (const skill of reattachedSkills(entry)) {
      if (!skill.truncated) {
        skills.add(skill.name);
      }
    }
  }
  return skills;
}

// This plugin's skills a compaction re-attached in this entry, if it is that attachment.
export function reattachedSkills(entry) {
  const attachment = entry?.type === 'attachment' ? entry.attachment : undefined;
  if (attachment?.type !== 'invoked_skills' || !Array.isArray(attachment.skills)) {
    return [];
  }
  return attachment.skills
    .map((skill) => ({ name: ownSkillName(skill?.name), content: skill?.content }))
    .filter((skill) => skill.name !== undefined)
    .map((skill) => ({
      name: skill.name,
      truncated: String(skill.content ?? '').includes(TRUNCATED_SKILL_MARKER),
    }));
}

export function isHumanPrompt(entry) {
  return entry?.type === 'user' && entry.origin?.kind === 'human' && !blocksOf(entry).some((block) => block?.type === 'tool_result');
}

// Successful edits of Luau files in Rojo repos and pesde workspaces, one per call: `file` is
// the resolved file path, and `path` the normalized DataModel path of the script it becomes
// (undefined for a file the project doesn't map into the place, such as a Lune tool).
export function fileEdits(calls) {
  return calls.flatMap((call) => {
    const file = call.input.file_path;
    if (!FILE_EDIT_TOOLS.has(call.name) || call.isError || !isWatchedLuauFile(file)) {
      return [];
    }
    const project = findRojoProject(file);
    return [{ ...call, file: resolve(file), path: project ? instancePathOfFile(project, file) : undefined }];
  });
}
