# syscode-pi-agent-kit

[![CI](https://github.com/syscode-labs/syscode-pi-agent-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/syscode-labs/syscode-pi-agent-kit/actions/workflows/ci.yml)
[![mise](https://img.shields.io/badge/mise-managed-5C4EE5)](https://mise.jdx.dev)
[![pi](https://img.shields.io/badge/pi-0.75.5-blue)](https://earendil.works)
[![experimental](https://img.shields.io/badge/status-experimental-orange)](https://github.com/syscode-labs/syscode-pi-agent-kit)

> **Experimental.** This is a personal research scaffold — nothing here is
> stable, production-ready, or guaranteed to work. Tool versions change, upstream
> APIs break, and entire subsystems may be replaced or removed without notice.
> Use it as a starting point or for inspiration, not as a reliable foundation.

Run a capable AI coding agent on your laptop using your existing ChatGPT Plus
subscription — no extra API costs. The kit bundles a small set of tools that
compress what the agent reads and writes, so each session uses fewer tokens and
costs less. Everything is version-pinned and installed with a single command,
so the environment reproduces reliably across machines.

## What it includes

| Layer | Tool | What it does |
|-------|------|-------------|
| Agent | [Pi](https://earendil.works) | Terminal AI coding agent |
| Model | ChatGPT Plus via Codex CLI | Runs on your existing subscription; no extra billing |
| Compression | [lean-ctx](https://github.com/yvgude/lean-ctx) + pi-lean-ctx | Shrinks file reads, shell output, and search results before they reach the model |
| MCP proxy | pi-mcp-adapter | Loads MCP server tool definitions lazily — ~200 tokens instead of thousands |
| Docs retrieval | Docmancer | Indexes local docs and third-party documentation sites for fast in-session lookup |
| Isolation | [Safehouse](https://safehouse.dev) | Sandboxes Pi sessions on macOS |
| Session capture | [SpecStory](https://specstory.dev) | Records terminal agent history |
| Task runner | [mise](https://mise.jdx.dev) | Single stable command interface for every operation |
| Dev environment | Nix devShell / Devbox | Reproducible bootstrap on any machine |

## Getting started

### 1. Enter a clean environment

```bash
nix develop
# or
devbox shell
```

This gives you a reproducible shell with all system-level dependencies available.
Skip this step only if you already have `mise` installed and trust your local environment.

### 2. Install everything

```bash
mise run bootstrap
```

This runs `mise install` (which pulls pinned versions of Node, Pi, Codex CLI,
lean-ctx, and Groundcrew), pulls the latest skills from
[syscode-agentic-skills](https://github.com/syscode-labs/syscode-agentic-skills)
into `.pi/skills/`, installs Pi extensions for context compression, and copies
the project configuration into `.pi/`.

### 3. Log in to ChatGPT Plus

Both Pi and the Codex CLI authenticate through ChatGPT Plus OAuth. Do this once
per machine:

```bash
codex          # then type /login → select ChatGPT Plus/Pro
pi             # then type /login → select ChatGPT Plus/Pro (Codex)
```

Credentials are saved to `~/.codex/` and `~/.pi/agent/auth.json` and reused
automatically from then on.

### 4. Start a session

```bash
mise run pi            # plain Pi session
mise run pi-safe       # sandboxed via Safehouse (macOS only)
mise run pi-story      # sandboxed + SpecStory session capture (macOS only)
```

Check that everything is wired up correctly at any time:

```bash
mise run doctor
```

## Measuring token savings

lean-ctx tracks how many tokens were compressed away during a session. View a
summary after any Pi session:

```bash
mise run leanctx-gain          # human-readable dashboard
mise run leanctx-gain-json     # machine-readable JSON
```

Or inside Pi, run `/lean-ctx`.

### Export to Prometheus

If you have a Pushgateway (or any compatible endpoint), savings metrics can be
pushed automatically:

```bash
export METRICS_PUSH_URL=http://pushgateway:9091
mise run push-leanctx-metrics
```

For per-tool-call granularity, start the lean-ctx daemon before your session:

```bash
mise run lean-ctx-daemon
```

The e2e test (`mise run test-e2e`) captures a before/after delta automatically
and pushes it to `$METRICS_PUSH_URL` if set.

<details>
<summary>Emitted metrics</summary>

All metrics carry `repo` and `session` labels.

| Metric | Type | Description |
|--------|------|-------------|
| `lean_ctx_tokens_saved` | gauge | Tokens saved by compression this session |
| `lean_ctx_avoided_usd` | gauge | API cost avoided this session (USD) |
| `lean_ctx_total_commands` | counter | Compressed tool calls this session |
| `lean_ctx_gain_rate_pct` | gauge | Compression gain rate % |
| `lean_ctx_roi` | gauge | ROI (avoided / spend) |
| `lean_ctx_score_compression` | gauge | Compression score 0–10 |
| `lean_ctx_score_cost_efficiency` | gauge | Cost efficiency score 0–10 |
| `lean_ctx_score_quality` | gauge | Quality score 0–10 |
| `lean_ctx_score_consistency` | gauge | Consistency score 0–10 |

</details>

## Optional extras

```bash
mise run bootstrap-docmancer         # index documentation sites for in-session lookup
DOCS_URL=https://docs.pytest.org mise run docmancer-add
mise run docmancer-query -- "How do I parametrize fixtures?"

mise run install-caveman             # output-token compressor (experimental)
mise run install-context-mode-profile  # alternate compression router (not compatible with lean-ctx)
```

> Do not enable the Context Mode profile alongside lean-ctx — they both act as
> the default compression router and will conflict.

## E2E comparison

Run the same prompt through plain `codex exec` and a Pi+lean-ctx session, then
diff the outputs:

```bash
mise run test-e2e
```

Results land in `e2e-out/<timestamp>/` (git-ignored). Not run in CI.

---

## Reference

<details>
<summary>All mise tasks</summary>

| Task | Description |
|------|-------------|
| `mise run bootstrap` | Full install: tools, Pi extensions, local config |
| `mise run bootstrap-context` | Install pi-lean-ctx and pi-mcp-adapter |
| `mise run bootstrap-docmancer` | Install and initialise Docmancer |
| `mise run install-local` | Copy templates into `.pi/` |
| `mise run doctor` | Report required and optional tool availability |
| `mise run doctor-leanctx` | Check lean-ctx binary and Pi wiring |
| `mise run doctor-codex` | Check Codex CLI |
| `mise run doctor-codebase-memory` | Check Codebase Memory MCP (optional) |
| `mise run pi` | Run Pi directly |
| `mise run pi-safe` | Run Pi through Safehouse (macOS) |
| `mise run pi-story` | Run Pi through Safehouse + SpecStory (macOS) |
| `mise run leanctx-gain` | Token-savings dashboard |
| `mise run leanctx-gain-json` | Token-savings as JSON |
| `mise run lean-ctx-daemon` | Start lean-ctx daemon for per-call tracking |
| `mise run push-leanctx-metrics` | Push metrics to Pushgateway (`$METRICS_PUSH_URL`) |
| `mise run test` | Run scaffold tests |
| `mise run test-e2e` | Run e2e comparison (costs tokens; requires auth) |
| `mise run audit-public` | Scan for secrets and machine-specific paths |

</details>

<details>
<summary>Pinned versions</summary>

| Tool | Version |
|------|---------|
| Node.js | 24.14.1 |
| Pi | 0.75.5 |
| Codex CLI | 0.137.0 |
| lean-ctx | 3.7.5 |
| Groundcrew | 4.10.4 |
| Safehouse | 0.10.1 |
| SpecStory | 1.13.0 |

</details>
