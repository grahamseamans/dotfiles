# dotfiles

My portable Claude Code setup. Clone anywhere, run `install.sh`, same config.

## What's in here

```
dotfiles/
├── install.sh                  # symlinks claude/*, installs + registers MCPs
├── claude/
│   ├── CLAUDE.md               # global CLAUDE.md
│   ├── settings.json           # global settings (hooks wired to ~/.claude/hooks/)
│   ├── skills/                 # all my skills
│   └── hooks/
│       ├── load-skills.sh
│       ├── timestamp.sh
│       └── permission-alert.sh # macOS-only; install.sh stubs it on Linux
└── mcp-servers/                # git submodules
    ├── coworker_mcp/           # Grok MCP (my own repo)
    ├── mouser_mcp/             # Mouser BOM tool (my own repo)
    └── digikey_mcp/            # DigiKey MCP (bengineer19)
```

## Setup on a new machine

```bash
# 1. Clone with submodules
git clone --recurse-submodules https://github.com/grahamseamans/dotfiles.git ~/dotfiles

# 2. Set env vars in your shell startup (~/.zshrc) — see "Env vars" below

# 3. Install
cd ~/dotfiles && ./install.sh

# 4. Verify
claude mcp list    # should show coworker, mouser, digikey (if all keys set)
```

Prerequisites per machine:
- **Mac**: `brew install node uv` (Claude Code also needs to be installed)
- **Linux container**: handled by the devcontainer's `Dockerfile` (install `nodejs`, `uv`, `@anthropic-ai/claude-code`)

## Env vars

No secrets files on disk. Everything goes through your shell env (or VS Code's
`containerEnv` → `${localEnv:XXX}` forwarding for devcontainers).

**Required:**
- `XAI_API_KEY` — Grok (coworker MCP)

**Optional (MCPs skip if missing):**
- `MOUSER_API_KEY`
- `DIGIKEY_CLIENT_ID`, `DIGIKEY_CLIENT_SECRET`, `DIGIKEY_USE_SANDBOX` (defaults "false")

**Per-project GitHub PATs** (fine-grained, one repo each):
- `GITHUB_TOKEN_GOSEQUENCE`
- `GITHUB_TOKEN_DOTFILES`
- `GITHUB_TOKEN_<PROJECT>` as needed

Scoped PATs live in your shell env. Each project's
`.devcontainer/devcontainer.json` forwards only that project's token:

```jsonc
"containerEnv": {
    "XAI_API_KEY": "${localEnv:XAI_API_KEY}",
    "GITHUB_TOKEN":  "${localEnv:GITHUB_TOKEN_GOSEQUENCE}"
}
```

VS Code reads from host env, passes only what's declared. Blast radius of a
compromised container = the one repo its PAT is scoped to.

## Devcontainer integration

In VS Code's user settings:
```json
{
  "dotfiles.repository": "https://github.com/grahamseamans/dotfiles",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "~/dotfiles/install.sh"
}
```

Every new devcontainer auto-clones dotfiles and runs install.sh on first
start. The project's own `.devcontainer/Dockerfile` is responsible for
installing node/uv/claude so `install.sh` has what it needs.

## Updating the MCP submodules

```bash
# pick up latest of a specific MCP
cd ~/dotfiles/mcp-servers/coworker_mcp && git pull origin main
cd ~/dotfiles && git add mcp-servers/coworker_mcp && git commit -m "bump coworker_mcp"
git push

# ... or all of them
cd ~/dotfiles && git submodule update --remote --merge
git add mcp-servers && git commit -m "bump submodules" && git push
```

Other machines: `git pull && git submodule update && ./install.sh`.
