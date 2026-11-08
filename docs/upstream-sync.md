# Reapplying this fork onto upstream

Read this after copying a newer [cursor/plugins pstack](https://github.com/cursor/plugins/tree/main/pstack) tree over `skills/`. Upstream is the prose. This file is the list of behaviors that must not come back with it.

Take the new tree. Do not restore `skills/poteto-mode/scripts/orch/`. Upstream deleted those scripts and made Orchestrate a short playbook. Keep that. Then reapply the rows below. `docs/routing.md` is the contract the skills point at. `~/.claude/rules/pstack-models.md` is the live role file, and it is not in this repo, so a sync will not refresh it. Check it by hand.

## What upstream will put back

| Upstream says | This fork keeps |
|---|---|
| Write a generated skill to `.cursor/skills/` or `~/.cursor/skills/` | `.claude/skills/` or `~/.claude/skills/`. Claude Code does not load the Cursor directories. |
| Write `~/.cursor/rules/pstack-models.mdc` | `~/.claude/rules/pstack-models.md`, mirrored to `~/.pi/agent/pstack-models.md`. No frontmatter. |
| Read transcripts at `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.claude/projects/<slug>/*.jsonl`. The slug keeps the leading slash as a leading dash (`/Users/you/proj` becomes `-Users-you-proj`). |
| Spawn `Task` with `subagent_type` and a model slug | `orca orchestration worker-start --agent claude --model <full id>`. Never `--agent codex`, `grok`, `pi`, `opencode`, or `cursor`. |
| Default models `grok-4.7-xhigh-fast` and `claude-opus-5-5-xhigh`, or the short aliases `opus`, `sonnet`, `haiku` | Full ids only: `claude-fable-5-1`, `claude/claude-opus-5-5`, `claude/claude-sonnet-5-5`. The short aliases resolve to `group/never-stuck`, which is one failover seat, not three models. |
| `environment: "cloud"`, a Cursor cloud agent, `cloud_base_branch` | An Orca coding agent, `--agent claude`, in its own workspace: `--worktree new-top-level`. Do not open a terminal. Name a non-default branch in the brief. |
| `control-ui`, `control-cli`, `/deslop` from `cursor-team-kit` | That same Orca agent. ego-browser for a web UI, the agent itself for a CLI, `/unslop`, `/no-comments`. Do not install `cursor-team-kit`. |
| `make-bot-ui` calling `update_state` and `api2.cursor.sh` | On Claude Code, say `Skipped: make-bot-ui needs a Cursor webhook routine` and stop. Do not invent a webhook. |
| `subagent_type: "poteto-agent"` or `"comment-sicko"` | Paste `briefs/poteto-worker.md` or `briefs/comment-sicko.md` into the worker spec. |
| Cursor's `AskQuestion` and `create-skill` tools | Ask in this chat. Author a skill with `skills/poteto-mode/playbooks/authoring-a-skill.md`. |

A sentence that names a Cursor path only to forbid it is fine. A sentence that tells the agent to write or launch there is not.

## Files you replace, not merge

These are fork-owned. An upstream copy of the whole file will look plausible and be wrong.

- `skills/setup-pstack/SKILL.md`. It detects Claude model pins, not Cursor slugs, and writes the Claude rule.
- The Workers section of `skills/poteto-mode/SKILL.md`.
- `docs/routing.md`.

## Files you patch a paragraph

Dispatch and output paths. The rest of the file stays upstream.

- `skills/arena/SKILL.md`, `skills/architect/SKILL.md`, `skills/interrogate/SKILL.md`, `skills/swarm/SKILL.md`, `skills/how/SKILL.md`, `skills/why/SKILL.md`, `skills/reflect/SKILL.md`, `skills/no-comments/SKILL.md`
- `skills/create-verification-skill/SKILL.md`, `skills/maintain-verification-skill/SKILL.md`
- `skills/automate-me/SKILL.md`, `skills/recall/SKILL.md`
- `skills/poteto-mode/scripts/worktree-audit.sh`
- Playbook sentences that name a default model, `/deslop`, `control-ui`, `control-cli`, or a Cursor cloud VM: `feature`, `refactoring`, `bug-fix`, `perf-issue`, `hillclimb`, `multi-phase-plan`, `orchestrate`, `opening-a-pr`, `shipping`, `autopilot-full`
- The skip note at the top of `skills/make-bot-ui/SKILL.md` and the fork note at the top of `skills/poteto-help/SKILL.md`

## Check before you commit the sync

```bash
rg -n '\.cursor/skills|~/\.cursor/skills|\.pi/skills/verify' skills
rg -n 'pstack-models\.mdc|grok-4\.|claude-opus-5-5-xhigh|--agent (codex|grok|pi)\b' skills
rg -n 'control-ui|control-cli|/deslop|subagent_type|environment: "cloud"' skills
```

The first two should print only lines that say not to do the thing. The third should too, plus the skip note in `make-bot-ui`. A hit that tells the agent to write, launch, or install the Cursor form is a miss. Fix it before pushing.

Also confirm `~/.claude/rules/pstack-models.md` and `~/.pi/agent/pstack-models.md` still agree, and that neither line is a bare `codex`, `grok`, or `pi`.
