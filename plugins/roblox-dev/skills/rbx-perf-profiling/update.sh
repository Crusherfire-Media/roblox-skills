#!/usr/bin/env bash
# Refresh this skill's upstream reference files and license from Roblox/libmp.
#
# Only the files under references/ that come from upstream are replaced. SKILL.md is maintained
# by hand and never written here: its frontmatter copies the upstream guide's description (with
# the name changed to match this folder), and its "Essentials from the upstream guide" section
# condenses that guide. When the guide or its description changes, this script says so, and
# SKILL.md should be reviewed against the new copy.
#
# The guide is saved with one change: upstream names a specific Studio MCP tool, and this plugin
# describes actions instead of tool names so it works with any Studio MCP. The sed below rewrites
# those mentions (written as execute_[l]uau so a search for tool names stays clean); review its
# output if upstream rewords them.
set -euo pipefail

cd "$(dirname "$0")"

REPO="https://raw.githubusercontent.com/Roblox/libmp/main"
BASE="$REPO/docs"
GUIDE="references/libmp-guide.md"
# Claude Code keeps a skill's SKILL.md whole after compaction only under 20,000 characters.
SKILL_MD_LIMIT=18000

mkdir -p references

fetch() {
    local url="$1" dest="$2"
    echo "fetching $url"
    curl -fsSL "$url" -o "$dest.tmp"
    # Refuse to overwrite a good copy with an error page or a truncated download.
    if [ ! -s "$dest.tmp" ]; then
        rm -f "$dest.tmp"
        echo "error: empty response for $url" >&2
        exit 1
    fi
    mv "$dest.tmp" "$dest"
}

frontmatter_description() {
    sed -n '1,10s/^description: //p' "$1" | tr -d '\r'
}

guide_before=""
if [ -f "$GUIDE" ]; then
    guide_before="$(cksum < "$GUIDE")"
fi

# Upstream calls its guide SKILL.md. It is saved under another name so it is read as a
# reference, never loaded as a second skill.
fetch "$BASE/SKILL.md" "$GUIDE"
fetch "$BASE/api-reference.md" references/api-reference.md
fetch "$BASE/ALL-SCOPES.md" references/ALL-SCOPES.md
# The MIT license must travel with the copied docs.
fetch "$REPO/LICENSE" references/LICENSE-libmp.txt

sed -i \
    -e "s/Studio MCP's \`execute_[l]uau\` \(command\|tool\)/a Studio MCP's run-Luau tool/g" \
    -e "s/via MCP's \`execute_[l]uau\`/via a Studio MCP's run-Luau tool/g" \
    -e "s/in \`execute_[l]uau\`/in code run through a Studio MCP/g" \
    -e "s/\`execute_[l]uau\`/a Studio MCP's run-Luau tool/g" \
    "$GUIDE"
if grep -nE 'mcp__|execute_[l]uau' references/*.md; then
    echo "warning: MCP tool names remain in references/; extend the sed above" >&2
fi

if [ "$(cksum < "$GUIDE")" != "$guide_before" ]; then
    echo "note: the upstream guide changed; review SKILL.md against $GUIDE (git diff -- $GUIDE)"
fi

upstream_description="$(frontmatter_description "$GUIDE")"
if [ -z "$upstream_description" ]; then
    echo "warning: no description found in $GUIDE's frontmatter; upstream format may have changed" >&2
elif [ "$upstream_description" != "$(frontmatter_description SKILL.md)" ]; then
    echo "warning: the upstream description differs from SKILL.md's; copy it into SKILL.md:" >&2
    echo "  description: $upstream_description" >&2
fi

skill_md_bytes="$(wc -c < SKILL.md | tr -d ' ')"
if [ "$skill_md_bytes" -ge "$SKILL_MD_LIMIT" ]; then
    echo "warning: SKILL.md is $skill_md_bytes bytes; keep it under $SKILL_MD_LIMIT by moving detail into references/" >&2
fi

echo "refreshed references/ (SKILL.md left as is, $skill_md_bytes bytes)"
