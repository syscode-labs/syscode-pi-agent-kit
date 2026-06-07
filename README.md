# syscode-pi-agent-kit

[![CI](https://github.com/syscode-labs/syscode-pi-agent-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/syscode-labs/syscode-pi-agent-kit/actions/workflows/ci.yml)
[![mise](https://img.shields.io/badge/mise-managed-5C4EE5)](https://mise.jdx.dev)
[![pi](https://img.shields.io/badge/pi-0.75.5-blue)](https://earendil.works)
[![experimental](https://img.shields.io/badge/status-experimental-orange)](https://github.com/syscode-labs/syscode-pi-agent-kit)

> **Experimental.** This kit is a personal research scaffold — nothing here is
> stable, production-ready, or guaranteed to work. Tool versions change, upstream
> APIs break, and entire subsystems may be replaced or removed without notice.
> Use it as a starting point or for inspiration, not as a reliable foundation.

**In plain terms:** this repo is a ready-to-use setup that lets you run an AI
coding agent (Pi) on your laptop, powered by your existing ChatGPT Plus
subscription — no extra API costs. It wires up a small stack of tools that
compress what the AI reads and writes so it uses fewer tokens per task, making
sessions cheaper and faster. Everything is pinned to specific versions and
installed with a single command, so the environment is reproducible across
machines.

Scaffold for making Pi behave like the current Claude/Codex workflow:

- `mise` tasks as the stable command interface.
- Nix devShell or Devbox as clean-machine bootstrap environments.
- Safehouse-wrapped Pi sessions for local isolation.
- SpecStory capture for terminal agent history.
- Pi skills and subagent profiles, including Superpowers adapters.
- Optional Groundcrew integration for ticket dispatch.
- Future Imp integration for stronger Firecracker-backed agent sandboxes.

## Bootstrap

Do not assume any agent tooling is installed. Enter through one available
bootstrap environment:

```bash
nix develop
# or
devbox shell
```

Then provision managed tools and project-local Pi configuration:

```bash
mise run bootstrap
```

`mise` provisions pinned Node.js, Pi, and Groundcrew versions. The bootstrap also
installs the project-local Pi subagent extension and copies the generated Pi
configuration into `.pi/`.

Check tool availability at any time:

```bash
mise run doctor
```

Safehouse `v0.10.1` is pinned and exposed automatically by both bootstrap
environments. It remains usable only on macOS.

SpecStory `v1.13.0` is also pinned and exposed automatically by both bootstrap
environments. It must pass `mise run doctor-specstory` before captured sessions
start.

## Context-efficiency profile

Default stack:

- Pi + Safehouse + SpecStory.
- LeanCTX via `pi-lean-ctx` for file/shell/search compression.
- Docmancer for local/docs-site documentation retrieval.
- `pi-mcp-adapter` for optional MCP servers without eager tool-definition bloat.
- Codebase Memory MCP for structural codebase graph queries, when installed.
- Caveman is optional and not enabled by default.
- Context Mode is an alternate experimental profile, not installed with LeanCTX.

### Install

`pi-lean-ctx` requires the `lean-ctx` binary, provisioned automatically by `mise install`. Then:

```bash
nix develop
# or
devbox shell

mise run bootstrap
mise run bootstrap-context
mise run bootstrap-docmancer
mise run doctor
mise run doctor-leanctx
mise run doctor-docmancer
mise run doctor-codebase-memory

# Index this repo into the Codebase Memory knowledge graph (optional)
mise run index-codebase-memory
```

### Measure savings

```bash
mise run leanctx-gain
mise run leanctx-gain-json
```

Inside Pi:

```text
/lean-ctx
```

### Prometheus metrics

lean-ctx savings can be exported to any Prometheus Pushgateway or
Pushgateway-compatible endpoint (`/metrics/job/<job>` HTTP POST):

```bash
# Push current cumulative metrics
export METRICS_PUSH_URL=http://pushgateway:9091
mise run push-leanctx-metrics

# Override session label (default: pi-leanctx)
SESSION=my-session mise run push-leanctx-metrics
```

The e2e test (`mise run test-e2e`) captures a per-session delta automatically:
before-snapshot → run Pi session → after-snapshot → compute delta →
push to `$METRICS_PUSH_URL` if set.

Emitted metrics (all labelled `repo` and `session`):

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

For full per-tool-call granularity, start the lean-ctx daemon before your session:

```bash
mise run lean-ctx-daemon
```

### Query docs

```bash
DOCS_URL=https://docs.pytest.org mise run docmancer-add
mise run docmancer-query -- "How do I parametrize fixtures?"
```

### Optional tools

```bash
mise run install-caveman
mise run install-context-mode-profile
```

Do not run the Context Mode profile and LeanCTX profile as simultaneous default routers.

> **Note:** Safehouse (`pi-safe`, `pi-story`) requires macOS. The rest of the
> context-efficiency stack works on any platform.

## Authentication

Pi and the Codex CLI both use your **ChatGPT Plus subscription** via OAuth.
OpenAI's Codex for OSS program covers third-party harness usage — no separate
API billing.

**One-time login for Codex CLI:**

```bash
codex
# inside: /login → select ChatGPT Plus/Pro
```

**One-time login for Pi:**

```bash
pi
# inside: /login → select ChatGPT Plus/Pro (Codex)
```

Saved credentials in `~/.codex/` and `~/.pi/agent/auth.json` are reused
automatically by `codex exec` and `pi --print`.

## E2E comparison test

Run the same prompt through plain `codex exec` (Session A) and a Pi+lean-ctx
session (Session B), then review outputs side by side:

```bash
mise run test-e2e
```

Both sessions use ChatGPT Plus OAuth (Codex for OSS — no extra billing).
Log in to both `codex` and `pi` interactively before running.
Outputs are written to `e2e-out/<timestamp>/` (git-ignored). Local-only; not run in CI.

## Status

Planning scaffold.
