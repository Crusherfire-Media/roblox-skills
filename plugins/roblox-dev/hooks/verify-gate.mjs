// Stop gate: runs luau-lsp analyze, selene, and stylua --check on the Luau files edited since
// the user's latest prompt, by this agent or its subagents, and blocks the stop when they report
// findings. Checks that can't run (a tool is missing, the project lacks type definitions, a
// sourcemap, or a config file) are skipped with a one-line note to the user instead.
//
// It blocks once per prompt: when Claude Code is already continuing because of a stop hook
// (`stop_hook_active`), or this gate's feedback is already in the turn, the stop goes through.
// The model may have fixed the findings, or explained why one doesn't apply.

import { existsSync, statSync } from 'node:fs';
import { resolve } from 'node:path';
import { runHook } from './lib/hook-io.mjs';
import { agentTranscripts, fileEdits, isHumanPrompt, readEntries, toolCalls, userTexts } from './lib/transcript.mjs';
import { findRojoProject } from './lib/rojo.mjs';
import { filesInRoot, findTool, runChecks } from './lib/verify.mjs';

// Starts every block reason, so a later stop can see this gate already blocked once.
const BLOCK_HEADING = 'Luau checks before this turn ends:';
const TOOLS = ['luau-lsp', 'selene', 'stylua'];

function isDirectory(path) {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

// The project root the checks run in: the Rojo repo holding the session's folder, else that
// folder itself (a pesde workspace).
function projectRoot(cwd) {
  if (typeof cwd !== 'string' || cwd === '' || !isDirectory(cwd)) {
    return undefined;
  }
  return findRojoProject(cwd)?.root ?? resolve(cwd);
}

// The Luau files edited in this turn: by the main agent since the prompt, and by subagents
// whose transcripts changed since then.
function editedFiles(transcriptPath, entries) {
  const turnStart = isHumanPrompt(entries[0]) ? Date.parse(entries[0].timestamp ?? '') || 0 : 0;
  const subagentCalls = agentTranscripts(transcriptPath, { modifiedSince: turnStart })
    .flatMap((path) => toolCalls(readEntries(path)))
    .filter((call) => call.timestamp >= turnStart);
  return [...fileEdits(toolCalls(entries)), ...fileEdits(subagentCalls)].map((edit) => edit.file);
}

function noteMessage(notes) {
  return notes.length > 0 ? `roblox-dev verify-gate:\n${notes.map((note) => `- ${note}`).join('\n')}` : undefined;
}

runHook((input) => {
  if (input.stop_hook_active === true) {
    return undefined;
  }
  const transcriptPath = input.transcript_path;
  if (typeof transcriptPath !== 'string' || !existsSync(transcriptPath)) {
    return undefined;
  }
  const entries = readEntries(transcriptPath, { since: 'turn' });
  if (entries.length === 0 || userTexts(entries).some((text) => text.includes(BLOCK_HEADING))) {
    return undefined;
  }
  const root = projectRoot(input.cwd);
  if (root === undefined) {
    return undefined;
  }
  const files = filesInRoot(root, editedFiles(transcriptPath, entries));
  if (files.length === 0) {
    return undefined;
  }

  const tools = Object.fromEntries(TOOLS.map((name) => [name, findTool(name)]));
  const { findings, notes } = runChecks({ root, files, tools });
  if (findings.length === 0) {
    const message = noteMessage(notes);
    return message ? { systemMessage: message } : undefined;
  }

  const sections = findings.map((finding) => `${finding.tool}:\n${finding.lines.join('\n')}`);
  const skipped = notes.length > 0 ? `\n\nSkipped checks:\n${notes.map((note) => `- ${note}`).join('\n')}` : '';
  return {
    decision: 'block',
    reason:
      `${BLOCK_HEADING}\n\n${sections.join('\n\n')}\n\n` +
      'Fix these in the files you edited, then finish. If a finding is a false match or lies outside this task, ' +
      `say so in your reply instead; the next stop goes through.${skipped}`,
  };
});
