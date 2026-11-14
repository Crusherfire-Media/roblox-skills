// Fixture hook: adds a marker to the context so the isolation proof can see the
// plugin's hooks run.
const event = process.argv[2] ?? "UserPromptSubmit";
process.stdout.write(
	JSON.stringify({ hookSpecificOutput: { hookEventName: event, additionalContext: `EVAL_DUMMY_HOOK_FIRED:${event}` } }),
);
