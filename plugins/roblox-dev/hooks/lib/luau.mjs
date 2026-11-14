// Recognizes what kind of Luau a script or an edit holds, and checks new Luau against the
// mechanical comment and style conventions. Detection is heuristic: a false match only costs a
// skill load, so the patterns lean toward matching.

import { normalizePath } from './hook-io.mjs';
import { findRojoProject, instancePathOfFile, isLuauFile } from './rojo.mjs';

const VIDE_PATTERNS = [
  /require\s*\(?[^)\n]*\bvide\b/i,
  /\bvide\.(create|source|derive|effect|mount|root|show|switch|indexes|values|spring|cleanup|untrack|batch|action|changed)\b/i,
  /\bcreate\s*"[A-Z]\w*"\s*\{/,
  /\bcreate\s*\(\s*"[A-Z]\w*"\s*\)\s*\(?\s*\{/,
];
const CHARM_PATTERNS = [
  /require\s*\(?[^)\n]*\b(charm|charm-sync|charmsync|vide-charm)\b/i,
  /\buseSignalState\b/,
];
// Building instances is what makes Vide code a component or screen, rather than a module that
// only uses Vide's reactive state.
const VIDE_UI_PATTERNS = [
  /\bcreate\s*"[A-Z]\w*"/,
  /\bcreate\s*\(\s*"[A-Z]\w*"\s*\)/,
  /\bvide\.create\b/i,
];
const REQUIRE_LINE = /\brequire\s*\(/;
const SPEC_PATH = /\.spec$/i;
const STORY_PATH = /(\.story|\.storybook)$|(^|\.)Stories(\.|$)/i;

export function looksLikeVide(text) {
  return typeof text === 'string' && VIDE_PATTERNS.some((pattern) => pattern.test(text));
}

export function buildsVideUi(text) {
  return typeof text === 'string' && VIDE_UI_PATTERNS.some((pattern) => pattern.test(text));
}

export function looksLikeCharm(text) {
  return typeof text === 'string' && CHARM_PATTERNS.some((pattern) => pattern.test(text));
}

export function isSpecPath(path) {
  return SPEC_PATH.test(normalizePath(path));
}

export function isStoryPath(path) {
  return STORY_PATH.test(normalizePath(path));
}

// The Luau a file edit tool call writes, and the text it replaces when the call says.
export function editText(tool, input) {
  switch (tool) {
    case 'Edit':
      return { added: String(input.new_string ?? ''), replaced: String(input.old_string ?? '') };
    case 'Write':
      return { added: String(input.content ?? ''), replaced: '' };
    case 'MultiEdit': {
      const edits = Array.isArray(input.edits) ? input.edits : [];
      return {
        added: edits.map((edit) => String(edit?.new_string ?? '')).join('\n'),
        replaced: edits.map((edit) => String(edit?.old_string ?? '')).join('\n'),
      };
    }
    default:
      return { added: '', replaced: '' };
  }
}

const NOTHING_READ = Object.freeze({ vide: false, ui: false, charm: false });

// The DataModel path a Read of a Rojo repo's Luau file showed. Undefined for anything else.
function readPath(call) {
  if (call.name === 'Read' && isLuauFile(call.input.file_path)) {
    const project = findRojoProject(call.input.file_path);
    return project ? instancePathOfFile(project, call.input.file_path) : undefined;
  }
  return undefined;
}

// What earlier Reads in a Rojo repo showed about each script, by normalized DataModel path.
export function scriptsRead(calls) {
  const seen = new Map();
  for (const call of calls) {
    const path = call.result ? readPath(call) : undefined;
    if (path === undefined) {
      continue;
    }
    const prior = seen.get(path) ?? NOTHING_READ;
    seen.set(path, {
      vide: prior.vide || looksLikeVide(call.result),
      ui: prior.ui || buildsVideUi(call.result),
      charm: prior.charm || looksLikeCharm(call.result),
    });
  }
  return seen;
}

export function readOf(reads, path) {
  return reads.get(normalizePath(path)) ?? NOTHING_READ;
}

// Whether an edit to the script at path makes it a Vide component, screen, or story, judged
// from the text it writes and what reads (from scriptsRead) showed about the script.
export function isVideUiEdit(tool, input, path, reads) {
  const { added } = editText(tool, input);
  const read = readOf(reads, path);
  const story = isStoryPath(path);
  return (read.vide || looksLikeVide(added) || story) && (read.ui || buildsVideUi(added) || story) && !isSpecPath(path);
}

// Lines of the new text that were not already in the replaced text, so existing code that an
// edit only carries along is not reported or counted as new.
export function newLines(added, replaced) {
  const existing = new Map();
  for (const line of replaced.split(/\r?\n/)) {
    const key = line.trim();
    existing.set(key, (existing.get(key) ?? 0) + 1);
  }
  const fresh = [];
  for (const line of added.split(/\r?\n/)) {
    const key = line.trim();
    const count = existing.get(key) ?? 0;
    if (count > 0) {
      existing.set(key, count - 1);
    } else {
      fresh.push(line);
    }
  }
  return fresh;
}

export function addsRequire(added, replaced) {
  return newLines(added, replaced).some((line) => REQUIRE_LINE.test(stripComment(line)));
}

const EM_DASH = String.fromCodePoint(0x2014);

// Each matches one whole word, so identifiers like `percentRemaining` never match "centre".
const BRITISH_WORDS = [
  [/^colour(s|ed|ing|ful)?$/, 'color'],
  [/^centre(s|d)?$/, 'center'],
  [/^behaviour(s|al)?$/, 'behavior'],
  [/^neighbour(s|ing|hood)?$/, 'neighbor'],
  [/^favourite(s)?$/, 'favorite'],
  [/^honour(s|ed)?$/, 'honor'],
  [/^cancell(ed|ing)$/, 'canceled / canceling'],
  [/^labell(ed|ing)$/, 'labeled / labeling'],
  [/^modell(ed|ing)$/, 'modeled / modeling'],
  [/^travell(ed|ing)$/, 'traveled / traveling'],
  [/^catalogue(s)?$/, 'catalog'],
  [/^licence(s)?$/, 'license'],
  [/^(initiali|normali|organi|recogni|customi|optimi|seriali|deseriali|synchroni|visuali|finali|prioriti|minimi|maximi)s(e|ed|es|ing|ation|er|ers)$/, 'the -ize spelling'],
  [/^analys(e|ed|ing)$/, 'analyze'],
];

const ONE_LINE_GUARD = /^\s*if\s.+\sthen\s+(return|continue|break)\b.*\bend\s*;?\s*$/;

// Blanks string contents, keeping the line's length so positions still match the original.
function withoutStrings(line) {
  return line.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`/g, (literal) =>
    `${literal[0]}${' '.repeat(literal.length - 2)}${literal[literal.length - 1]}`);
}

function commentStart(line) {
  return withoutStrings(line).indexOf('--');
}

function stripComment(line) {
  const at = commentStart(line);
  return at >= 0 ? line.slice(0, at) : line;
}

// The words a line writes itself: comment words outside `code spans`, and the identifier parts
// of its code, split at camelCase and underscores. String contents and member names (after "."
// or ":") are skipped, since they can be existing APIs or data the code has to match, such as
// Enum.PlaybackState.Cancelled.
function ownWords(code, comment) {
  const memberFree = (text) => text.replace(/[.:][A-Za-z_]\w*/g, ' ');
  const text = `${memberFree(withoutStrings(code))} ${memberFree(comment.replace(/`[^`]*`/g, ' '))}`;
  return (text.match(/[A-Za-z]+/g) ?? []).flatMap((token) => token.split(/(?<=[a-z])(?=[A-Z])/));
}

function britishSpelling(words) {
  for (const word of words) {
    for (const [pattern, american] of BRITISH_WORDS) {
      if (pattern.test(word.toLowerCase())) {
        return `British spelling "${word}" (use ${american})`;
      }
    }
  }
  return undefined;
}

// Convention problems in the lines an edit adds, each with a short excerpt of the line.
export function lintLuau(lines) {
  const findings = [];
  let inBlockComment = false;
  for (const line of lines) {
    const excerpt = line.trim().slice(0, 80);
    let code = line;
    let comment = '';
    if (inBlockComment) {
      inBlockComment = !line.includes(']]');
      code = '';
      comment = line;
      if (comment.includes(EM_DASH)) {
        findings.push(`em dash in a comment; use a comma, colon, parentheses, or a new sentence: \`${excerpt}\``);
      }
    } else {
      const at = commentStart(line);
      if (at >= 0) {
        code = line.slice(0, at);
        comment = line.slice(at + 2);
      }
      if (comment.startsWith('[[')) {
        inBlockComment = !comment.includes(']]');
        if (!/^\[\[\s*(@description:\s*)?$/.test(comment)) {
          findings.push(`block comment text on the \`--[[\` line; put \`--[[\` and \`]]\` on their own lines: \`${excerpt}\``);
        }
      } else if (comment.includes(EM_DASH)) {
        findings.push(`em dash in a comment; use a comma, colon, parentheses, or a new sentence: \`${excerpt}\``);
      } else if (/\s--\s+\S/.test(comment)) {
        findings.push(`"--" used as a dash inside a comment: \`${excerpt}\``);
      }
      if (ONE_LINE_GUARD.test(code)) {
        findings.push(`one-line guard clause; expand it over several lines: \`${excerpt}\``);
      }
    }
    const spelling = britishSpelling(ownWords(code, comment));
    if (spelling) {
      findings.push(`${spelling}: \`${excerpt}\``);
    }
  }
  return findings;
}
