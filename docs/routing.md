# Routing: Claude Code parent, Orca for a real second family

The primary harness is Claude Code. Orca is how a role leaves that process and runs on a different agent CLI. pi is one of those CLIs, not the parent.

Upstream pstack (https://github.com/cursor/plugins/tree/main/pstack) already installs in Claude Code and writes this same role file. Its Claude adapter then drops every non-Claude model slug onto the session model. That is the wrong behavior here. A role that names `codex`, `grok`, `pi`, `opencode`, `opencode2`, or `cursor` is an Orca worker, not a Claude model pin.

## Where the file is read

First hit wins. A role missing from all three keeps the skill's inline default.

1. Project `.pstack-models.md` at the repo root. Commit it when a repo's worker policy should travel with the code.
2. User `~/.claude/rules/pstack-models.md`. Claude Code loads every file in that directory into each new session, so the lines are already in context. Skills still read the file when they are about to dispatch, in case the session did not.
3. User `~/.pi/agent/pstack-models.md`. Legacy path from the pi port. Keep it identical to the Claude file, or delete it. Do not let the two disagree.

`/skill:setup-pstack` writes the Claude file by default and mirrors it to the pi path.

## What a value means

| Value | What runs |
|---|---|
| `inherit-parent`, `auto` | This session. No model pin. Do not spawn a Claude subagent just to pick opus, sonnet, or haiku. A panel entry still counts as one seat. |
| `codex`, `grok`, `pi`, `opencode`, `opencode2`, `cursor` | `orca orchestration worker-start --agent <id>`. Do not pass the word as a Claude `Agent` model. |
| `claude` | Not a second family. Treat it as `inherit-parent`. |
| `claude` with `--model claude-fable-5-1` | The one Claude pin that is not the failover group. Use it only on a line that names that model. |

Do not pass `--model` unless the line contains one. Never pass a Magpie group id (`group/never-stuck`, `magpie/group/never-stuck`) to an Orca worker. That hands the seat back to the parent's pool and the panel stops being a panel.

## Why Claude is not a family on this machine

Magpie sits in front of Claude Code. Orca's model catalog resolves `opus`, `sonnet`, and `haiku` to `group/never-stuck[1m]`. The group fails over, in one seat, across:

- `claude/claude-opus-5-5`
- `claude/claude-sonnet-5-5`
- `codex/gpt-6-astra` and `codex/gpt-6.1-sol`
- `grok/grok-4.7@500k`
- `cursor/grok-4.7@500k`
- `kimi/k3.1-pro`

Failover is one model at a time. It is not four models answering together. `fable` resolves to `claude-fable-5-1` and is the exception.

Orca agents actually discovered on this machine: `claude`, `codex`, `grok`, `pi`, `opencode`, `opencode2`. `cursor` and `kimi` have CLIs, and Orca's help text names `cursor`, but neither is in the local catalog until a launch succeeds. pi's own default model is the kimi seat. Do not add `cursor` to a panel until `orca agent launch --agent cursor` has worked once.

`--agent codex` launches Codex's own model list (GPT-6 and GPT-5.6), not the group. `--agent grok` launches native `grok-4.7`. Those two, plus pi, are the three families a panel can hold.

## The default

The parent thinks. A worker gets a brief. A panel is three families, and none of them is `claude`.

| Roles | Who | Why |
|---|---|---|
| judgment and prose, hardest tasks, how explainer, why synthesizer, reflect judgment | `inherit-parent` | The session is already the best member of the group. A second Claude process cannot leave it. |
| bug-fix, perf-issue, hillclimb, reflect tooling | `codex` | The Codex plan, spent on purpose, on work that is a spec to execute. |
| feature, refactoring, how explorer, why investigators, swarm workers | `grok` | Fast mechanical edits and bulk reads, concurrent with the parent. |
| how critics, arena runners, architect runners, interrogate reviewers | `codex, grok, pi` | One seat per family. List length is the fan-out. |
| arena cross-judge pool | `codex, pi, grok` | Same three. Codex is first because the parent is often already Grok via failover, and the judge must be a different family. |

`# budget: medium (high)` is the parent's effort. Workers use their CLI's own default unless the line adds `--effort`.
