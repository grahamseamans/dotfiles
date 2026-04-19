# Setting up a new Claude Code devcontainer

Pattern for starting a new project with a sandboxed Claude Code
devcontainer that auto-picks-up your dotfiles.

## One-time setup per machine (already done on this Mac)

1. Install Docker Desktop + VS Code + the Dev Containers extension.
2. Set these in VS Code user settings:
    ```json
    "dotfiles.repository": "https://github.com/grahamseamans/dotfiles",
    "dotfiles.targetPath": "~/dotfiles",
    "dotfiles.installCommand": "./install.sh"
    ```
    Gotcha: `./install.sh` NOT `~/dotfiles/install.sh`. VS Code sets cwd to
    the target path; `~` doesn't expand in the install command string.
3. Add MCP keys to `~/.zshrc`:
    ```bash
    export XAI_API_KEY=...
    export MOUSER_API_KEY=...    # optional
    export DIGIKEY_CLIENT_ID=... # optional
    export DIGIKEY_CLIENT_SECRET=...
    export DIGIKEY_USE_SANDBOX=false
    ```

## Per-project devcontainer setup

Copy the shape of `go-sequence/.devcontainer/` as a template. Three files:

### `.devcontainer/devcontainer.json`

```jsonc
{
  "name": "<project> dev",
  "build": {
    "dockerfile": "Dockerfile",
    "args": {
      "TZ": "${localEnv:TZ:America/Los_Angeles}",
      "CLAUDE_CODE_VERSION": "latest",
      "GIT_DELTA_VERSION": "0.18.2",
      "ZSH_IN_DOCKER_VERSION": "1.2.0"
      // + any per-language versions you need (Go, Python, etc.)
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code"
        // + your language extension(s)
      ]
    }
  },

  "remoteUser": "node",
  "mounts": [
    "source=${localWorkspaceFolderBasename}-bashhistory,target=/commandhistory,type=volume",
    "source=${localWorkspaceFolderBasename}-claude-config,target=/home/node/.claude,type=volume"
    // + any language-specific caches (GOCACHE, .cargo, etc.)
  ],

  "containerEnv": {
    "CLAUDE_CONFIG_DIR": "/home/node/.claude",

    // MCP keys: forward all of them everywhere. They're read-mostly
    // personal API keys with low blast radius if leaked. Simpler than
    // scoping per-project. install.sh skips MCPs whose keys are missing.
    "XAI_API_KEY": "${localEnv:XAI_API_KEY}",
    "MOUSER_API_KEY": "${localEnv:MOUSER_API_KEY}",
    "DIGIKEY_CLIENT_ID": "${localEnv:DIGIKEY_CLIENT_ID}",
    "DIGIKEY_CLIENT_SECRET": "${localEnv:DIGIKEY_CLIENT_SECRET}",
    "DIGIKEY_USE_SANDBOX": "${localEnv:DIGIKEY_USE_SANDBOX}",
    "WEATHER_LAT": "${localEnv:WEATHER_LAT}",
    "WEATHER_LON": "${localEnv:WEATHER_LON}",

    // GitHub PAT: SCOPED per project. A PAT grants write access to repos,
    // so a compromised container = blast radius of every repo the PAT can
    // touch. Generate a fine-grained PAT scoped to ONLY this project's
    // repo, store as GITHUB_TOKEN_<PROJECT> in your shell, forward as
    // both GITHUB_TOKEN (git default) and GH_TOKEN (gh CLI default).
    "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN_<PROJECT>}",
    "GH_TOKEN":     "${localEnv:GITHUB_TOKEN_<PROJECT>}"
  },

  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",
  "workspaceFolder": "/workspace",
  "postAttachCommand": "cd ~/dotfiles && git pull --ff-only && ./install.sh"
}
```

**Key rules:**
- Mount names use `${localWorkspaceFolderBasename}` (stable, documented).
  NOT `${devcontainerId}` (undocumented hash, may change across VS Code
  versions and silently lose your volumes).
- **MCP keys: forward all everywhere.** They're personal read-mostly API
  keys; the marginal risk of having them in N containers vs 1 is ~zero.
- **GitHub PATs: scoped per project, ALWAYS.** Real write-capable
  credentials. Generate a fine-grained PAT per repo. Forward only the
  one this project needs.
- `${localEnv:FOO}` resolves at container creation. If unset on host →
  forwarded as empty string → install.sh's optional-MCP checks skip
  gracefully. Required vars (XAI_API_KEY) → install.sh exits with error.
- `postAttachCommand` re-syncs dotfiles + reruns install.sh on every
  container attach. Means MCPs always-latest, env always matches what's
  declared in dotfiles.

### `.devcontainer/Dockerfile`

Start from Anthropic's reference (Node 20 base — Claude Code needs Node).
Add language toolchains as needed. Examples from go-sequence's Dockerfile:

