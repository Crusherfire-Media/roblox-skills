// Runs each hook as Claude Code does (event JSON on stdin, answer on stdout) against a
// transcript and a small Rojo repo written for the test. Run with: npm test

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { delimiter, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, describe, test } from 'node:test';

const HOOKS = join(dirname(fileURLToPath(import.meta.url)), '..');
const DIR = mkdtempSync(join(tmpdir(), 'roblox-dev-hooks-test-'));
after(() => rmSync(DIR, { recursive: true, force: true }));

let clock = Date.parse('2026-01-01T00:00:00Z');
const at = () => new Date((clock += 1000)).toISOString();

const human = (text) => ({ type: 'user', origin: { kind: 'human' }, timestamp: at(), message: { role: 'user', content: text } });
const use = (id, name, input) => ({ type: 'assistant', timestamp: at(), message: { role: 'assistant', content: [{ type: 'tool_use', id, name, input }] } });
const result = (id, text, isError = false) => ({
  type: 'user',
  timestamp: at(),
  message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: id, content: [{ type: 'text', text }], is_error: isError }] },
});
const call = (name, input, text = 'ok', isError = false) => {
  const id = randomUUID();
  return [use(id, name, input), result(id, text, isError)];
};
const skill = (name) => call('Skill', { skill: name }, `Launching skill: ${name}`);
const own = (...names) => names.flatMap((name) => skill(`roblox-dev:${name}`));
// The two skills every Luau edit needs.
const BASE = ['roblox-lua-style-guide', 'code-comments'];
const boundary = () => ({ type: 'system', subtype: 'compact_boundary', content: 'Conversation compacted', timestamp: at() });
const reattach = (skills) => ({
  type: 'attachment',
  timestamp: at(),
  attachment: {
    type: 'invoked_skills',
    skills: skills.map(([name, truncated]) => ({
      name,
      path: `plugin:${name}`,
      content: truncated ? '...\n\n[... skill content truncated for compaction; use Read on the skill path if you need the full text]' : 'full text',
    })),
  },
});

function writeLines(path, items) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, items.flat().map((entry) => JSON.stringify(entry)).join('\n') + '\n');
  return path;
}

function transcript(...items) {
  return writeLines(join(DIR, 'transcripts', `${randomUUID()}.jsonl`), items);
}

// An environment where no Luau tool can be found: PATH holds one empty folder and the home
// folder (where Rokit keeps its bin) is empty too.
const EMPTY_BIN = join(DIR, 'empty-bin');
const EMPTY_HOME = join(DIR, 'empty-home');
mkdirSync(EMPTY_BIN, { recursive: true });
mkdirSync(EMPTY_HOME, { recursive: true });

function hookEnv({ path = EMPTY_BIN, home = EMPTY_HOME } = {}) {
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !/^path$/i.test(key)));
  // The hooks keep state under the OS temp folder; point it at this test's folder.
  return { ...env, TEMP: DIR, TMP: DIR, TMPDIR: DIR, PATH: path, HOME: home, USERPROFILE: home };
}

function runHook(script, input, envOptions) {
  const child = spawnSync(process.execPath, [join(HOOKS, script)], { input: JSON.stringify(input), encoding: 'utf8', env: hookEnv(envOptions) });
  assert.equal(child.status, 0, child.stderr);
  return child.stdout.trim() === '' ? undefined : JSON.parse(child.stdout);
}

// A small Rojo repo on disk, shaped like a game repo: code under src/, packages pesde installs,
// a Lune tool, and the files the verify gate's checks need.
const REPO = join(DIR, 'game-repo');
const file = (relativePath, text = '') => {
  const path = join(REPO, ...relativePath.split('/'));
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text);
  return path;
};
file('default.project.json', JSON.stringify({
  name: 'game',
  tree: {
    $className: 'DataModel',
    ServerScriptService: {
      $className: 'ServerScriptService',
      $path: 'src/ServerScriptService',
      Packages: { $path: 'roblox_packages' },
    },
  },
}));
// pesde writes a Rojo project into every installed package.
file('roblox_packages/.pesde/acme+signal/0.1.0/signal/default.project.json', JSON.stringify({ name: 'signal', tree: { $path: 'src' } }));
const SHOP = file('src/ServerScriptService/Modules/Shop.luau', 'return {}\n');
const UI_INIT = file('src/ServerScriptService/Modules/Ui/init.luau', 'return {}\n');
const START = file('src/ServerScriptService/Start.server.luau', '');
const SPEC = file('src/ServerScriptService/Tests/Specs/Shop.spec.luau', '');
const STORY = file('src/ServerScriptService/Stories/Shop.story.luau', '');
const INSTALLED = file('roblox_packages/.pesde/acme+signal/0.1.0/signal/src/init.luau', 'return {}\n');
const TOOL = file('tools/install.luau', '');
const README = file('README.md', '# game\n');
const NEW_MODULE = join(REPO, 'src', 'ServerScriptService', 'Modules', 'Cart.luau');

