// Runs luau-lsp analyze, selene, and stylua --check on a set of Luau files in one project, and
// sorts what they print into findings (problems in the files) and notes (a check that could not
// run, and why). A check runs only when the project has what it needs to give true answers:
// without Roblox type definitions and a sourcemap luau-lsp reports every Roblox global as
// unknown, and without selene.toml selene reports `game` as undefined.
//
// Security: the tools run without a shell, with argument arrays, a timeout, and the project root
// as their working directory. Every file passed to them is checked to sit inside that root. Tool
// lookup ignores relative PATH entries, so a repo can't plant its own `stylua` and have it run.

import { spawnSync } from 'node:child_process';
import { accessSync, constants, readdirSync, readFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { delimiter, isAbsolute, join, relative, resolve } from 'node:path';
import { forwardSlashes, isInInstalledPackages, isLuauFile } from './rojo.mjs';

export const TOOL_TIMEOUT_MS = 45000;
const MAX_FILES = 100;
const MAX_LINES_PER_TOOL = 20;
const MAX_OUTPUT_BYTES = 4 * 1024 * 1024;
const DEFINITIONS_URL = 'https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau';
const DEFINITIONS_FILE = /^globalTypes(\.[A-Za-z]+)?\.d\.luau$/;
const DEFINITIONS_DIRS = ['.', 'types'];
const SETTINGS_FILE = '.vscode/settings.json';
const SOURCEMAP_FILE = 'sourcemap.json';
const STYLUA_CONFIGS = ['stylua.toml', '.stylua.toml'];

// luau-lsp's default formatter: `src/Shop.luau(3,7): TypeError: Unknown global 'x'`.
const LUAU_LSP_FINDING = /^.+\(\d+,\d+\): \w+: .+$/;
// selene's quiet display style: `src/Shop.luau:3:7: warning[unused_variable]: ...`.
const SELENE_FINDING = /^.+:\d+:\d+: (error|warning)\[[\w-]+\]: .+$/;
// stylua --check names each file that needs formatting: `Diff in src/Shop.luau:`.
const STYLUA_FINDING = /^Diff in (.+):$/;

function isFile(path) {
  try {
    return statSync(path).isFile();
  } catch {
    return false;
  }
}

function isExecutable(path, platform) {
  if (!isFile(path)) {
    return false;
  }
  if (platform === 'win32') {
    return true;
  }
  try {
    accessSync(path, constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

// The directory Rokit installs its tool shims into.
export function rokitBin(home = homedir()) {
  return join(home, '.rokit', 'bin');
}

// The absolute path of a tool's executable, from PATH or Rokit's bin, else undefined. On Windows
// only `.exe` files count: a `.cmd` or `.bat` file can't run without a shell.
export function findTool(name, { env = process.env, home = homedir(), platform = process.platform } = {}) {
  const pathValue = env.PATH ?? env.Path ?? '';
  const dirs = [...pathValue.split(delimiter), rokitBin(home)]
    .map((dir) => dir.trim().replace(/^"(.*)"$/, '$1'))
    .filter((dir) => dir !== '' && isAbsolute(dir));
  const fileName = platform === 'win32' ? `${name}.exe` : name;
  for (const dir of dirs) {
    const candidate = join(dir, fileName);
    if (isExecutable(candidate, platform)) {
      return candidate;
    }
  }
  return undefined;
}

// Each Luau file as a path relative to root with forward slashes, keeping only existing files
// inside root and outside installed packages. Files elsewhere are dropped: the tools only ever
// receive paths under the project root.
export function filesInRoot(root, files) {
  const kept = new Set();
  for (const file of files) {
    if (typeof file !== 'string' || !isLuauFile(file)) {
      continue;
    }
    const absolute = resolve(root, file);
    const rel = relative(root, absolute);
    if (rel === '' || rel.startsWith('..') || isAbsolute(rel) || !isFile(absolute) || isInInstalledPackages(absolute)) {
      continue;
    }
    const path = forwardSlashes(rel);
    // A leading "-" would read as a flag.
    kept.add(path.startsWith('-') ? `./${path}` : path);
  }
  return [...kept].sort();
}

// A JSON file that may hold comments and trailing commas, as VS Code settings files often do.
// Returns { value, strict }: strict is true when the text was plain JSON.
function readLooseJson(path) {
  let text;
  try {
    text = readFileSync(path, 'utf8');
  } catch {
    return undefined;
  }
  try {
    return { value: JSON.parse(text), strict: true };
  } catch {
    // Fall through to the lenient read.
  }
  const stripped = text
    .replace(/("(?:[^"\\]|\\.)*")|\/\*[\s\S]*?\*\/|\/\/[^\n]*/g, (match, string) => string ?? '')
    .replace(/,(\s*[}\]])/g, '$1');
  try {
    return { value: JSON.parse(stripped), strict: false };
  } catch {
    return undefined;
  }
}

function insideRoot(root, path) {
  const rel = relative(root, resolve(root, path));
  return rel !== '' && !rel.startsWith('..') && !isAbsolute(rel);
}

// What the project offers luau-lsp: definition files (name to path relative to root), the
// sourcemap, and the settings file when luau-lsp can read it as is.
export function luauLspSetup(root) {
  const definitions = new Map();
  let settingsPath;
  const settings = readLooseJson(join(root, SETTINGS_FILE));
  const configured = settings?.value?.['luau-lsp.types.definitionFiles'];
  let hasRemoteDefinitions = false;
  if (configured && typeof configured === 'object') {
    const pairs = Array.isArray(configured)
      ? configured.map((path, index) => [`@roblox${index + 1}`, path])
      : Object.entries(configured);
    for (const [name, path] of pairs) {
      if (typeof path !== 'string') {
        continue;
      }
      if (/^[a-z]+:\/\//i.test(path)) {
        hasRemoteDefinitions = true;
      } else if (/^@?[\w-]+$/.test(name) && insideRoot(root, path) && isFile(resolve(root, path))) {
        definitions.set(name.startsWith('@') ? name : `@${name}`, forwardSlashes(relative(root, resolve(root, path))));
      }
    }
  }
  const fromSettings = definitions.size > 0;
  if (!fromSettings) {
    for (const dir of DEFINITIONS_DIRS) {
      let names = [];
      try {
        names = readdirSync(join(root, dir)).filter((name) => DEFINITIONS_FILE.test(name)).sort();
      } catch {
        continue;
      }
      if (names.length > 0) {
        definitions.set('@roblox', dir === '.' ? names[0] : `${dir}/${names[0]}`);
        break;
      }
    }
  }
  // luau-lsp loads the settings file's definitionFiles itself and has no way to fetch a URL, and
  // it skips a settings file it can't parse, so the file is passed only when it helps. When it
  // is passed, the definitions it lists are left to it rather than loaded twice.
  let definitionArgs = definitions;
  if (settings?.strict && !hasRemoteDefinitions) {
    settingsPath = SETTINGS_FILE;
    if (fromSettings) {
      definitionArgs = new Map();
    }
  }
  const sourcemap = isFile(join(root, SOURCEMAP_FILE)) ? SOURCEMAP_FILE : undefined;
  return { definitions, definitionArgs, sourcemap, settingsPath };
}

export function defaultRun(command, args, cwd) {
  const child = spawnSync(command, args, {
    cwd,
    encoding: 'utf8',
    timeout: TOOL_TIMEOUT_MS,
    maxBuffer: MAX_OUTPUT_BYTES,
    windowsHide: true,
    shell: false,
  });
  return {
    status: child.status,
    output: `${child.stdout ?? ''}\n${child.stderr ?? ''}`,
    errorCode: child.error?.code,
  };
}

function firstLine(text) {
  return (text.split(/\r?\n/).map((line) => line.trim()).find((line) => line !== '') ?? '').slice(0, 200);
}

// A note for a run that produced no findings but did not succeed, else undefined.
function failureNote(label, result) {
  if (result.errorCode === 'ETIMEDOUT') {
    return `${label} timed out after ${TOOL_TIMEOUT_MS / 1000} seconds, skipped.`;
  }
  if (result.errorCode === 'ENOENT') {
    return `${label} could not be started, skipped.`;
  }
  if (result.errorCode) {
    return `${label} failed to run (${result.errorCode}), skipped.`;
  }
  if (/Failed to find tool/i.test(result.output)) {
    return `${label} is not in this project's rokit.toml (add it with \`rokit add\`), skipped.`;
  }
  if (/os error [23]\b/.test(result.output)) {
    return `${label} is listed in rokit.toml but not installed (run \`rokit install\`), skipped.`;
  }
  if (result.status !== 0) {
    return `${label} exited with code ${result.status} without reporting findings: ${firstLine(result.output)}`;
  }
  return undefined;
}

function matching(output, pattern) {
  return output.split(/\r?\n/).map((line) => line.trimEnd()).filter((line) => pattern.test(line));
}

// luau-lsp prints some diagnostics with the file's absolute path (and its DataModel path in
// brackets); this shortens that to the path relative to the root, like the other lines.
function withoutRoot(line, root) {
  const prefix = `${forwardSlashes(root).replace(/\/$/, '')}/`.toLowerCase();
  const normalized = line.replace(/\\/g, '/');
  return normalized.toLowerCase().startsWith(prefix) ? normalized.slice(prefix.length) : line;
}

// The file a luau-lsp diagnostic names: `src/A.luau(3,7): ...` or `src/A.luau [game/A](4,1): ...`.
function diagnosticPath(line) {
  const match = line.match(/^(.+?)(?: \[[^\]]*\])?\(\d+,\d+\): /);
  return match ? match[1] : '';
}

function normalizedPath(path) {
  return path.replace(/\\/g, '/').replace(/^\.\//, '').toLowerCase();
}

function capped(lines) {
  const shown = lines.slice(0, MAX_LINES_PER_TOOL);
  if (lines.length > MAX_LINES_PER_TOOL) {
    shown.push(`... and ${lines.length - MAX_LINES_PER_TOOL} more`);
  }
  return shown;
}

// The three checks over files (paths relative to root, from filesInRoot). `tools` maps a tool
// name to its executable path (undefined when missing); `run` spawns one, as defaultRun does.
export function runChecks({ root, files, tools, run = defaultRun }) {
  const findings = [];
  const notes = [];
  if (files.length === 0) {
    return { findings, notes };
  }
  let targets = files;
  if (files.length > MAX_FILES) {
    notes.push(`Checked the first ${MAX_FILES} of ${files.length} edited files.`);
    targets = files.slice(0, MAX_FILES);
  }
  const missingTool = (name) => `${name} was not found on PATH or in ${rokitBin()}, skipped.`;

  // luau-lsp analyze
  if (!tools['luau-lsp']) {
    notes.push(missingTool('luau-lsp'));
  } else {
    const setup = luauLspSetup(root);
    const missing = [];
    if (setup.definitions.size === 0) {
      missing.push(
        'Roblox type definitions (download ' + DEFINITIONS_URL + ' into the project root as globalTypes.d.luau, ' +
        'or list a local file under luau-lsp.types.definitionFiles in .vscode/settings.json)',
      );
    }
    if (!setup.sourcemap) {
      missing.push('sourcemap.json (run `rojo sourcemap default.project.json -o sourcemap.json`)');
    }
    if (missing.length > 0) {
      notes.push(`luau-lsp analyze skipped, since it would report Roblox globals as errors without ${missing.join(' and ')}.`);
    } else {
      const args = ['analyze'];
      for (const [name, path] of setup.definitionArgs) {
        args.push(`--definitions:${name}=${path}`);
      }
      args.push(`--sourcemap=${setup.sourcemap}`);
      if (setup.settingsPath) {
        args.push(`--settings=${setup.settingsPath}`);
      }
      const result = run(tools['luau-lsp'], [...args, ...targets], root);
      const all = matching(result.output, LUAU_LSP_FINDING).map((line) => withoutRoot(line, root));
      // luau-lsp also reports errors in modules the targets require, such as installed packages;
      // only the edited files are this turn's to fix.
      const edited = new Set(targets.map(normalizedPath));
      const lines = all.filter((line) => edited.has(normalizedPath(diagnosticPath(line))));
      if (lines.length > 0) {
        findings.push({ tool: 'luau-lsp analyze', lines: capped(lines) });
      } else if (all.length === 0) {
        const note = failureNote('luau-lsp analyze', result);
        if (note) {
          notes.push(note);
        }
      }
    }
  }

  // selene
  if (!tools.selene) {
    notes.push(missingTool('selene'));
  } else if (!isFile(join(root, 'selene.toml'))) {
    notes.push('selene skipped: the project has no selene.toml (it needs `std = "roblox"` to know Roblox globals).');
  } else {
    const result = run(tools.selene, ['--display-style=quiet', ...targets], root);
    const lines = matching(result.output, SELENE_FINDING);
    if (lines.length > 0) {
      findings.push({ tool: 'selene', lines: capped(lines) });
    } else {
      const note = failureNote('selene', result);
      if (note) {
        notes.push(note);
      }
    }
  }

  // stylua --check
  if (!tools.stylua) {
    notes.push(missingTool('stylua'));
  } else if (!STYLUA_CONFIGS.some((name) => isFile(join(root, name)))) {
    notes.push('stylua skipped: the project has no stylua.toml.');
  } else {
    const result = run(tools.stylua, ['--check', '--respect-ignores', ...targets], root);
    const unformatted = matching(result.output, STYLUA_FINDING).map((line) => line.match(STYLUA_FINDING)[1]);
    if (unformatted.length > 0) {
      findings.push({
        tool: 'stylua --check',
        lines: [`Not formatted: ${unformatted.join(', ')}. Run \`stylua ${unformatted.join(' ')}\` to format them.`],
      });
    } else {
      const note = failureNote('stylua --check', result);
      if (note) {
        notes.push(note);
      }
    }
  }

  return { findings, notes };
}
