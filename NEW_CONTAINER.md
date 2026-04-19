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
  "runArgs": ["--cap-add=NET_ADMIN", "--cap-add=NET_RAW"],  // needed for firewall

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
  "postStartCommand": "sudo /usr/local/bin/init-firewall.sh",
  "postAttachCommand": "cd ~/dotfiles && git pull --ff-only && ./install.sh",
  "waitFor": "postStartCommand"
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
- Python: `python3 python3-pip`, or install `uv` via the astral.sh script
  (note: add `astral.sh` to firewall whitelist if using the curl install).

### `.devcontainer/init-firewall.sh`

Copy verbatim from go-sequence. Add any project-specific domains to the
whitelist — the default set covers GitHub, npm, Anthropic, Go proxy, VS Code,
gitlab.com, xAI. Gotchas:

- Use `ipset add -exist` (idempotent). Without `-exist`, overlapping IP
  ranges (e.g., GitHub CIDRs + Google Cloud hosts) make the script fail on
  second runs.
- If an MCP hits a new domain, the firewall will silently block it. Check
  with `docker exec <container> sudo /usr/local/bin/init-firewall.sh` and
  watch for "Adding X for domain" lines to confirm all your hosts resolve.

## What happens on "Reopen in Container"

1. Docker builds image (or uses cache).
2. Container starts.
3. `postStartCommand` runs `init-firewall.sh` → iptables rules applied.
4. VS Code clones dotfiles to `~/dotfiles` inside the container.
5. VS Code runs `./install.sh` inside `~/dotfiles`:
   - Symlinks `claude/{CLAUDE.md,settings.json,skills,hooks}` → `~/.claude/`
   - Initializes + npm-installs MCP submodules
   - Registers coworker (requires `XAI_API_KEY`), plus mouser / digikey if
     their keys are forwarded.
6. Container is ready. `claude --dangerously-skip-permissions` → auto mode
   with all your skills, CLAUDE.md, and MCPs available.

## Common pitfalls

- **"Reopen in Container" vs "Rebuild Container"**: Reopen attaches to the
  existing container (no Dockerfile re-run). Rebuild tears down + recreates.
  For changes to Dockerfile / firewall / devcontainer.json, always Rebuild.
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
- [ ] Add project-specific firewall domains to `init-firewall.sh` if the app
      hits anything beyond GitHub/npm/Anthropic/standard Go proxy
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