const WORKSPACE = join(DIR, 'shared-packages');
mkdirSync(join(WORKSPACE, 'packages', 'signal', 'src'), { recursive: true });
writeFileSync(join(WORKSPACE, 'pesde.toml'), 'name = "x/shared"\nworkspace_members = ["packages/*"]\n');
const PACKAGE_FILE = join(WORKSPACE, 'packages', 'signal', 'src', 'init.luau');
const ELSEWHERE = join(DIR, 'elsewhere', 'a.luau');

const editFile = (filePath, extra = {}) => ({ file_path: filePath, old_string: 'return {}', new_string: 'return { A = 1 }', ...extra });

function gate(path, toolName, toolInput, extra = {}) {
  return runHook('skill-gate.mjs', {
    hook_event_name: 'PreToolUse',
    session_id: randomUUID(),
    transcript_path: path,
    cwd: REPO,
    tool_name: toolName,
    tool_input: toolInput,
    ...extra,
  });
}

const denied = (output) => output?.hookSpecificOutput?.permissionDecision === 'deny';
const reasonOf = (output) => output?.hookSpecificOutput?.permissionDecisionReason ?? '';

describe('skill-gate', () => {
  test('denies a Luau edit until the style guide and code-comments are loaded', () => {
    const output = gate(transcript(human('fix it')), 'Edit', editFile(SHOP));
    assert.ok(denied(output));
    assert.match(reasonOf(output), /Load `roblox-dev:roblox-lua-style-guide`, `roblox-dev:code-comments`/);
    const styleOnly = gate(transcript(human('fix it'), own('roblox-lua-style-guide')), 'Edit', editFile(SHOP));
    assert.ok(denied(styleOnly));
    assert.match(reasonOf(styleOnly), /Load `roblox-dev:code-comments`/);
    assert.equal(gate(transcript(human('fix it'), own(...BASE)), 'Edit', editFile(SHOP)), undefined);
  });

  test('counts only skills loaded under the roblox-dev: name', () => {
    const edit = editFile(SHOP);
    const privatePlugin = transcript(human('fix it'), skill('roblox:roblox-lua-style-guide'), skill('roblox:code-comments'));
    assert.match(reasonOf(gate(privatePlugin, 'Edit', edit)), /roblox-lua-style-guide.*code-comments/);
    const bare = transcript(human('fix it'), skill('roblox-lua-style-guide'), skill('code-comments'));
    assert.ok(denied(gate(bare, 'Edit', edit)));
    const typed = transcript(human('fix it'), {
      type: 'user',
      timestamp: at(),
      message: { role: 'user', content: [{ type: 'text', text: '<command-name>/roblox-dev:roblox-lua-style-guide</command-name>\n<command-name>/roblox:code-comments</command-name>' }] },
    });
    assert.match(reasonOf(gate(typed, 'Edit', edit)), /^Load `roblox-dev:code-comments` with/);
    const reattached = transcript(human('go'), boundary(), reattach([['roblox-dev:roblox-lua-style-guide', false], ['roblox-dev:code-comments', false]]));
    assert.equal(gate(reattached, 'Edit', edit), undefined);
    const reattachedPrivate = transcript(human('go'), boundary(), reattach([['roblox:roblox-lua-style-guide', false], ['roblox:code-comments', false]]));
    assert.ok(denied(gate(reattachedPrivate, 'Edit', edit)));
  });

  test('a skill loaded before compaction counts only when re-attached in full', () => {
    const before = [human('go'), own(...BASE), boundary()];
    const edit = editFile(SHOP);
    assert.ok(denied(gate(transcript(...before), 'Edit', edit)));
    assert.ok(denied(gate(transcript(...before, reattach([['roblox-dev:roblox-lua-style-guide', true], ['roblox-dev:code-comments', false]])), 'Edit', edit)));
    assert.equal(gate(transcript(...before, reattach([['roblox-dev:roblox-lua-style-guide', false], ['roblox-dev:code-comments', false]])), 'Edit', edit), undefined);
  });

  test('reads a subagent transcript, where frontmatter preloads show as <command-name>', () => {
    const main = transcript(human('delegate'));
    const agentId = 'a1b2c3';
    writeLines(join(main.replace(/\.jsonl$/, ''), 'subagents', `agent-${agentId}.jsonl`), [{
      type: 'user',
      message: { role: 'user', content: [{ type: 'text', text: BASE.map((name) => `<command-name>roblox-dev:${name}</command-name>`).join('\n') }] },
    }]);
    assert.equal(gate(main, 'Edit', editFile(SHOP), { agent_id: agentId, agent_type: 'general-purpose' }), undefined);
    assert.ok(denied(gate(main, 'Edit', editFile(SHOP))));
  });

  test('finds workflow agent transcripts, and lets an agent through when its own is missing', () => {
    const main = transcript(human('run the workflow'));
    const runDir = join(main.replace(/\.jsonl$/, ''), 'subagents', 'workflows', 'wf_123');
    writeLines(join(runDir, 'agent-w1.jsonl'), own('vide'));
    assert.match(reasonOf(gate(main, 'Edit', editFile(SHOP), { agent_id: 'w1' })), /roblox-lua-style-guide/);
    writeLines(join(runDir, 'agent-w2.jsonl'), own(...BASE));
    assert.equal(gate(main, 'Edit', editFile(SHOP), { agent_id: 'w2' }), undefined);
    assert.equal(gate(main, 'Edit', editFile(SHOP), { agent_id: 'missing' }), undefined);
  });

  test('requires the Vide skills for a file an earlier Read showed is Vide UI', () => {
    const path = transcript(
      human('tweak the shop'),
      own(...BASE),
      call('Read', { file_path: SHOP }, 'local vide = require(ReplicatedStorage.Packages.vide)\nreturn vide.create "Frame" {}'),
    );
    const output = gate(path, 'Edit', editFile(SHOP));
    assert.ok(denied(output));
    assert.match(reasonOf(output), /`roblox-dev:vide`.*`roblox-dev:vide-ui-labs`/);
    assert.doesNotMatch(reasonOf(output), /roblox-lua-style-guide/);
  });

  test('recognizes Vide, Charm, stories, and specs from the edit itself', () => {
    const path = transcript(human('go'), own(...BASE));
    assert.match(reasonOf(gate(path, 'Edit', editFile(SHOP, { new_string: 'return create "Frame" {' }))), /`roblox-dev:vide`/);
    assert.match(reasonOf(gate(path, 'Edit', editFile(SHOP, { new_string: 'local vide = require(Packages.vide)\nlocal charm = require(Packages.charm)' }))), /vide-charm/);
    assert.match(reasonOf(gate(path, 'Edit', editFile(SPEC))), /roblox-testing/);
    assert.match(reasonOf(gate(path, 'Edit', editFile(STORY))), /vide-ui-labs/);
  });

  test('asks for vide-ui-labs only for code that builds UI, and never for specs', () => {
    const stateOnly = transcript(
      human('go'),
      own(...BASE),
      call('Read', { file_path: SHOP }, 'local Vide = require(ReplicatedStorage.Packages.vide)\nVide.effect(function() end)'),
    );
    const reason = reasonOf(gate(stateOnly, 'Edit', editFile(SHOP)));
    assert.match(reason, /`roblox-dev:vide`/);
    assert.doesNotMatch(reason, /vide-ui-labs/);
    const spec = gate(transcript(human('go'), own(...BASE, 'roblox-testing')), 'Edit', editFile(SPEC, { new_string: 'local ui = create "Frame" {}' }));
    assert.doesNotMatch(reasonOf(spec), /vide-ui-labs/);
  });

  test('asks for game-architecture for a new script or a new require in game code, not in Lune tools', () => {
    const styled = transcript(human('add it'), own(...BASE));
    assert.match(reasonOf(gate(styled, 'Write', { file_path: NEW_MODULE, content: 'return {}\n' })), /game-architecture.*creates a script/);
    assert.match(reasonOf(gate(styled, 'Edit', editFile(SHOP, { new_string: 'local A = require("./A")\nreturn {}' }))), /game-architecture/);
    const carried = 'local Other = require("./Other")\nreturn {}';
    assert.equal(gate(styled, 'Edit', editFile(SHOP, { old_string: carried, new_string: `${carried}\nlocal b = 2` })), undefined);
    assert.equal(gate(styled, 'Write', { file_path: TOOL, content: 'local fs = require("@lune/fs")\n' }), undefined);
    assert.equal(gate(styled, 'Write', { file_path: SHOP, content: 'return {}\n' }), undefined);
  });

  test('gates MultiEdit and pesde workspace files the same way', () => {
    const fresh = transcript(human('fix it'));
    const multi = { file_path: SHOP, edits: [{ old_string: 'return {}', new_string: 'return create "Frame" {}' }] };
    assert.match(reasonOf(gate(fresh, 'MultiEdit', multi)), /code-comments.*vide/);
    assert.match(reasonOf(gate(fresh, 'Edit', editFile(PACKAGE_FILE))), /roblox-lua-style-guide/);
  });

  test('denies editing installed packages, whatever skills are loaded', () => {
    const loaded = transcript(human('fix it'), own(...BASE));
    assert.match(reasonOf(gate(loaded, 'Edit', editFile(INSTALLED))), /pesde install.*rojo-workflow/);
    assert.match(reasonOf(gate(loaded, 'Write', { file_path: INSTALLED, content: '' })), /Installed packages/);
  });

  test('lets non-Luau files, Luau outside a Rojo repo, other tools, and unreadable transcripts through', () => {
    const fresh = transcript(human('fix it'));
    assert.equal(gate(fresh, 'Edit', editFile(README)), undefined);
    assert.equal(gate(fresh, 'Edit', editFile(ELSEWHERE)), undefined);
    assert.equal(gate(fresh, 'Read', { file_path: SHOP }), undefined);
    assert.equal(gate(fresh, 'NotebookEdit', { notebook_path: SHOP, new_source: '' }), undefined);
    assert.equal(gate(join(DIR, 'missing.jsonl'), 'Edit', editFile(SHOP)), undefined);
  });

  test('steps aside after three denials in a row for the same agent', () => {
    const path = transcript(human('go'));
    const session = { session_id: randomUUID() };
    for (let attempt = 1; attempt <= 3; attempt += 1) {
      assert.ok(denied(gate(path, 'Edit', editFile(SHOP), session)), `attempt ${attempt}`);
    }
    assert.equal(gate(path, 'Edit', editFile(SHOP), session), undefined);
    assert.ok(denied(gate(path, 'Edit', editFile(SHOP), session)), 'the streak starts over');
  });
});

