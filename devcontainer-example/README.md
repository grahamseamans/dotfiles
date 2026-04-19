# devcontainer-example

A copy of go-sequence's `.devcontainer/` as a reference template for
spinning up new Claude devcontainers. Not used directly by dotfiles —
it's here so you can copy + adapt.

## When starting a new project

```bash
cp -R ~/dotfiles/devcontainer-example <your-project>/.devcontainer
```

Then edit:

1. **`devcontainer.json`**
   - `"name"` → your project's name
   - `"GOLANG_VERSION"` args block → remove if not Go, or replace with
     your language's version arg
   - `containerEnv.GITHUB_TOKEN` and `.GH_TOKEN` → change
     `GITHUB_TOKEN_GOSEQUENCE` to `GITHUB_TOKEN_<YOUR_PROJECT>`
   - MCP keys (XAI_API_KEY, MOUSER_API_KEY, DIGIKEY_*) → leave as-is,
     forward them all
   - Language-specific mounts (`gocache`, `gomodcache`) → swap for your
     language (e.g., `.cargo` for Rust, `.cache/pip` for Python)

2. **`Dockerfile`**
   - Keep the Node 20 base (Claude Code needs Node)
   - Keep firewall/claude/zsh setup
   - Replace the Go install block with your language's toolchain
   - Add any C/C++ build deps your project needs (`libasound2-dev` etc.)

3. **Generate a scoped GitHub PAT for the new project**
   - https://github.com/settings/personal-access-tokens/new
   - Repository access: only the new repo
   - Contents + Pull requests (read/write)
   - Add to `~/.zshrc`: `export GITHUB_TOKEN_<YOUR_PROJECT>=ghp_...`

4. **Open in VS Code → "Reopen in Container"**
   - First build takes ~5 min
   - dotfiles auto-install on attach
   - Verify inside: `claude mcp list` + `gh api user`

See `~/dotfiles/NEW_CONTAINER.md` for full rationale and gotchas.
