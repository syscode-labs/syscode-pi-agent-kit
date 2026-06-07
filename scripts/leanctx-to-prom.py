#!/usr/bin/env python3
"""
Convert lean-ctx gain --json output to Prometheus text format.

Usage:
  lean-ctx gain --json | python3 scripts/leanctx-to-prom.py
  lean-ctx gain --json | python3 scripts/leanctx-to-prom.py --before /path/to/before.json

When --before is given, emits per-session delta values for accumulating
metrics (tokens_saved, avoided_usd, total_commands).  Rate/score fields
always reflect the current snapshot.

Environment:
  SESSION   label value (default: pi-leanctx)
  REPO      label value (default: syscode-pi-agent-kit)
"""

import argparse
import json
import os
import sys


def load(path):
    with open(path) as f:
        return json.load(f)["summary"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--before", metavar="FILE", help="JSON snapshot taken before the session")
    args = parser.parse_args()

    after = json.load(sys.stdin)["summary"]
    before = load(args.before) if args.before else None

    def d(key):
        if before is not None:
            return after[key] - before[key]
        return after[key]

    session = os.environ.get("SESSION", "pi-leanctx")
    repo = os.environ.get("REPO", "syscode-pi-agent-kit")
    labels = f'repo="{repo}",session="{session}"'

    metrics = [
        # delta counters — per-session savings
        ("lean_ctx_tokens_saved",   "gauge",   "Tokens saved by lean-ctx compression this session",        d("tokens_saved")),
        ("lean_ctx_avoided_usd",    "gauge",   "API cost avoided by compression this session (USD)",        d("avoided_usd")),
        ("lean_ctx_total_commands", "counter", "Compressed tool calls this session",                        d("total_commands")),
        # snapshot rates — reflect current session's efficiency
        ("lean_ctx_gain_rate_pct",  "gauge",   "Compression gain rate percent",                             after["gain_rate_pct"]),
        ("lean_ctx_roi",            "gauge",   "Compression ROI (avoided_usd / tool_spend_usd)",            after["roi"]),
        # score dimensions
        ("lean_ctx_score_compression",    "gauge", "lean-ctx compression score (0-10)",  after["score"]["compression"]),
        ("lean_ctx_score_cost_efficiency","gauge", "lean-ctx cost efficiency score (0-10)", after["score"]["cost_efficiency"]),
        ("lean_ctx_score_quality",        "gauge", "lean-ctx quality score (0-10)",       after["score"]["quality"]),
        ("lean_ctx_score_consistency",    "gauge", "lean-ctx consistency score (0-10)",   after["score"]["consistency"]),
    ]

    for name, mtype, help_text, value in metrics:
        print(f"# HELP {name} {help_text}")
        print(f"# TYPE {name} {mtype}")
        print(f"{name}{{{labels}}} {value}")


if __name__ == "__main__":
    main()