describe('after-edit', () => {
  const EM_DASH = String.fromCodePoint(0x2014);
  const afterEdit = (toolName, toolInput, response) => runHook('after-edit.mjs', {
    hook_event_name: 'PostToolUse', session_id: randomUUID(), tool_name: toolName, tool_input: toolInput, tool_response: response,
  });
  const contextOf = (output) => output?.hookSpecificOutput?.additionalContext ?? '';

  test('reports convention problems in the lines an edit adds', () => {
    const carried = 'if old then return end';
    const output = afterEdit('Edit', editFile(SHOP, {
      old_string: carried,
      new_string: [
        carried,
        'if not player then return end',
        `-- Waits for the data ${EM_DASH} then fires`,
        '--[[ Rebuilds the shop ]]',
        'local function setColour() end',
        '-- SERVICES --',
      ].join('\n'),
    }));
    assert.equal(output.hookSpecificOutput.hookEventName, 'PostToolUse');
    const context = contextOf(output);
    assert.match(context, /one-line guard clause.*not player/);
    assert.doesNotMatch(context, /if old then/);
    assert.match(context, /em dash/);
    assert.match(context, /block comment text/);
    assert.match(context, /British spelling "Colour"/);
    assert.doesNotMatch(context, /SERVICES/);
  });

  test('leaves strings, member names, and identifiers that only contain a British word alone', () => {
    const lines = [
      'x:align("Left") -- Shop',
      'local s = "a -- b" -- note',
      'local remaining = C.AccentRebirth + percentRemaining',
      'if state == Enum.PlaybackState.Cancelled or status == "CANCELLED" then',
      'HudDock.modalCentre(frame)',
      '-- Positions the `modalCentre` anchor',
    ];
    assert.equal(afterEdit('Edit', editFile(SHOP, { old_string: '', new_string: lines.join('\n') })), undefined);
    const ownWords = afterEdit('Edit', editFile(SHOP, { old_string: '', new_string: 'local barColour = Color3.new()\n-- Colour of the bar' }));
    assert.equal(contextOf(ownWords).match(/British spelling/g).length, 2);
  });

  test('says nothing about a clean edit, a non-Luau file, or Luau outside a Rojo repo', () => {
    const clean = '--[[\n    Rebuilds the shop.\n]]\nlocal function rebuild()\n    if not ready then\n        return\n    end\nend';
    assert.equal(afterEdit('Edit', editFile(SHOP, { old_string: '', new_string: clean })), undefined);
    assert.equal(afterEdit('Edit', editFile(README, { new_string: `if x then return end -- a ${EM_DASH} b` })), undefined);
    assert.equal(afterEdit('Edit', editFile(ELSEWHERE, { new_string: 'if x then return end' })), undefined);
  });

  test('a Write reports only lines that were not in the original file', () => {
    const rewrite = afterEdit('Write', { file_path: SHOP, content: 'if old then return end\nif new then return end' }, { originalFile: 'if old then return end' });
    assert.match(contextOf(rewrite), /if new/);
    assert.doesNotMatch(contextOf(rewrite), /if old/);
  });
});

