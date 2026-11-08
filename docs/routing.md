# Routing: Claude Code, different models

The harness is Claude Code for the parent and for every worker. A worker is not a Codex, Grok, or pi process. Orca only starts another Claude Code terminal:

```bash
orca orchestration task-create --spec "<brief>" --json
orca orchestration worker-start --task <id> --worktree current --agent claude --model <slug> --json
```

Do not pass `--agent codex`, `grok`, `pi`, `opencode`, `opencode2`, or `cursor`. Do not call Claude Code `Task` with a model slug. Upstream's Claude adapter drops non-Claude slugs onto the session model.

## Where the worker sits

The agent decides. It does not ask.

| The task | Workspace |
|---|---|
| A straight change on this checkout, or a question that does not modify code and fits in this chat | `--worktree current` |
| Several angles at once, a second opinion, a parallel candidate, a verifier who is not the author, or work that would crowd or dirty this checkout | `--worktree new-child` |

Being a skill that sometimes explores (`how`, `why`, `teach`, `blast-radius`, `recall`) is not a reason to leave. A narrow question stays here. A child workspace hangs off this one. `--worktree new-top-level` is a sibling. Do not use it. The split per skill is in the Workers section of `skills/poteto-mode/SKILL.md`.

## Where the file is read

First hit wins. A role missing from all three keeps the skill's inline default.

1. Project `.pstack-models.md` at the repo root. Commit it when a repo's worker policy should travel with the code.
2. User `~/.claude/rules/pstack-models.md`. Claude Code loads every file in that directory into each new session. Skills still read the file when they are about to dispatch.
3. User `~/.pi/agent/pstack-models.md`. Legacy mirror. Keep it identical to the Claude file, or delete it.

`/skill:setup-pstack` writes the Claude file by default and mirrors it to the pi path.

## What a value means

| Value | What runs |
|---|---|
| `inherit-parent`, `auto` | This session. No extra worker. A panel entry still counts as one seat. |
| `claude --model <slug>` | An Orca worker, `--agent claude`, pinned to that model. |

Pass `--model` only when the line names one. Pass `--effort` only when the line names one.

The short aliases `opus`, `sonnet`, and `haiku` are not models on this machine. Orca's catalog resolves all three to `group/never-stuck[1m]`, one failover seat. Never pass those aliases, and never pass `group/never-stuck` or `magpie/group/never-stuck`.

Pins that resolve to themselves, and so stay distinct:

- `claude-fable-5-1`
- `claude/claude-opus-5-5`
- `claude/claude-sonnet-5-5`

A panel is three of those, not three harnesses. List length is the fan-out.

## The default

The parent session does judgment. A worker is another Claude Code on a pinned model.

| Roles | Who | Why |
|---|---|---|
| judgment and prose, how explainer, why synthesizer, reflect judgment | `inherit-parent` | This session already holds the decision. |
| hardest tasks | `claude --model claude-fable-5-1` | The pin that is not the failover group. |
| bug-fix, perf-issue, hillclimb, reflect tooling | `claude --model claude/claude-opus-5-5` | A pinned Opus, not the `opus` alias. |
| feature, refactoring, how explorer, why investigators, swarm workers | `claude --model claude/claude-sonnet-5-5` | The faster Claude model, still Claude Code. |
| how critics, arena runners, architect runners, interrogate reviewers | fable, Opus 5.5, Sonnet 5.5 | One seat per model. |
| arena cross-judge pool | fable, then Sonnet 5.5, then Opus 5.5 | Fable is first because this session is the group, not Fable. The judge skips the parent's model. |

`# budget: medium (high)` is the parent's effort. Workers use the pinned model's own default unless the line adds `--effort`.