- Go: download from `go.dev/dl` (arch-aware for arm64/amd64).
- C/C++ native builds (e.g., for rtmidi): `build-essential pkg-config libasound2-dev`
- **uv + python3: install in every container by default** (not just for
  Python-based projects). Claude's python-runtime skill uses `uv run
  --with <pkg>` for ad-hoc scripting / data exploration / one-off analysis.
  Without it in the container, that whole workflow doesn't work. Install
  via: `curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh`.
  Also install `python3 python3-venv ca-certificates` via apt so uv has
  a base Python and can fetch packages.

### No outbound firewall

Earlier iterations had an iptables/ipset default-deny firewall running at
container start. Dropped it. Rationale: auto-mode Claude needs arbitrary
outbound fetch to do its job (Go modules, npm packages, docs, GitHub
clones, etc.). Whitelisting becomes operational tax without meaningful
security gain — attack vectors like "malicious npm package" already have
the registry whitelisted anyway, and exfiltration via whitelisted
endpoints (GitHub push to attacker repo) isn't prevented.

The sandbox's real protections are filesystem isolation (Docker keeps
Claude in `/workspace` + volumes) and the scoped GitHub PAT (limits git
damage to one repo). Those are kept.

If you DO want the firewall for a particular project (e.g., sensitive
secrets in the container, or a specific threat model), git log the
go-sequence repo for the pre-removal versions — the `init-firewall.sh`
script is preserved in history and can be re-added.

## What happens on "Reopen in Container"

1. Docker builds image (or uses cache).
2. Container starts.
3. VS Code clones dotfiles to `~/dotfiles` inside the container.
4. VS Code runs `./install.sh` inside `~/dotfiles`:
   - Symlinks `claude/{CLAUDE.md,settings.json,skills,hooks}` → `~/.claude/`
   - Initializes + npm-installs MCP submodules
   - Registers coworker (requires `XAI_API_KEY`), plus mouser / digikey if
     their keys are forwarded.
6. Container is ready. `claude --dangerously-skip-permissions` → auto mode
   with all your skills, CLAUDE.md, and MCPs available.

## Common pitfalls

- **"Reopen in Container" vs "Rebuild Container"**: Reopen attaches to the
  existing container (no Dockerfile re-run). Rebuild tears down + recreates.
  For changes to Dockerfile / devcontainer.json, always Rebuild.
- **Persistent Claude volume**: `~/.claude` is a named Docker volume, so it
  survives rebuilds. Good for auth persistence, bad when stale MCP configs
  from earlier setups shadow dotfiles-managed ones. If you see the wrong
  MCP path in `claude mcp list`, check for duplicate entries across scopes:
  `claude mcp remove <name> -s local` + `-s user`.
- **Missing env var stops install.sh**: install.sh requires `XAI_API_KEY`.
  Other keys are optional. If your shell env doesn't have `XAI_API_KEY`,
  VS Code passes an empty string and install fails.
- **MCP repos must be public** (or forward a GitHub token into the
  container so install.sh can clone them). install.sh's `sync_repo` step
  uses HTTPS clones, no auth by default.
- **MIDI / USB / audio hardware**: Docker Desktop on macOS can't pass
  through USB/MIDI devices. Containers are for code/tests only; run the
  app on the host for hardware integration.

## Debugging a failed dotfiles install

Logs live at
`~/Library/Application Support/Code/logs/*/window*/exthost/ms-vscode-remote.remote-containers/*.log`.
Grep for `dotfile` or `installcommand`.

To run install.sh manually inside a running container:

```bash
C=$(docker ps -q -f "label=devcontainer.local_folder=/path/to/project")
docker exec --user node -e XAI_API_KEY="$XAI_API_KEY" "$C" bash /home/node/dotfiles/install.sh
```

`bash -x /home/node/dotfiles/install.sh` gives line-by-line trace if the
script exits silently.

## Checklist for a new project

- [ ] Copy `.devcontainer/` from an existing project (go-sequence is a
      good template)
- [ ] Update `name` in devcontainer.json
- [ ] Update Dockerfile for language toolchains this project needs
- [ ] Generate a scoped GitHub PAT for this repo (only Contents +
      PullRequests write on just this repo). Add to `~/.zshrc`:
      `export GITHUB_TOKEN_<PROJECT>=ghp_...`
- [ ] In devcontainer.json, change the GITHUB_TOKEN/GH_TOKEN forwards to
      reference `${localEnv:GITHUB_TOKEN_<PROJECT>}`
- [ ] Open in VS Code → "Reopen in Container" → wait for build
- [ ] Inside container: `claude mcp list` → verify coworker connected
- [ ] Inside container: `gh api user` → verify PAT works (returns your username)
- [ ] Inside container: `claude` → ask "which Grok model do you use?" → confirm
      it answers `grok-4-1-fast-reasoning` (proves skills loaded)

## Future considerations

**Nix flakes + devshell** — fully declarative reproducibility across machines,
no Docker needed for the tool-versioning concern. Each project gets a
`flake.nix` that pins exact versions of Go/Node/Python/uv/etc. The auto-mode
sandboxing still wants Docker, so the mature pattern is *Nix inside the
devcontainer*: Dockerfile shrinks to "install Nix", the flake handles
everything else. Real week-plus learning curve though (flake syntax, lazy
eval, etc.). Worth doing once you have >3 personal projects hitting this
"containers are great but pinning versions everywhere is a pain" wall.