describe('skill-hints', () => {
  const hint = (input) => runHook('skill-hints.mjs', input)?.hookSpecificOutput?.additionalContext;

  test('after compaction, lists skills it cut short or dropped', () => {
    const path = transcript(
      human('go'),
      own('roblox-lua-style-guide', 'vide', 'game-architecture'),
      boundary(),
      reattach([['roblox-dev:roblox-lua-style-guide', true], ['roblox-dev:vide', false]]),
    );
    const context = hint({ hook_event_name: 'SessionStart', source: 'compact', transcript_path: path });
    assert.match(context, /`roblox-dev:roblox-lua-style-guide`/);
    assert.match(context, /`roblox-dev:game-architecture`/);
    assert.doesNotMatch(context, /`roblox-dev:vide`/);
    assert.equal(hint({ hook_event_name: 'SessionStart', source: 'startup', transcript_path: path }), undefined);
  });

  test('points prompt wording at skills not loaded yet', () => {
    const fresh = transcript(human('x'));
    const context = hint({ hook_event_name: 'UserPromptSubmit', prompt: 'The shop UI has lag spikes', transcript_path: fresh });
    assert.match(context, /`roblox-dev:vide`/);
    assert.match(context, /`roblox-dev:game-ui-design`/);
    assert.match(context, /roblox-performance/);
    const loaded = transcript(human('x'), own('vide', 'vide-ui-labs', 'game-ui-design'));
    const afterLoad = hint({ hook_event_name: 'UserPromptSubmit', prompt: 'The shop UI has lag spikes', transcript_path: loaded });
    assert.doesNotMatch(afterLoad, /`roblox-dev:vide`/);
    assert.doesNotMatch(afterLoad, /game-ui-design/);
    assert.equal(hint({ hook_event_name: 'UserPromptSubmit', prompt: 'Rename the variable', transcript_path: fresh }), undefined);
    assert.match(hint({ hook_event_name: 'UserPromptSubmit', prompt: 'Rebuild the shop from the Figma file', transcript_path: fresh }), /`roblox-dev:figma-to-roblox`/);
    assert.match(hint({ hook_event_name: 'UserPromptSubmit', prompt: 'Restart rojo serve', transcript_path: fresh }), /`roblox-dev:rojo-workflow`/);
    const report = 'Another Claude session sent a message:\n<agent-message from="a1">The shop UI has lag spikes</agent-message>';
    assert.equal(hint({ hook_event_name: 'UserPromptSubmit', prompt: report, transcript_path: fresh }), undefined);
  });

  test('a skill loaded from another plugin does not silence the hint', () => {
    const privateLoad = transcript(human('x'), skill('roblox:roblox-performance'));
    assert.match(hint({ hook_event_name: 'UserPromptSubmit', prompt: 'Fix the lag', transcript_path: privateLoad }), /`roblox-dev:roblox-performance`/);
  });

  test('flags Vide code and specs when a Read shows them', () => {
    const vide = hint({
      hook_event_name: 'PostToolUse',
      transcript_path: transcript(human('x')),
      tool_name: 'Read',
      tool_input: { file_path: SHOP },
      tool_response: { type: 'text', file: { filePath: SHOP, content: 'local vide = require(ReplicatedStorage.Packages.Vide)\nreturn vide.create "Frame" {}' } },
    });
    assert.match(vide, /Vide code.*`roblox-dev:vide`, `roblox-dev:vide-ui-labs`/);
    const spec = hint({
      hook_event_name: 'PostToolUse',
      transcript_path: transcript(human('x')),
      tool_name: 'Read',
      tool_input: { file_path: SPEC },
      tool_response: { type: 'text', file: { filePath: SPEC, content: 'describe("Shop", function() end)' } },
    });
    assert.match(spec, /a spec.*roblox-testing/);
    const plain = hint({
      hook_event_name: 'PostToolUse',
      transcript_path: transcript(human('x')),
      tool_name: 'Read',
      tool_input: { file_path: README },
      tool_response: { type: 'text', file: { filePath: README, content: 'local vide = require(Packages.vide)' } },
    });
    assert.equal(plain, undefined);
  });
});

