// Parses the stream-json transcript that `claude -p --output-format stream-json --verbose`
// writes: one JSON event per line.

export function parseEvents(text) {
	const events = [];
	for (const line of text.split(/\r?\n/)) {
		const trimmed = line.trim();
		if (!trimmed.startsWith("{")) continue;
		try {
			events.push(JSON.parse(trimmed));
		} catch {
			// A trial killed mid-write can leave a partial last line.
		}
	}
	return events;
}

export function findInit(events) {
	return events.find((e) => e.type === "system" && e.subtype === "init") ?? null;
}

export function findResult(events) {
	for (let i = events.length - 1; i >= 0; i--) {
		if (events[i].type === "result") return events[i];
	}
	return null;
}

// The parts of the init event that show what the session loaded.
export function summarizeInit(init) {
	if (!init) return null;
	return {
		claude_code_version: init.claude_code_version ?? null,
		model: init.model ?? null,
		cwd: init.cwd ?? null,
		permissionMode: init.permissionMode ?? null,
		plugins: (init.plugins ?? []).map((p) => ({
			name: p.name,
			source: p.source ?? null,
			path: p.path ?? null,
		})),
		skills: init.skills ?? [],
		agents: init.agents ?? [],
		mcp_servers: (init.mcp_servers ?? []).map((m) => ({ name: m.name, source: m.source ?? null })),
		tool_count: (init.tools ?? []).length,
		tools: (init.tools ?? []).filter((t) => !t.startsWith("mcp__")),
	};
}

function toolUses(events) {
	const uses = [];
	for (const e of events) {
		if (e.type !== "assistant") continue;
		for (const block of e.message?.content ?? []) {
			if (block.type === "tool_use") {
				uses.push({ name: block.name, input: block.input ?? {}, parent: e.parent_tool_use_id ?? null });
			}
		}
	}
	return uses;
}

export function skillsLoaded(events) {
	return toolUses(events)
		.filter((u) => u.name === "Skill" && typeof u.input.skill === "string")
		.map((u) => u.input.skill);
}

// Reading a SKILL.md with the Read tool also loads a skill's instructions.
export function skillFileReads(events) {
	return toolUses(events)
		.filter((u) => u.name === "Read" && /SKILL\.md$/i.test(String(u.input.file_path ?? "")))
		.map((u) => u.input.file_path);
}

export function toolCallCounts(events) {
	const counts = {};
	for (const u of toolUses(events)) counts[u.name] = (counts[u.name] ?? 0) + 1;
	return counts;
}

// Hook runs, from the events that --include-hook-events adds.
export function hooksFired(events) {
	const byId = new Map();
	for (const e of events) {
		if (e.type !== "system" || !String(e.subtype ?? "").startsWith("hook_")) continue;
		const entry = byId.get(e.hook_id) ?? { hook_name: e.hook_name, hook_event: e.hook_event };
		if (e.subtype === "hook_response") {
			entry.exit_code = e.exit_code ?? null;
			entry.output = String(e.output ?? "").slice(0, 300);
		}
		byId.set(e.hook_id, entry);
	}
	return [...byId.values()];
}

// Totals across every model the session used (the main model plus any helper calls).
export function usageTotals(result) {
	const totals = {
		input_tokens: 0,
		output_tokens: 0,
		cache_read_input_tokens: 0,
		cache_creation_input_tokens: 0,
		total_tokens: 0,
	};
	if (!result) return totals;
	const models = result.modelUsage ?? {};
	if (Object.keys(models).length > 0) {
		for (const m of Object.values(models)) {
			totals.input_tokens += m.inputTokens ?? 0;
			totals.output_tokens += m.outputTokens ?? 0;
			totals.cache_read_input_tokens += m.cacheReadInputTokens ?? 0;
			totals.cache_creation_input_tokens += m.cacheCreationInputTokens ?? 0;
		}
	} else if (result.usage) {
		totals.input_tokens = result.usage.input_tokens ?? 0;
		totals.output_tokens = result.usage.output_tokens ?? 0;
		totals.cache_read_input_tokens = result.usage.cache_read_input_tokens ?? 0;
		totals.cache_creation_input_tokens = result.usage.cache_creation_input_tokens ?? 0;
	}
	totals.total_tokens =
		totals.input_tokens +
		totals.output_tokens +
		totals.cache_read_input_tokens +
		totals.cache_creation_input_tokens;
	return totals;
}

export function summarizeResult(result) {
	if (!result) return null;
	return {
		subtype: result.subtype ?? null,
		is_error: result.is_error ?? null,
		terminal_reason: result.terminal_reason ?? null,
		num_turns: result.num_turns ?? null,
		duration_ms: result.duration_ms ?? null,
		duration_api_ms: result.duration_api_ms ?? null,
		total_cost_usd: result.total_cost_usd ?? null,
		permission_denials: (result.permission_denials ?? []).map((d) => d.tool_name ?? d),
		models: Object.keys(result.modelUsage ?? {}),
	};
}

export function finalText(result) {
	return typeof result?.result === "string" ? result.result : "";
}
