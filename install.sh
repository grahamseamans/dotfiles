#!/bin/bash
# Dotfiles installer — declarative, always-latest.
#
# Symlinks Claude config, clones/pulls each MCP repo, builds it, registers
# it with Claude Code. No submodules, no pins — `git pull` on every run.
#
# If one MCP fails (build error, upstream bad, missing runtime) the others
# still install. GC step at the end: any MCP we manage that didn't install
# this run gets unregistered, so the env always matches what's declared
# here.
#
# Required env var:  XAI_API_KEY  (coworker MCP)
# Optional env vars: MOUSER_API_KEY, DIGIKEY_CLIENT_ID, DIGIKEY_CLIENT_SECRET,
#                    DIGIKEY_USE_SANDBOX (default "false")

set -uo pipefail  # no -e: we handle errors per-MCP and keep going

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
MCP_DIR="$DOTFILES/mcp-servers"
PLATFORM=$(uname -s)
mkdir -p "$MCP_DIR"

echo "→ Dotfiles root: $DOTFILES"
echo "→ Platform: $PLATFORM"

: "${XAI_API_KEY:?Error: XAI_API_KEY required. Set in shell env or devcontainer.json.}"

# MCPs this script manages. Each one installs below; the GC step at the
# bottom removes any that aren't in this list from Claude's user-scope
# config. Add/remove entries here to change the declared set.
MANAGED_MCPS=(coworker mouser digikey)
INSTALLED_THIS_RUN=()

# ─────────── Symlink Claude config ───────────
mkdir -p ~/.claude ~/.claude/hooks
ln -sfn "$DOTFILES/claude/CLAUDE.md"     ~/.claude/CLAUDE.md
ln -sfn "$DOTFILES/claude/settings.json" ~/.claude/settings.json
ln -sfn "$DOTFILES/claude/skills"        ~/.claude/skills
ln -sfn "$DOTFILES/claude/hooks/load-skills.sh" ~/.claude/hooks/load-skills.sh
ln -sfn "$DOTFILES/claude/hooks/timestamp.sh"   ~/.claude/hooks/timestamp.sh
if [ "$PLATFORM" = "Darwin" ]; then
    ln -sfn "$DOTFILES/claude/hooks/permission-alert.sh" ~/.claude/hooks/permission-alert.sh
elif [ ! -f ~/.claude/hooks/permission-alert.sh ] || ! grep -q "Stubbed on Linux" ~/.claude/hooks/permission-alert.sh; then
    cat > ~/.claude/hooks/permission-alert.sh <<'EOF'
#!/bin/bash
# Stubbed on Linux (macOS/osascript-only). Dotfiles install.sh generates this.
exit 0
EOF
    chmod +x ~/.claude/hooks/permission-alert.sh
fi
echo "✓ claude config symlinked"

# Clone if missing, else fetch + hard reset to origin/main.
# --depth=1 for first clone; --ff-only would block non-ff. We use reset
# to get unambiguously-latest regardless of local state.
sync_repo() {
    local name=$1 url=$2
    local dir="$MCP_DIR/$name"
    if [ ! -d "$dir/.git" ]; then
        rm -rf "$dir"
        git clone --depth=1 "$url" "$dir"
    else
        (cd "$dir" && git fetch --quiet origin main && git reset --hard --quiet origin/main)
    fi
}

# ─────────── coworker MCP (Grok) ───────────
install_coworker() {
    command -v node >/dev/null 2>&1 || { echo "⚠  coworker: node not installed; skipping"; return 1; }
    sync_repo coworker_mcp https://github.com/grahamseamans/coworker_mcp.git || { echo "⚠  coworker: clone/pull failed"; return 1; }
    local dir="$MCP_DIR/coworker_mcp"
    (cd "$dir" && npm install) || { echo "⚠  coworker: npm install failed"; return 1; }
    (cd "$dir" && npm run build) || { echo "⚠  coworker: npm run build failed"; return 1; }
    claude mcp remove coworker --scope user 2>/dev/null || true
    claude mcp add coworker --scope user --env XAI_API_KEY="$XAI_API_KEY" \
        -- node "$dir/dist/index.js" >/dev/null \
        || { echo "⚠  coworker: claude mcp add failed"; return 1; }
    echo "✓ coworker"
    INSTALLED_THIS_RUN+=("coworker")
}
install_coworker