describe('rojo mapping', () => {
  test('maps files to the scripts they become', async () => {
    const rojo = await import('../lib/rojo.mjs');
    const project = rojo.findRojoProject(SHOP);
    assert.equal(project.root, REPO);
    assert.equal(rojo.instancePathOfFile(project, SHOP), 'ServerScriptService.Modules.Shop');
    assert.equal(rojo.instancePathOfFile(project, UI_INIT), 'ServerScriptService.Modules.Ui');
    assert.equal(rojo.instancePathOfFile(project, START), 'ServerScriptService.Start');
    assert.equal(rojo.instancePathOfFile(project, SPEC), 'ServerScriptService.Tests.Specs.Shop.spec');
    assert.equal(rojo.instancePathOfFile(project, TOOL), undefined);
    assert.equal(rojo.findRojoProject(WORKSPACE), undefined);
    assert.equal(rojo.findRojoProject(INSTALLED).root, REPO);
    assert.ok(rojo.isInInstalledPackages(INSTALLED));
    assert.ok(rojo.inPesdeWorkspace(PACKAGE_FILE));
    assert.equal(rojo.inPesdeWorkspace(ELSEWHERE), false);
  });

  test('a multi-place repo maps shared files from the root and from a place', async () => {
    const rojo = await import('../lib/rojo.mjs');
    const multi = join(DIR, 'multi-place-repo');
    const place = (name) => {
      mkdirSync(join(multi, 'places', name, 'src', 'ServerScriptService'), { recursive: true });
      writeFileSync(join(multi, 'places', name, 'default.project.json'), JSON.stringify({
        name,
        tree: {
          $className: 'DataModel',
          ReplicatedStorage: { $className: 'ReplicatedStorage', Shared: { $path: '../../shared' } },
          ServerScriptService: { $className: 'ServerScriptService', $path: 'src/ServerScriptService' },
        },
      }));
    };
    place('alpha');
    place('beta');
    mkdirSync(join(multi, 'shared', 'Utilities'), { recursive: true });
    const shared = join(multi, 'shared', 'Utilities', 'Format.luau');
    writeFileSync(shared, 'return {}\n');
    const alphaScript = join(multi, 'places', 'alpha', 'src', 'ServerScriptService', 'AlphaScript.luau');
    writeFileSync(alphaScript, 'return {}\n');
    const root = rojo.findRojoProject(shared);
    assert.equal(root.root, multi);
    assert.equal(rojo.instancePathOfFile(root, shared), 'ReplicatedStorage.Shared.Utilities.Format');
    const alpha = rojo.findRojoProject(alphaScript);
    assert.equal(alpha.root, join(multi, 'places', 'alpha'));
    assert.equal(rojo.instancePathOfFile(alpha, alphaScript), 'ServerScriptService.AlphaScript');
    assert.equal(rojo.instancePathOfFile(alpha, shared), 'ReplicatedStorage.Shared.Utilities.Format');
  });
});

