---
name: setup-pstack
description: Configure which agents and models pstack uses per role. Detects the agent CLIs Orca can launch and writes a config file that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", or changing pstack's agent/model choices.
---

# Setup pstack

Write `~/.pi/agent/pstack-models.md`, the pstack role-to-worker config. Every value is an
Orca worker launch spec: an agent CLI id, optionally followed by model flags. The skills
read it and fall back to their inline defaults when a line is absent, so this is an
override layer, not a requirement.

## Steps

### 1. Detect available agents

Enumerate the agent CLIs Orca can launch as workers. `command -v` each of the known ids:
`pi`, `claude`, `codex`, `grok`, `omp`, `opencode`, `gemini`, `droid`, `cursor-agent`.
The detected set is the dependable source. For per-agent model flags, prefer what the
agent itself reports (`pi --help`, the user's `~/.pi/agent/settings.json`/`models.json`,
`claude`/`codex` docs) over memory; never write a real model slug you have not confirmed.
The aliases `inherit-parent` and `auto` are always valid even though they are not detected.

Workers launch through Orca orchestration:

```bash
orca orchestration worker-start --task <task_id> --worktree current --agent <id> [--model <slug>] [--effort <level>] --json
```

`--model` and `--effort` apply only to fresh agent terminals and only where the agent
supports them. When in doubt, configure just the agent id and let the agent's own default
model apply.

### 2. Load current state

The default role-to-worker mapping is the config shape shown in step 5 below. If
`~/.pi/agent/pstack-models.md` already exists, read it and treat its values as the current
choices. Otherwise start from those defaults.

### 3. Map and confirm

Show every role with its current worker, marking any agent id not in the detected set as
needing a choice. Ask whether to accept as-is or change specific roles, offering the
detected agents plus `inherit-parent` and `auto` (both mean: this role runs on the parent
chat's own agent and model) as the options. For panel roles (how critics, arena runners,
architect runners, interrogate reviewers) the value is a comma-separated list, and one
worker runs per entry, alias entries included, so the list length sets the fan-out count.
`arena cross-judge pool` is also a list, but Arena selects one value from it whose agent
family differs from the parent's when possible. `swarm workers` is the default worker for
every arm unless a race or comparison assigns another per arm.

Panel diversity is the point of the multi-model workflows. A panel of four identical
agents collapses the signal to one model's blind spots.

### 4. Validate

Every agent id written must be in the detected set; `inherit-parent` and `auto` always
pass. If a chosen id is not launchable, stop and ask again. A config pointing at an agent
the user cannot run breaks every delegation that reads it.

### 5. Write the config

Write `~/.pi/agent/pstack-models.md`, overwriting the whole file so re-runs stay
idempotent. Shape:

```markdown
# pstack worker configuration. One line per role: `<role>: <agent> [--model <slug>] [--effort <level>]`.
# Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat's agent and
# model. Alias entries in a panel list still count toward its fan-out.
feature, refactoring: grok
bug-fix: codex
perf-issue: codex
hillclimb: codex
judgment and prose: claude
hardest tasks: claude
how explorer: grok
how explainer: claude
how critics: claude, codex, grok, pi
why investigators: grok
why synthesizer: claude
reflect tooling: codex
reflect judgment, divergent, synthesizer: claude
arena runners: claude, codex, grok, pi
arena cross-judge pool: claude, codex, grok, pi
swarm workers: grok
architect runners: claude, codex, grok, pi
interrogate reviewers: claude, codex, grok, pi
```

Unlike a Cursor `alwaysApply` rule, nothing injects this file into context. The skills
read it explicitly at delegation time, which keeps it out of sessions that never delegate.

### 6. Confirm

Tell the user the config was written and that skills pick it up on the next delegation,
no restart needed. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill,
or an existing harness). If not, offer once: "want a project-local verification skill, so
agents can drive the app the way a user does and prove changes work? I can generate one
with /skill:create-verification-skill." On yes, invoke that skill (resolves wherever
pstack-orca is installed). On no, move on without pushing.
