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
