# pstack-orca from other harnesses: Claude Code, Codex, Grok, and friends

pstack-orca is pi-flavored but not pi-locked. There are two ways the other coding
agents touch this repo, and they behave very differently.

## 1. As Orca workers (the common case)

This is the design center of the port. Every fan-out skill (`swarm`, `arena`, `how`,
`why`, `interrogate`, `reflect`, `architect`) dispatches workers through Orca, and the
default role config already spreads work across agent families:

```bash
orca orchestration worker-start --task <id> --worktree current --agent claude --json
orca orchestration worker-start --task <id> --worktree current --agent codex --json
orca orchestration worker-start --task <id> --worktree current --agent grok --json
```

The defaults mirror the original pstack's model split: `grok` for fast mechanical code,
`codex` for precisely-specified execution, `claude` for judgment and prose, `pi` as the
fourth panel family. `/skill:setup-pstack` detects which of these CLIs are actually
installed before letting you assign them to roles.

What a worker sees when it starts:

- **The dispatch brief is universal.** Every skill hands workers self-contained briefs,
  and the poteto style rides along via `briefs/poteto-worker.md`, which instructs the
  worker to read `skills/poteto-mode/SKILL.md` *by path*. That works for any agent that
  can read a file, no skill system required.
- **Skill discovery inside the worker is per-harness.** A claude worker only
  auto-discovers pstack's skills if they're visible to Claude Code (`~/.claude/skills/`,
  project `.claude/skills/`), a codex worker likewise (`~/.codex/skills/`). Grok has no
  documented skill discovery; brief-by-path is the only mechanism, which is fine for the
  mechanical-code role it fills. `scripts/install-harnesses.sh` symlinks the repo's
  skills into the claude and codex user skill directories.
- **`--model` / `--effort` passthrough is per-agent.** Orca documents these for Claude,
  Codex, and Cursor launches. pi and grok workers run their own configured default
  model; set it in that agent's own settings, not in pstack's config.

Nothing about the orchestration protocol itself is pi-specific. `worker_done`, `ask`,
heartbeats, and decision gates are `orca` CLI calls; any agent running in an Orca
terminal can make them.

## 2. As your primary harness (instead of pi)

If you sometimes drive Claude Code or Codex as the main agent in an Orca terminal, the
skills still load — pstack-orca follows the Agent Skills standard (a `SKILL.md` with
`name` + `description` frontmatter), which is the same standard Claude Code and Codex
consume.

```bash
./scripts/install-harnesses.sh
# symlinks skills/* into ~/.claude/skills/ and ~/.codex/skills/
# (--project <dir> for project scope: .claude/skills/ and .codex/skills/)
```

Each harness keeps its own invocation syntax (`/skill:name` is pi's; Claude Code lists
skills as its own slash commands). Asking for a skill by name works everywhere.

### What transfers cleanly

- All 21 principles and all 22 playbooks (pure prose).
- Every Orca mechanism: workers, dispatch, automations, worktrees, benny.
- `~/.pi/agent/pstack-models.md` is just a file the skills read by path. It's an odd
  home when pi isn't in the picture, but nothing breaks. Point the skills at any copy.

### What's pi-flavored today

Three skills mine agent history, and history lives in different places per harness:

| harness | sessions |
|---|---|
| pi | `~/.pi/agent/sessions/<--dir-slug-->/*.jsonl` |
| claude code | `~/.claude/projects/<dir-slug>/*.jsonl` |
| codex | `~/.codex/sessions/` |

`recall`, `reflect`, and `automate-me` name the pi path. Under another harness, point
them at that harness's session store — the mining logic (fan out workers over slices,
order by mtime, keep raw payloads out of the main thread) is unchanged. Likewise
`setup-pstack`'s step 7 references pi's skill locations when placing a new skill.

If running non-pi harnesses as primary becomes a regular pattern rather than an
exception, the honest fix is a small `harness:` note at the top of those three skills
with a path table like the one above, not a fork of the repo.

## A note on Cursor agents

`cursor-agent` is also launchable as an Orca worker (`--agent cursor`, with
`--model`/`--effort` support). If you still have Cursor installed, the *original*
pstack remains the better experience inside Cursor itself — this repo exists for
everything outside it.
