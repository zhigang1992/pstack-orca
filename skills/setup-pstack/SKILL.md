---
name: setup-pstack
description: Configure which agents pstack uses per role. Detects the agent CLIs Orca can launch and writes the Claude Code rule that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", or changing pstack's agent choices.
---

# Setup pstack

Write the pstack role-to-worker config. A value is either `inherit-parent` (this session
does the role) or an Orca agent id, optionally followed by `--model` and `--effort`.
The contract is `docs/routing.md`. Skills fall back to their inline defaults when a line
is absent, so this is an override layer, not a requirement.

**The config has three scopes, checked in this order:**

1. `.pstack-models.md` at the project root. Per-project and per-use-case; commit it to
   share a team's worker policy with the repo.
2. `~/.claude/rules/pstack-models.md`. Per-user, across all projects. Claude Code loads
   it into every new session. This is the file to write.
3. `~/.pi/agent/pstack-models.md`. Legacy. Mirror the Claude file here so an old lookup
   cannot disagree. Do not treat it as a second policy.

A role set in the project file beats the user file. A role absent from all three keeps
the skill's inline default. The repo itself ships no config, so nothing user-specific
leaks into a published copy.

## Steps

### 1. Detect available agents

Enumerate the agent CLIs Orca can launch as workers. `command -v` each of the known ids:
`pi`, `claude`, `codex`, `grok`, `opencode`, `kimi`, `cursor-agent`. A binary on PATH is
not enough. The dependable set is the `agent` values in Orca's
`agent-model-catalog.json` (under Application Support), because that is what has
actually launched. Do not write an id that is absent from it. `claude` can be present
and still not be a second family: if its `opus`, `sonnet`, and `haiku` entries resolve
to a Magpie group, treat bare `claude` as `inherit-parent`. See `docs/routing.md`.
Never write a `--model` you have not confirmed against that catalog or the agent's own
help. The aliases `inherit-parent` and `auto` are always valid.

Workers launch through Orca orchestration:

```bash
orca orchestration worker-start --task <task_id> --worktree current --agent <id> [--model <slug>] [--effort <level>] --json
```

`--model` and `--effort` apply only to fresh agent terminals and only where the agent
supports them. When in doubt, configure just the agent id and let the agent's own default
model apply.

### 2. Load current state

The default role-to-worker mapping is the config shape shown in step 5 below. Read the
project file first, then `~/.claude/rules/pstack-models.md`, then the pi file. If none
exist, start from the defaults.

Ask which scope to write: project (shared with the team) or user (just you, everywhere).
Default to user scope unless the user asked for a project or team setting. User scope
writes the Claude file and mirrors it to the pi path.

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

Write the chosen scope's file, overwriting the whole file so re-runs stay idempotent.
User scope writes `~/.claude/rules/pstack-models.md` with no frontmatter, then copies
the same bytes to `~/.pi/agent/pstack-models.md`. Project scope writes
`.pstack-models.md` only. Shape:

```markdown
# pstack worker configuration. One line per role: `<role>: <agent> [--model <slug>] [--effort <level>]`.
# Delete a line to fall back to the skill default.
# Lookup, first hit wins: project `.pstack-models.md`, this file, `~/.pi/agent/pstack-models.md`.
# Contract: docs/routing.md in the pstack-orca checkout.
#
# inherit-parent or auto: this session does the role. No model pin. No --agent claude.
# A Claude model pin is not a second family. Magpie resolves opus, sonnet, and haiku
# to group/never-stuck[1m]. That group fails over one seat at a time across Claude,
# Codex, Grok, Cursor, and Kimi. It does not run them together.
# codex, grok, pi, opencode, cursor: Orca worker-start --agent <id>.
# Do not pass that word as a Claude Agent model. Do not pass a Magpie group as --model.
# budget: medium (high). Parent effort only. Workers use their CLI default.

# parent thinks
judgment and prose: inherit-parent
hardest tasks: inherit-parent
how explainer: inherit-parent
why synthesizer: inherit-parent
reflect judgment, divergent, synthesizer: inherit-parent

# codex executes a brief
bug-fix: codex
perf-issue: codex
hillclimb: codex
reflect tooling: codex

# grok does fast edits and bulk reads
feature, refactoring: grok
how explorer: grok
why investigators: grok
swarm workers: grok

# three families. list length is the fan-out. judge pool puts codex first.
how critics: codex, grok, pi
arena runners: codex, grok, pi
arena cross-judge pool: codex, pi, grok
architect runners: codex, grok, pi
interrogate reviewers: codex, grok, pi
```

Claude Code injects `~/.claude/rules/pstack-models.md` into every new session. Skills
still read it at delegation time. The pi path is a mirror, not a second source.

Prefer agent ids without `--model`. pi and grok run their own configured default, and
pi's default is the kimi seat. Add `--model` only when the user named one that Orca's
catalog lists for that agent. The only Claude pin that leaves the failover group is
`claude-fable-5-1`.

### 6. Confirm

Tell the user the config was written and that skills pick it up on the next delegation,
no restart needed. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill,
or an existing harness). If not, offer once: "want a project-local verification skill, so
agents can drive the app the way a user does and prove changes work? I can generate one
with /skill:create-verification-skill." On yes, invoke that skill (resolves wherever
pstack-orca is installed). On no, move on without pushing.

### 8. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with /skill:create-formal-verification-skill." On yes, invoke that skill. On no, move on without pushing.
