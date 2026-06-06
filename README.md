# syscode-pi-agent-kit

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

## Status

Planning scaffold.
