#!/usr/bin/env bash
# Installs pesde $PESDE_VERSION from its GitHub release for a CI job.
# pesde's docs advise against toolchain managers, so it isn't in rokit.toml.
# Only pesde's own folder goes on PATH: ~/.pesde/bin also holds pesde's rojo
# link, which would run instead of the Rojo version rokit.toml pins.
set -euo pipefail

: "${PESDE_VERSION:?set PESDE_VERSION}"
dir="$RUNNER_TEMP/pesde"
mkdir -p "$dir"
gh release download "v$PESDE_VERSION" --repo pesde-pkg/pesde \
	--pattern "pesde-${PESDE_VERSION%%+*}-linux-x86_64.zip" --dir "$dir" --clobber
unzip -o -q "$dir"/pesde-*.zip -d "$dir"
chmod +x "$dir/pesde"
echo "$dir" >> "$GITHUB_PATH"
"$dir/pesde" --version
