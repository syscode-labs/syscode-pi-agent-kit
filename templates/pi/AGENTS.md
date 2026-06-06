# Pi Agent Instructions

Read the nearest project `AGENTS.md` before acting. If multiple instruction files
apply, follow the most specific one unless it conflicts with a higher-priority
system or developer instruction.

Before starting a task, check whether a relevant skill applies. If a Superpowers
workflow applies, load it through the matching adapter skill and follow the
returned instructions.

Use `mise run <task>` as the stable project command interface. Prefer existing
`mise` tasks over ad hoc command sequences.

Use Safehouse-wrapped commands for risky local sessions, filesystem-sensitive
work, or networked agent activity.

Use the SpecStory wrapper for sessions whose agent history should be retained.

## Context discipline

Use the context stack in this order:

1. For normal file, shell, and search work, prefer LeanCTX-backed tools:
   - `ctx_read` before `read` for non-trivial files.
   - `ctx_shell` before `bash` for noisy commands.
   - `ctx_grep`, `ctx_find`, and `ctx_ls` before raw search or listing tools.
   - `lean_ctx gain`, `lean_ctx stats`, or `ctx_metrics` when asked to quantify
     savings.
2. For documentation questions, use the Docmancer skill or
   `mise run docmancer-query -- "<question>"`.
3. For structural codebase questions, use Codebase Memory MCP through the MCP
   adapter for symbol usage, call graphs, impact analysis, route discovery, and
   cross-service links.
4. Do not install or enable Context Mode and LeanCTX as simultaneous primary
   context routers in the same default profile.
5. Do not enable Caveman globally for architecture, debugging, security,
   incidents, or irreversible edits. Use it only when explicitly requested.
