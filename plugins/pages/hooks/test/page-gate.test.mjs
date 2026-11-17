// Runs the page gate as Claude Code does (event JSON on stdin, answer on stdout) against a
// transcript written for the test. Run with: npm test (from the repo root)

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, describe, test } from 'node:test';

const HOOK = join(dirname(fileURLToPath(import.meta.url)), '..', 'page-gate.mjs');
const DIR = mkdtempSync(join(tmpdir(), 'page-gate-test-'));
after(() => rmSync(DIR, { recursive: true, force: true }));

const KIT_PAGE = '<!doctype html><html lang="en"><meta charset="utf-8"><title>Plan</title><script src="../kit/kit.js" defer></script>\n<h2>Goal</h2>';
const FREEFORM = '<!doctype html><html lang="en"><meta charset="utf-8"><title>Plan</title><style>body{color:red}</style><h2>Goal</h2>';

const human = (text) => ({ type: 'user', origin: { kind: 'human' }, message: { role: 'user', content: text } });
const skill = (name) => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', id: randomUUID(), name: 'Skill', input: { skill: name } }] } });
const boundary = () => ({ type: 'system', subtype: 'compact_boundary', content: 'Conversation compacted' });
const reattach = (name, truncated) => ({
  type: 'attachment',
  attachment: {
    type: 'invoked_skills',
    skills: [{ name, content: truncated ? '...\n\n[... skill content truncated for compaction; use Read on the skill path]' : 'full text' }],
  },
});

function transcript(...entries) {
  const path = join(DIR, `${randomUUID()}.jsonl`);
  writeFileSync(path, entries.map((entry) => JSON.stringify(entry)).join('\n') + '\n');
  return path;
}

function gate(transcriptPath, filePath, content, extra = {}) {
  const env = { ...process.env, TEMP: DIR, TMP: DIR, TMPDIR: DIR };
  const input = {
    hook_event_name: 'PreToolUse',
    session_id: randomUUID(),
    transcript_path: transcriptPath,
    tool_name: 'Write',
    tool_input: { file_path: filePath, content },
    ...extra,
  };
  const child = spawnSync(process.execPath, [HOOK], { input: JSON.stringify(input), encoding: 'utf8', env });
  assert.equal(child.status, 0, child.stderr);
  return child.stdout.trim() === '' ? undefined : JSON.parse(child.stdout).hookSpecificOutput;
}

const newPage = () => join(DIR, `${randomUUID()}.html`);

describe('page-gate', () => {
  test('lets a kit page through once the skill is loaded, under either name', () => {
    assert.equal(gate(transcript(human('plan it'), skill('pages:html-kit')), newPage(), KIT_PAGE), undefined);
    assert.equal(gate(transcript(human('plan it'), skill('html-kit')), newPage(), KIT_PAGE), undefined);
  });

  test('asks for the skill before a new page', () => {
    const output = gate(transcript(human('plan it')), newPage(), KIT_PAGE);
    assert.equal(output.permissionDecision, 'deny');
    assert.match(output.permissionDecisionReason, /`pages:html-kit`/);
    assert.doesNotMatch(output.permissionDecisionReason, /data-kit/);
    assert.ok(gate(transcript(human('plan it'), skill('other:html-kit')), newPage(), KIT_PAGE));
  });

  test('asks a page to load the kit, unless it opts out', () => {
    const loaded = transcript(human('plan it'), skill('pages:html-kit'));
    const output = gate(loaded, newPage(), FREEFORM);
    assert.equal(output.permissionDecision, 'deny');
    assert.match(output.permissionDecisionReason, /kit\/kit\.js.*data-kit="off"/);
    assert.equal(gate(loaded, newPage(), FREEFORM.replace('<html lang="en">', '<html lang="en" data-kit="off">')), undefined);
    assert.equal(gate(loaded, newPage(), '<!doctype html><script src="file:///G:/docs/kit/kit.js" defer></script>'), undefined);
    assert.ok(gate(loaded, newPage(), '<!doctype html><script src="kit/kitchen.js" defer></script>'));
  });

  test('leaves existing pages, other files, and other tools alone', () => {
    const fresh = transcript(human('fix it'));
    const existing = join(DIR, 'existing.html');
    writeFileSync(existing, FREEFORM);
    assert.equal(gate(fresh, existing, FREEFORM), undefined);
    assert.equal(gate(fresh, join(DIR, 'notes.md'), '# Notes'), undefined);
    assert.equal(gate(fresh, newPage(), undefined), undefined);
  });

  test('a skill loaded before compaction counts only when re-attached in full', () => {
    const before = [human('go'), skill('pages:html-kit'), boundary()];
    assert.ok(gate(transcript(...before), newPage(), KIT_PAGE));
    assert.ok(gate(transcript(...before, reattach('pages:html-kit', true)), newPage(), KIT_PAGE));
    assert.equal(gate(transcript(...before, reattach('pages:html-kit', false)), newPage(), KIT_PAGE), undefined);
  });

  test('reads a subagent transcript, and checks only the kit line when it is missing', () => {
    const main = transcript(human('delegate'));
    const agentFile = join(main.replace(/\.jsonl$/, ''), 'subagents', 'agent-a1.jsonl');
    mkdirSync(dirname(agentFile), { recursive: true });
    writeFileSync(agentFile, JSON.stringify({
      type: 'user',
      message: { role: 'user', content: [{ type: 'text', text: '<command-name>pages:html-kit</command-name>' }] },
    }) + '\n');
    assert.equal(gate(main, newPage(), KIT_PAGE, { agent_id: 'a1' }), undefined);
    assert.equal(gate(main, newPage(), KIT_PAGE, { agent_id: 'missing' }), undefined);
    assert.ok(gate(main, newPage(), FREEFORM, { agent_id: 'missing' }));
  });

  test('steps aside after three denials in a row', () => {
    const path = transcript(human('go'));
    const session = { session_id: randomUUID() };
    for (let attempt = 1; attempt <= 3; attempt += 1) {
      assert.ok(gate(path, newPage(), KIT_PAGE, session), `attempt ${attempt}`);
    }
    assert.equal(gate(path, newPage(), KIT_PAGE, session), undefined);
  });
});
