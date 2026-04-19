#!/bin/bash
# Dotfiles installer — symlinks Claude config, installs MCP deps,
# registers MCPs with Claude Code. Idempotent; safe to re-run.
#
# Required env vars (must be exported before running this script):
#     XAI_API_KEY              — for coworker MCP (Grok)
#     MOUSER_API_KEY           — for mouser MCP (optional: skipped if missing)
#     DIGIKEY_CLIENT_ID        — for digikey MCP (optional: skipped if missing)
#     DIGIKEY_CLIENT_SECRET    — for digikey MCP (optional: skipped if missing)
#     DIGIKEY_USE_SANDBOX      — optional, defaults to "false"
#
# On host Mac: set these in your shell startup (~/.zshrc or a sourced
# .envrc that's gitignored). Running `./install.sh` picks them up.
#
# In a devcontainer: each project's `.devcontainer/devcontainer.json`
# forwards only the env vars that project needs via containerEnv +
# `${localEnv:XXX}` — VS Code reads from host env and passes in.
#
# Missing optional vars → MCP is skipped with a warning. Missing required
# vars → script exits. No secrets files on disk.

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PLATFORM=$(uname -s)  # Darwin or Linux

echo "→ Dotfiles root: $DOTFILES"
echo "→ Platform: $PLATFORM"

# ─────────── Symlink Claude config ───────────
mkdir -p ~/.claude
ln -sfn "$DOTFILES/claude/CLAUDE.md"     ~/.claude/CLAUDE.md
ln -sfn "$DOTFILES/claude/settings.json" ~/.claude/settings.json
ln -sfn "$DOTFILES/claude/skills"        ~/.claude/skills

# Hooks: symlink cross-platform; stub macOS-only ones on Linux
mkdir -p ~/.claude/hooks
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
echo "✓ Claude config symlinked"

# ─────────── Ensure submodules initialized ───────────
(cd "$DOTFILES" && git submodule update --init --recursive --quiet)

# ─────────── Required env vars ───────────
# XAI_API_KEY is required (coworker is the one MCP we expect to always be there)
: "${XAI_API_KEY:?Error: XAI_API_KEY required (coworker MCP). Set in shell or devcontainer.json.}"

# ─────────── Register coworker MCP (Grok) ───────────
COWORKER_DIR="$DOTFILES/mcp-servers/coworker_mcp"
if command -v node >/dev/null 2>&1 && [ -d "$COWORKER_DIR" ]; then
    # dist/ is gitignored upstream; build if missing
    if [ ! -d "$COWORKER_DIR/node_modules" ]; then
        (cd "$COWORKER_DIR" && npm install --silent) 2>&1 | tail -3
    fi
    if [ ! -f "$COWORKER_DIR/dist/index.js" ]; then
        (cd "$COWORKER_DIR" && npm run build --silent) 2>&1 | tail -3
    fi
    claude mcp remove coworker --scope user 2>/dev/null || true
    claude mcp add coworker --scope user --env XAI_API_KEY="$XAI_API_KEY" \
        -- node "$COWORKER_DIR/dist/index.js" >/dev/null
    echo "✓ coworker MCP registered"
else
    echo "⚠  coworker skipped (node missing or dir missing)"
fi

# ─────────── Register mouser MCP ───────────
MOUSER_DIR="$DOTFILES/mcp-servers/mouser_mcp"
if command -v node >/dev/null 2>&1 && [ -d "$MOUSER_DIR" ] && [ -n "${MOUSER_API_KEY:-}" ]; then
    if [ ! -d "$MOUSER_DIR/node_modules" ]; then
        (cd "$MOUSER_DIR" && npm install --silent) 2>&1 | tail -3
    fi
    if [ ! -d "$MOUSER_DIR/dist" ]; then
        (cd "$MOUSER_DIR" && npm run build --silent) 2>&1 | tail -3
    fi
    claude mcp remove mouser --scope user 2>/dev/null || true
    claude mcp add mouser --scope user --env MOUSER_API_KEY="$MOUSER_API_KEY" \
        -- node "$MOUSER_DIR/dist/index.js" >/dev/null
    echo "✓ mouser MCP registered"
elif [ -z "${MOUSER_API_KEY:-}" ]; then
    echo "⚠  mouser skipped (MOUSER_API_KEY not set)"
fi

# ─────────── Register digikey MCP ───────────
DIGIKEY_DIR="$DOTFILES/mcp-servers/digikey_mcp"
if command -v uv >/dev/null 2>&1 && [ -d "$DIGIKEY_DIR" ] \
    && [ -n "${DIGIKEY_CLIENT_ID:-}" ] && [ -n "${DIGIKEY_CLIENT_SECRET:-}" ]; then
    claude mcp remove digikey --scope user 2>/dev/null || true
    claude mcp add digikey --scope user \
        --env CLIENT_ID="$DIGIKEY_CLIENT_ID" \
        --env CLIENT_SECRET="$DIGIKEY_CLIENT_SECRET" \
        --env USE_SANDBOX="${DIGIKEY_USE_SANDBOX:-false}" \
        -- uv run --directory "$DIGIKEY_DIR" python digikey_mcp_server.py >/dev/null
    echo "✓ digikey MCP registered"
elif ! command -v uv >/dev/null 2>&1; then
    echo "⚠  digikey skipped (uv not installed)"
elif [ -z "${DIGIKEY_CLIENT_ID:-}" ] || [ -z "${DIGIKEY_CLIENT_SECRET:-}" ]; then
    echo "⚠  digikey skipped (DIGIKEY_CLIENT_ID/SECRET not set)"
fi

echo ""
echo "Done. Verify with: claude mcp list"
