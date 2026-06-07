#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

jq -e '
  .npmCommand == ["mise", "exec", "node@24.14.1", "--", "npm"] and
  .sessionDir == ".pi/sessions" and
  .compaction.enabled == true and
  .compaction.reserveTokens == 16384 and
  .compaction.keepRecentTokens == 20000 and
  (.packages | index("npm:pi-lean-ctx@3.7.5")) and
  (.packages | index("npm:pi-mcp-adapter@2.9.0")) and
  ((.packages | index("npm:context-mode@1.0.162")) | not) and
  ((.packages | index("npm:pi-caveman@1.0.7")) | not) and
  .enableSkillCommands == true
' templates/pi/settings.json >/dev/null

jq -e '
  .mode == "additive" and
  .enableMcp == true and
  .env.LEAN_CTX_COMPRESSION == "balanced"
' templates/pi/extensions/pi-lean-ctx/config.json >/dev/null

jq -e '
  .settings.toolPrefix == "server" and
  .settings.idleTimeout == 10 and
  .settings.directTools == false and
  (.mcpServers | keys == ["codebase-memory-mcp"]) and
  .mcpServers["codebase-memory-mcp"].command == "codebase-memory-mcp" and
  .mcpServers["codebase-memory-mcp"].lifecycle == "lazy"
' templates/pi/mcp.json >/dev/null

test -f templates/pi/skills/docmancer/SKILL.md
rg -q '^## Context discipline$' templates/pi/AGENTS.md

rm -rf .pi .agents
mise run install-local >/dev/null

test -f .pi/settings.json
test -f .pi/AGENTS.md
test -f .pi/mcp.json
test -f .pi/skills/docmancer/SKILL.md
test -f .pi/extensions/pi-lean-ctx/config.json

echo "context profile scaffold: ok"

# install-local removes stale template-managed files
touch .pi/skills/stale-canary.md
mise run install-local >/dev/null
test ! -f .pi/skills/stale-canary.md

# doctor-codebase-memory uses soft-fail: must report 'optional' not hard-exit
grep -q "printf 'optional codebase-memory-mcp" mise.toml

# bootstrap-docmancer: pipx install line must not be followed by || true
grep 'pipx install docmancer' mise.toml | grep -qv '|| true'

# doctor-leanctx: must print mise install hint
grep -q 'mise install' mise.toml

echo "task behaviour checks: ok"