# ─────────── mouser MCP ───────────
install_mouser() {
    [ -n "${MOUSER_API_KEY:-}" ] || { echo "⚠  mouser: MOUSER_API_KEY not set; skipping"; return 1; }
    command -v node >/dev/null 2>&1 || { echo "⚠  mouser: node not installed; skipping"; return 1; }
    sync_repo mouser_mcp https://github.com/grahamseamans/ai_mouser_bom_tool.git || { echo "⚠  mouser: clone/pull failed"; return 1; }
    local dir="$MCP_DIR/mouser_mcp"
    (cd "$dir" && npm install) || { echo "⚠  mouser: npm install failed"; return 1; }
    (cd "$dir" && npm run build) || { echo "⚠  mouser: npm run build failed"; return 1; }
    claude mcp remove mouser --scope user 2>/dev/null || true
    claude mcp add mouser --scope user --env MOUSER_API_KEY="$MOUSER_API_KEY" \
        -- node "$dir/dist/index.js" >/dev/null \
        || { echo "⚠  mouser: claude mcp add failed"; return 1; }
    echo "✓ mouser"
    INSTALLED_THIS_RUN+=("mouser")
}
install_mouser

# ─────────── digikey MCP ───────────
install_digikey() {
    [ -n "${DIGIKEY_CLIENT_ID:-}" ] && [ -n "${DIGIKEY_CLIENT_SECRET:-}" ] \
        || { echo "⚠  digikey: DIGIKEY_CLIENT_ID/SECRET not set; skipping"; return 1; }
    command -v uv >/dev/null 2>&1 || { echo "⚠  digikey: uv not installed; skipping"; return 1; }
    sync_repo digikey_mcp https://github.com/grahamseamans/digikey_mcp.git || { echo "⚠  digikey: clone/pull failed"; return 1; }
    local dir="$MCP_DIR/digikey_mcp"
    claude mcp remove digikey --scope user 2>/dev/null || true
    claude mcp add digikey --scope user \
        --env CLIENT_ID="$DIGIKEY_CLIENT_ID" \
        --env CLIENT_SECRET="$DIGIKEY_CLIENT_SECRET" \
        --env USE_SANDBOX="${DIGIKEY_USE_SANDBOX:-false}" \
        -- uv run --directory "$dir" python digikey_mcp_server.py >/dev/null \
        || { echo "⚠  digikey: claude mcp add failed"; return 1; }
    echo "✓ digikey"
    INSTALLED_THIS_RUN+=("digikey")
}
install_digikey

# ─────────── GC: remove managed MCPs that didn't install this run ───────────
# Any MCP in MANAGED_MCPS but not in INSTALLED_THIS_RUN gets unregistered.
# Keeps env consistent with what's declared here, even when a MCP fails or
# a key got removed from the shell env.
for mcp in "${MANAGED_MCPS[@]}"; do
    installed=false
    for i in "${INSTALLED_THIS_RUN[@]:-}"; do
        [ "$i" = "$mcp" ] && installed=true
    done
    if [ "$installed" = false ]; then
        if claude mcp remove "$mcp" --scope user 2>/dev/null; then
            echo "🗑  GC: removed $mcp (not active this run)"
        fi
    fi
done

# ─────────── Verification ───────────
if claude mcp list 2>/dev/null | grep -q "^coworker:"; then
    echo ""
    echo "✓ Done. Coworker registered; env synced."
else
    echo ""
    echo "✗ Done, but coworker is not registered. Check output above."
    exit 1
fi
