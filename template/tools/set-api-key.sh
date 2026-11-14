#!/usr/bin/env bash
# Stores the Open Cloud API key as this GitHub repo's ROBLOX_API_KEY secret.
# The key is read from hidden input and piped to `gh secret set`, so it never
# shows on screen, in the shell history, or on a command line.
#
# Run it yourself in a terminal at the repo root (not through Claude):
#     bash tools/set-api-key.sh
set -euo pipefail

if ! command -v gh > /dev/null; then
	echo "The GitHub CLI (gh) isn't on PATH. Install it, then open a new terminal." >&2
	exit 1
fi
if ! gh auth status > /dev/null 2>&1; then
	echo "Sign in to GitHub first with: gh auth login" >&2
	exit 1
fi

printf "Paste the Open Cloud API key (it stays hidden), then press Enter: "
IFS= read -rs key
echo
if [ -z "$key" ]; then
	echo "No key was entered, so nothing was stored." >&2
	exit 1
fi
case "$key" in
*[[:space:]]*)
	echo "The key contains spaces or line breaks. Copy it again from the Creator Dashboard." >&2
	exit 1
	;;
esac

printf "%s" "$key" | gh secret set ROBLOX_API_KEY
echo "Stored ROBLOX_API_KEY. GitHub only ever shows its name from now on."