describe('verify-gate checks (lib)', async () => {
  const verify = await import('../lib/verify.mjs');
  const fakeExe = (dir, name) => {
    const path = join(dir, process.platform === 'win32' ? `${name}.exe` : name);
    mkdirSync(dir, { recursive: true });
    writeFileSync(path, '#!/bin/sh\nexit 0\n');
    chmodSync(path, 0o755);
    return path;
  };

  test('finds a tool on PATH or in Rokit bin, and ignores relative PATH entries', () => {
    const onPath = join(DIR, 'tools-on-path');
    const home = join(DIR, 'tools-home');
    const pathTool = fakeExe(onPath, 'selene');
    const rokitTool = fakeExe(join(home, '.rokit', 'bin'), 'stylua');
    const env = { PATH: ['relative-bin', onPath].join(delimiter) };
    assert.equal(verify.findTool('selene', { env, home }), pathTool);
    assert.equal(verify.findTool('stylua', { env, home }), rokitTool);
    assert.equal(verify.findTool('luau-lsp', { env, home }), undefined);
    const planted = join(REPO, 'relative-bin');
    fakeExe(planted, 'luau-lsp');
    assert.equal(verify.findTool('luau-lsp', { env, home }), undefined);
    rmSync(planted, { recursive: true, force: true });
  });

  test('passes only existing Luau files inside the project root to the tools', () => {
    const files = verify.filesInRoot(REPO, [SHOP, SHOP, README, INSTALLED, ELSEWHERE, join(REPO, 'src', 'Gone.luau'), join(REPO, '..', 'outside.luau')]);
    assert.deepEqual(files, ['src/ServerScriptService/Modules/Shop.luau']);
    const dash = file('-flag.luau', '');
    assert.deepEqual(verify.filesInRoot(REPO, [dash]), ['./-flag.luau']);
    rmSync(dash);
  });

  test('finds definitions in the project root or in settings, and leaves remote ones alone', () => {
    const project = join(DIR, 'definitions-project');
    mkdirSync(join(project, '.vscode'), { recursive: true });
    assert.equal(verify.luauLspSetup(project).definitions.size, 0);
    writeFileSync(join(project, 'globalTypes.None.d.luau'), '');
    writeFileSync(join(project, 'sourcemap.json'), '{}');
    let setup = verify.luauLspSetup(project);
    assert.deepEqual([...setup.definitionArgs], [['@roblox', 'globalTypes.None.d.luau']]);
    assert.equal(setup.sourcemap, 'sourcemap.json');
    writeFileSync(join(project, '.vscode', 'settings.json'), '{\n  // comment\n  "luau-lsp.types.definitionFiles": { "@roblox": "types/roblox.d.luau" },\n}\n');
    mkdirSync(join(project, 'types'), { recursive: true });
    writeFileSync(join(project, 'types', 'roblox.d.luau'), '');
    setup = verify.luauLspSetup(project);
    assert.deepEqual([...setup.definitionArgs], [['@roblox', 'types/roblox.d.luau']]);
    assert.equal(setup.settingsPath, undefined);
    writeFileSync(join(project, '.vscode', 'settings.json'), JSON.stringify({ 'luau-lsp.types.definitionFiles': { '@roblox': 'types/roblox.d.luau' } }));
    setup = verify.luauLspSetup(project);
    assert.equal(setup.settingsPath, '.vscode/settings.json');
    assert.equal(setup.definitionArgs.size, 0);
    writeFileSync(join(project, '.vscode', 'settings.json'), JSON.stringify({ 'luau-lsp.types.definitionFiles': { '@roblox': 'https://example.com/x.d.luau', '@other': '../outside.d.luau' } }));
    setup = verify.luauLspSetup(project);
    assert.equal(setup.settingsPath, undefined);
    assert.deepEqual([...setup.definitionArgs], [['@roblox', 'globalTypes.None.d.luau']]);
  });

  // A project with everything the checks need, and a fake runner that records each call.
  const ready = join(DIR, 'ready-project');
  for (const [name, text] of [['selene.toml', 'std = "roblox"\n'], ['stylua.toml', ''], ['sourcemap.json', '{}'], ['globalTypes.d.luau', ''], ['src/A.luau', '']]) {
    mkdirSync(dirname(join(ready, name)), { recursive: true });
    writeFileSync(join(ready, name), text);
  }
  const TOOLS = { 'luau-lsp': '/bin/luau-lsp', selene: '/bin/selene', stylua: '/bin/stylua' };
  const recorder = (outputs) => {
    const calls = [];
    const run = (command, args, cwd) => {
      calls.push({ command, args, cwd });
      return outputs[command] ?? { status: 0, output: '' };
    };
    return { calls, run };
  };

  test('runs each tool in the project root with the files as separate arguments', () => {
    const { calls, run } = recorder({});
    const outcome = verify.runChecks({ root: ready, files: ['src/A.luau'], tools: TOOLS, run });
    assert.deepEqual(outcome, { findings: [], notes: [] });
    assert.deepEqual(calls.map((entry) => entry.cwd), [ready, ready, ready]);
    assert.deepEqual(calls[0].args, ['analyze', '--definitions:@roblox=globalTypes.d.luau', '--sourcemap=sourcemap.json', 'src/A.luau']);
    assert.deepEqual(calls[1].args, ['--display-style=quiet', 'src/A.luau']);
    assert.deepEqual(calls[2].args, ['--check', '--respect-ignores', 'src/A.luau']);
  });

  test('turns tool output into findings', () => {
    const { run } = recorder({
      '/bin/luau-lsp': {
        status: 1,
        output: `[WARN] noise\nsrc/A.luau(3,7): TypeError: Unknown global 'x'\n${join(ready, 'src', 'A.luau')} [game/A](4,1): TypeError: Key 'Nme' not found\n`,
      },
      '/bin/selene': { status: 1, output: 'src/A.luau:1:7: warning[unused_variable]: a is assigned a value, but never used\nResults:\n0 errors\n1 warnings\n' },
      '/bin/stylua': { status: 1, output: 'Diff in src/A.luau:\n1 |-x\n1 |+ x\n' },
    });
    const { findings, notes } = verify.runChecks({ root: ready, files: ['src/A.luau'], tools: TOOLS, run });
    assert.deepEqual(notes, []);
    assert.deepEqual(findings.map((finding) => finding.tool), ['luau-lsp analyze', 'selene', 'stylua --check']);
    assert.deepEqual(findings[0].lines, ["src/A.luau(3,7): TypeError: Unknown global 'x'", "src/A.luau [game/A](4,1): TypeError: Key 'Nme' not found"]);
    assert.match(findings[2].lines[0], /Not formatted: src\/A\.luau/);
  });

  test('skips a missing tool or setup with a note instead of reporting findings', () => {
    const bare = join(DIR, 'bare-project');
    mkdirSync(bare, { recursive: true });
    const { calls, run } = recorder({});
    const { findings, notes } = verify.runChecks({ root: bare, files: ['a.luau'], tools: { 'luau-lsp': '/bin/luau-lsp', selene: '/bin/selene' }, run });
    assert.deepEqual(findings, []);
    assert.equal(calls.length, 0);
    assert.match(notes.join('\n'), /luau-lsp analyze skipped.*Roblox type definitions.*sourcemap\.json/);
    assert.match(notes.join('\n'), /selene skipped: the project has no selene\.toml/);
    assert.match(notes.join('\n'), /stylua was not found on PATH or in .*\.rokit/);
  });

  test('a tool that fails without findings is a note, not a finding', () => {
    const { run } = recorder({
      '/bin/luau-lsp': { status: null, output: '', errorCode: 'ETIMEDOUT' },
      '/bin/selene': { status: 1, output: "ERROR Failed to find tool 'selene' in any project manifest file." },
      '/bin/stylua': { status: 1, output: 'ERROR The system cannot find the path specified. (os error 3)' },
    });
    const { findings, notes } = verify.runChecks({ root: ready, files: ['src/A.luau'], tools: TOOLS, run });
    assert.deepEqual(findings, []);
    assert.match(notes[0], /luau-lsp analyze timed out/);
    assert.match(notes[1], /selene is not in this project's rokit\.toml/);
    assert.match(notes[2], /run `rokit install`/);
  });
});

describe('verify-gate (hook)', () => {
  const stop = (path, extra = {}, envOptions) => runHook('verify-gate.mjs', {
    hook_event_name: 'Stop', session_id: randomUUID(), transcript_path: path, cwd: REPO, stop_hook_active: false, ...extra,
  }, envOptions);
  const luauEdit = () => call('Edit', editFile(SHOP), 'The file has been updated successfully.');

  test('with no tools installed, lets the stop through and tells the user what it skipped', () => {
    const output = stop(transcript(human('go'), luauEdit()));
    assert.equal(output.decision, undefined);
    assert.match(output.systemMessage, /luau-lsp was not found/);
    assert.match(output.systemMessage, /selene was not found/);
    assert.match(output.systemMessage, /stylua was not found/);
  });

  test('stays quiet without Luau edits in this turn', () => {
    assert.equal(stop(transcript(human('go'), call('Edit', editFile(README), 'ok'))), undefined);
    assert.equal(stop(transcript(human('go'), call('Edit', editFile(SHOP), 'failed', true))), undefined);
    assert.equal(stop(transcript(human('go'), luauEdit(), human('thanks'))), undefined);
    assert.equal(stop(transcript(human('go'), call('Edit', editFile(ELSEWHERE), 'ok'))), undefined);
    assert.equal(stop(transcript(human('go'), call('Edit', editFile(INSTALLED), 'ok'))), undefined);
  });

  test('lets a second stop through', () => {
    const feedback = { type: 'user', isMeta: true, timestamp: at(), message: { role: 'user', content: 'Stop hook feedback:\nLuau checks before this turn ends:\n\n...' } };
    assert.equal(stop(transcript(human('go'), luauEdit()), { stop_hook_active: true }), undefined);
    assert.equal(stop(transcript(human('go'), luauEdit(), feedback)), undefined);
    assert.equal(stop(join(DIR, 'missing.jsonl')), undefined);
  });

  // Fake tools are shell scripts, which Windows can't run without a shell; CI runs these on Linux.
  test('blocks on findings from the tools, counting subagent edits, and passes the second stop', { skip: process.platform === 'win32' && 'fake tools are shell scripts' }, () => {
    const bin = join(DIR, 'fake-bin');
    mkdirSync(bin, { recursive: true });
    const tool = (name, body) => {
      const path = join(bin, name);
      writeFileSync(path, `#!/bin/sh\nprintf '%s\\n' "$PWD" "$@" > "$0.args"\n${body}\n`);
      chmodSync(path, 0o755);
    };
    tool('luau-lsp', 'echo "src/ServerScriptService/Modules/Shop.luau(1,8): TypeError: Unknown global \'x\'"; exit 1');
    tool('selene', 'echo "src/ServerScriptService/Start.server.luau:1:7: warning[unused_variable]: a is never used"; exit 1');
    tool('stylua', 'exit 0');
    file('selene.toml', 'std = "roblox"\n');
    file('stylua.toml', '');
    file('sourcemap.json', '{}');
    file('globalTypes.d.luau', '');
    try {
      const main = transcript(human('go'), luauEdit());
      writeLines(join(main.replace(/\.jsonl$/, ''), 'subagents', 'agent-s1.jsonl'), [call('Write', { file_path: START, content: 'local a = 1' }, 'ok')]);
      const output = stop(main, {}, { path: bin });
      assert.equal(output.decision, 'block');
      assert.match(output.reason, /^Luau checks before this turn ends:/);
      assert.match(output.reason, /luau-lsp analyze:\nsrc\/ServerScriptService\/Modules\/Shop\.luau\(1,8\)/);
      assert.match(output.reason, /selene:\n.*unused_variable/);
      assert.doesNotMatch(output.reason, /stylua/);
      const args = readFileSync(join(bin, 'luau-lsp.args'), 'utf8').split('\n');
      assert.equal(args[0], REPO);
      assert.deepEqual(args.slice(1, -1), [
        'analyze',
        '--definitions:@roblox=globalTypes.d.luau',
        '--sourcemap=sourcemap.json',
        'src/ServerScriptService/Modules/Shop.luau',
        'src/ServerScriptService/Start.server.luau',
      ]);
      assert.equal(stop(main, { stop_hook_active: true }, { path: bin }), undefined);
    } finally {
      for (const name of ['selene.toml', 'stylua.toml', 'sourcemap.json', 'globalTypes.d.luau']) {
        rmSync(join(REPO, name), { force: true });
      }
    }
  });
});
