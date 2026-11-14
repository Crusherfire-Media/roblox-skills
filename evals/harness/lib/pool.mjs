// Runs async jobs with at most `limit` in flight. Results keep the input order;
// a job that throws yields { error } instead of stopping the others.
export async function runPool(jobs, limit) {
	const results = new Array(jobs.length);
	let next = 0;
	const worker = async () => {
		while (next < jobs.length) {
			const i = next++;
			try {
				results[i] = await jobs[i]();
			} catch (err) {
				results[i] = { error: err instanceof Error ? err.message : String(err) };
			}
		}
	};
	const n = Math.max(1, Math.min(limit, jobs.length));
	await Promise.all(Array.from({ length: n }, worker));
	return results;
}
