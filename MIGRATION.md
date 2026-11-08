# Migration notes: pstack (Cursor) → pstack-orca (pi + Orca)

This file records how each Cursor mechanism in the original
[pstack](https://github.com/cursor/plugins/tree/main/pstack) was translated, and the
reasoning where the mapping is not one-to-one.

## Fit check

pstack's architecture is three layers, and they port unevenly:

1. **Content** (24 principles, 23 playbooks, skill bodies, writing rules). Harness
   agnostic. Ported verbatim except where the prose names a Cursor mechanism.
2. **Orchestration** (subagent fan-out, model panels, cloud workers, wake loops).
   Cursor-specific on the surface, but the *shape* maps cleanly onto Orca orchestration.
   This is where nearly all the edits are.
3. **Harness integration** (plugin manifest, rules files, `/loop`, `/goal`, MCP
   registry, transcript store, Cursor automations). No direct equivalent; each got an
   explicit substitution, listed below.

The fit is good. Cursor's differentiator for pstack was real subagents with model
selection and background execution. Orca's differentiator is *supervised* workers with
durable task provenance (`task-create` → `worker-start` → `worker_done`), which is
strictly more structure than pstack assumed. The orchestrate/autopilot playbooks, which
hand-built inbox/drain/liveness machinery over Cursor cloud agents, get part of that
from Orca for free.

## The mapping

| Cursor | pi + Orca | notes |
|---|---|---|
| `.cursor-plugin/plugin.json` | `package.json` with `pi.skills` / `pi.prompts`; install with `pi install <path\|git>` | pi auto-discovers `skills/` and `prompts/` convention directories too. |
| `/skill` slash commands | pi skills, `/skill:<name>` with `enableSkillCommands` | `/poteto-mode` also ships as a prompt template (`prompts/poteto-mode.md`) so the flagship keeps its bare `/poteto-mode` invocation. |
| `Task` subagent tool (`subagent_type`, `run_in_background`, `model`, `readonly`) | `orca orchestration run-create` → `task-create --spec` → `worker-start --task <id> --agent <cli> [--model] [--effort]` → `check --wait --types worker_done,escalation,question` | Workers are background by construction (own terminals). `readonly: true` has no Orca flag; the brief says report-only and is the enforcement. |
| `environment: "cloud"` cloud agents | a child Orca workspace (`--worktree new-child`), or `--on <environment>` on a paired remote. Never `new-top-level` | A straight change stays on `--worktree current`. Exploration and separate work become a child, and the agent decides. |
| `cloud_base_branch` | `--base-branch <ref>` on worktree creation | |
| `agents/poteto-agent.md`, `agents/comment-sicko.md` subagent types | `briefs/` directory: paste the brief into the worker's task spec | Orca has no subagent-type registry. The brief carries the same instruction (read poteto-mode in full first). |
| `~/.cursor/rules/pstack-models.mdc` (`alwaysApply: true`) | `~/.claude/rules/pstack-models.md`, which Claude Code loads every session, mirrored to `~/.pi/agent/pstack-models.md` | Upstream's Claude adapter writes the Cursor path, then drops non-Claude slugs onto the session model. This fork writes the Claude path. Every worker is `--agent claude` plus a full model id. See `docs/routing.md`. |
| Model slugs (`grok-4.7-xhigh-fast`, `claude-opus-5-5-xhigh`) and short aliases (`opus`, `sonnet`, `haiku`) | `claude --model <full id>`. Distinct pins: `claude-fable-5-1`, `claude/claude-opus-5-5`, `claude/claude-sonnet-5-5` | The short aliases resolve to `group/never-stuck`. Never pass them, and never pass `--agent codex`, `grok`, or `pi`. |
| `inherit-parent` / `auto` role aliases | same aliases; meaning changed to "run the role on the parent chat's own agent and model" | For singleton roles that means doing the step inline; for panels it counts toward fan-out as before. |
| MCP discovery (the `why` skill) | connector discovery at run time: installed pi skills (`lark-*` for chat/docs/tasks), CLIs (`gh`, `lark-cli`), MCP servers if the harness exposes them | The seven evidence categories and per-source playbooks are unchanged; they're explicitly example vocabularies adapted per connector. |
| Cursor transcripts (`~/.cursor/projects/<slug>/agent-transcripts/`) | Claude Code sessions (`~/.claude/projects/<slug>/*.jsonl`, slug keeps the leading dash) and `orca orchestration worker-read --dispatch <id>` for workers | Affects `recall`, `reflect`, `automate-me`, `session-pickup`, `eval`, `show-me-your-work`, and `scripts/worktree-audit.sh`. |
| `/loop` | rolling `orca orchestration check --wait --timeout-ms <n>` while the session is live; `orca automations create --trigger <cron> --prompt <text> --provider <agent>` when the operator steps away | Orca automations are the durable, survives-restart option; the rolling wait is the in-session option. |
| `/goal` (autopilot playbooks) | the Orca Run objective + the program's standing-orders file | Both are re-read at every audit tick, same contract as `/goal`. |
| "cloud-sleeper wake chain" (autopilot audits) | Orca automation on a 30-minute cron | |
| Cursor Bugbot / agentic security review | generic "review bots" | The skeptical-triage posture is unchanged. |
| Cursor built-in babysit skill | the pstack babysit playbook, unopposed | The port note telling you not to route to the built-in is gone. |
| Cursor built-in `create-skill` | the authoring-a-skill playbook, updated for pi's skill format and discovery paths | |
| `cursor-team-kit` (`deslop`, `control-ui`, `control-cli`) | `unslop` for prose; **ego-browser** for web UIs; the real CLI/TUI in a terminal for CLIs | `deslop` (code-level slop) has no shipped equivalent; `no-comments` plus an explicit ask covers most of it. |
| Cursor plan mode | dropped | The original README leaned on it; pstack's stance ("the best spec is code") needs no replacement. |
| `make-bot-ui` skill | shipped, and it still refuses outside Cursor | It depends on Cursor routines' webhook + sender-key flow. The skill says to skip on Claude Code and Orca rather than invent that API. |
| Cursor automations (benny pack, `.cursor/automations/`) | scheduled Orca automations; pack installs at `.orca/benny/`; Slack triggers become scheduled channel scans | The trigger model changes from event (new Slack message) to polling (every 15 minutes), because Orca automations are cron/RRULE-based. Lark via `lark-im` is the first-class chat adapter in this environment. |
| `.cursor/settings.json` plugin enable (benny) | `.pi/settings.json` `skills` entry or `pi install -l` | |
| Graphite (`gt`), `gh`, the watch-pr and orch scripts | unchanged | Harness-agnostic from the start. |

## Judgment calls worth reviewing

- **Workers over pi-native anything.** pi has no built-in subagent tool; under Orca the
  honest primitive is an Orca worker. All fan-out skills (`swarm`, `arena`, `how`,
  `why`, `interrogate`, `reflect`, `architect`) now speak `task-create` +
  `worker-start` + `check --wait`. If you later run pi outside Orca, those skills
  degrade to "do it inline" — the playbooks still read correctly, just without
  parallelism.
- **Agent ids as the default role values, not model slugs.** Cursor let pstack name
  exact models. Orca launches agent CLIs; `--model` is an optional opaque passthrough.
  Defaults therefore name agents, and `setup-pstack` validates launchability instead of
  model entitlement.
- **Benny's trigger became polling.** This is the one semantic regression: Cursor
  automations could fire on a new Slack message; Orca automations are scheduled. A
  15-minute scan keeps the same outcomes with bounded latency and is idempotent by
  watermark. If Orca later gains event triggers, only the two prompt templates and the
  setup checklist change.
- **`make-bot-ui` is present and still Cursor-only.** Its flow is Cursor routines.
  On Claude Code and Orca the skill skips instead of inventing a webhook. Recreating
  it needs an incoming-webhook surface Orca doesn't expose to automations today.

## Other harnesses

Claude Code, Codex, and Grok are first-class as Orca workers (the default role config
dispatches them), and the skills load in Claude Code and Codex as a primary harness too,
via the shared Agent Skills standard. See `docs/harnesses.md` for the worker vs primary
distinction, the per-harness session stores that `recall`/`reflect`/`automate-me` would
need, and `scripts/install-harnesses.sh` for symlinking the skills into
`~/.claude/skills/` and `~/.codex/skills/`.

## Verifying the port

```bash
# skills load and validate
pi install /path/to/pstack-orca -l   # in any project, then restart pi; check /skill: list

# worker loop smoke test
orca orchestration run-create --objective "pstack-orca smoke test" --json
orca orchestration task-create --spec "Reply with PASS and nothing else." --json
orca orchestration worker-start --task <task_id> --worktree current --agent pi --json
orca orchestration check --wait --types worker_done,escalation --timeout-ms 300000 --json
```
