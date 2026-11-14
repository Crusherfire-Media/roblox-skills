// PostToolUse on Luau file edits in a Rojo repo or pesde workspace: reports new lines that break
// the mechanical comment and style conventions back to the model as context. It never blocks,
// since the edit already landed.

import { FILE_EDIT_TOOLS, runHook } from './lib/hook-io.mjs';
import { editText, lintLuau, newLines } from './lib/luau.mjs';
import { isWatchedLuauFile } from './lib/rojo.mjs';

const MAX_FINDINGS = 8;

// The new lines of a Luau file edit in a Rojo repo or pesde workspace, or undefined for any
// other file. A Write's old text comes from the tool's response when it carries one.
function fileEditLines(tool, args, response) {
  if (!isWatchedLuauFile(args.file_path)) {
    return undefined;
  }
  const { added, replaced } = editText(tool, args);
  const original = typeof response?.originalFile === 'string' ? response.originalFile : '';
  return newLines(added, tool === 'Write' ? original : replaced);
}

function lintContext(target, lines) {
  const findings = lintLuau(lines);
  if (findings.length === 0) {
    return undefined;
  }
  const shown = findings.slice(0, MAX_FINDINGS).map((finding) => `- ${finding}`);
  if (findings.length > MAX_FINDINGS) {
    shown.push(`- and ${findings.length - MAX_FINDINGS} more`);
  }
  return `Luau convention check on the lines this edit added to ${target}:\n${shown.join('\n')}\n` +
    'Fix them with a follow-up edit, unless a finding is a false match (for example, text the user asked for verbatim).';
}

runHook((input) => {
  if (!FILE_EDIT_TOOLS.has(input.tool_name)) {
    return undefined;
  }
  const args = input.tool_input ?? {};
  const lines = fileEditLines(input.tool_name, args, input.tool_response);
  const context = lines && lintContext(args.file_path, lines);
  return context ? { hookSpecificOutput: { hookEventName: 'PostToolUse', additionalContext: context } } : undefined;
});
