#!/usr/bin/env bash
# E2E comparison: plain codex exec vs Pi+lean-ctx session (both use Codex/ChatGPT Plus).
# Writes timestamped outputs to e2e-out/<timestamp>/ for human review.
# Does NOT run in CI — codex is a user-installed external tool.
#
# Auth:
#   Codex uses your ChatGPT Plus subscription (Codex for OSS program — no extra billing).
#   Log in once interactively: run `codex`, then /login with ChatGPT Plus.
#   Saved credentials are reused by both codex exec and pi --print.
#
#   Pi must also be logged into Codex: run `pi`, then /login → ChatGPT Plus/Pro (Codex).
#
# Metrics:
#   lean-ctx savings are captured as a per-session delta and written to leanctx-delta.json.
#   Set METRICS_PUSH_URL to push Prometheus metrics to a Pushgateway or compatible endpoint:
#     export METRICS_PUSH_URL=http://pushgateway:9091
#   Set SESSION to override the session label (default: pi-leanctx).
#   Run `mise run lean-ctx-daemon` before long sessions for full per-call tracking.
#
# Usage:
#   mise run test-e2e
#
# Output: e2e-out/ (git-ignored)

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

PROMPT='In one paragraph, explain what mise run bootstrap does in this repo and which tools it provisions.'
SESSION="${SESSION:-pi-leanctx}"

# --- preflight ----------------------------------------------------------------

ok=1
for bin in codex pi; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    printf 'missing  %s\n' "$bin" >&2
    ok=0
  fi
done

if [ "$ok" -eq 0 ]; then
  printf '\nInstall hints:\n' >&2
  printf '  codex: mise install  (then: codex /login)\n' >&2
  printf '  pi:    mise run bootstrap\n' >&2
  exit 1
fi

# --- sessions -----------------------------------------------------------------

ts="$(date +%Y%m%dT%H%M%S)"
session_dir="e2e-out/$ts"
mkdir -p "$session_dir"

printf '==> Session A: codex exec (plain, no lean-ctx)\n'
codex exec --ephemeral "$PROMPT" > "$session_dir/codex.md"
printf '    %s\n' "$session_dir/codex.md"

# Snapshot lean-ctx state before Pi session to isolate per-session delta
if command -v lean-ctx >/dev/null 2>&1; then
  lean-ctx gain --json > "$session_dir/leanctx-before.json" 2>/dev/null || true
fi

printf '==> Session B: pi --print (pi-lean-ctx profile)\n'
pi --print "$PROMPT" > "$session_dir/pi-leanctx.md"
printf '    %s\n' "$session_dir/pi-leanctx.md"

# --- metrics ------------------------------------------------------------------

printf '==> LeanCTX metrics\n'
if command -v lean-ctx >/dev/null 2>&1; then
  lean-ctx gain --json > "$session_dir/leanctx-after.json" 2>/dev/null || true

  before_flag=""
  if [ -f "$session_dir/leanctx-before.json" ]; then
    before_flag="--before $session_dir/leanctx-before.json"
  fi

  SESSION="$SESSION" REPO="$(basename "$root")" \
    python3 scripts/leanctx-to-prom.py $before_flag \
    < "$session_dir/leanctx-after.json" \
    > "$session_dir/leanctx-delta.prom"
  printf '    %s\n' "$session_dir/leanctx-delta.prom"

  if [ -n "${METRICS_PUSH_URL:-}" ]; then
    printf '==> Pushing metrics to %s\n' "$METRICS_PUSH_URL"
    curl -sf --data-binary @"$session_dir/leanctx-delta.prom" \
      "${METRICS_PUSH_URL}/metrics/job/pi-agent-kit/instance/${SESSION}" \
      && printf '    pushed ok\n' \
      || printf '    push failed (continuing)\n'
  else
    printf '    set METRICS_PUSH_URL to push to Prometheus Pushgateway\n'
  fi
else
  printf '    lean-ctx not installed; skipping (run: mise install)\n'
fi

# --- summary ------------------------------------------------------------------

printf '\nCompare outputs:\n'
printf '  A (codex exec):  %s\n' "$session_dir/codex.md"
printf '  B (pi+lean-ctx): %s\n' "$session_dir/pi-leanctx.md"
printf '\n  diff %s \\\n       %s\n' "$session_dir/codex.md" "$session_dir/pi-leanctx.md"
