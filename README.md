# pstack-orca

[pstack](https://github.com/cursor/plugins/tree/main/pstack) is [poteto](https://x.com/poteto)'s
answer to AI slop: the skills she uses every day to ship high-quality code, turning one
agent into a real engineering team. This repository is **pstack ported from Cursor to
pi + Orca**. Same skills, same playbooks, same principles. The harness underneath is
different: skills load through pi, and every "subagent" runs as a supervised Orca worker.

the goal is not to maximize loc, in fact it's the opposite. pstack helps you write less,
but higher quality code.

**pstack gives you fearless parallelism.** when you can go deep on one agent and trust it
to write good, verifiable code, you can truly parallelize with confidence. start multiple
workers up with `poteto-mode` and trust that they'll apply rigorous engineering
principles to their work. under Orca those workers are real terminals with task
provenance and `worker_done` reporting, not fire-and-forget prompts.

fork it. improve it. make it yours. PRs are welcome!

## install

this is a pi package. install from git:

```bash
pi install git:github.com/zhigang1992/pstack-orca        # user scope
pi install git:github.com/zhigang1992/pstack-orca -l     # project scope (.pi/settings.json)
```

or from a checkout (`pi install /path/to/pstack-orca`), or by adding the checkout's
`skills/` directory to `~/.pi/agent/settings.json`:

```json
{ "skills": ["/path/to/pstack-orca/skills"] }
```

pi discovers every `skills/*/SKILL.md` recursively. enable skill commands in
`/settings` (`enableSkillCommands`) to invoke them as `/skill:<name>`.

## get started

two steps:

1. run [`/skill:setup-pstack`](./skills/setup-pstack/SKILL.md) and choose which agents
   and models your workers use.
2. use [`/poteto-mode`](./prompts/poteto-mode.md) (a prompt template that loads
   [`Poteto Mode`](./skills/poteto-mode/SKILL.md)) whenever you're doing anything that
   requires rigor.

new here? the [pstack guide](./docs/guide/README.md) walks you through a first real
task, from setup and prompting through verification and overnight runs.

that's it. the other skills are situational; the mode skill uses them for you as needed.
out of the box the mode splits work by agent strength: precisely-specified code goes to
`codex`, fast mechanical code goes to `grok`, prose and judgment go to `claude`, and `pi`
rounds out the review panels. [`/skill:setup-pstack`](./skills/setup-pstack/SKILL.md)
changes any of it.

## how the port works

| cursor | pi + orca |
|---|---|
| plugin (`.cursor-plugin/plugin.json`) | pi package (`package.json`, `pi install`) |
| `/skill` slash skills | pi skills, invoked as `/skill:<name>`; `/poteto-mode` ships as a prompt template |
| `Task` subagents (`subagent_type`, `run_in_background`, model) | `orca orchestration` workers: `task-create` → `worker-start --agent <cli> [--model <m>]` → `check --wait` for `worker_done` |
| cloud subagents (`environment: "cloud"`) | workers in fresh Orca worktrees, or `--on <environment>` on a paired remote Orca server |
| `poteto-agent` / Comment Sicko subagent types | dispatch briefs in [`briefs/`](./briefs/), pasted into the worker's task spec |
| `~/.cursor/rules/pstack-models.mdc` | `~/.pi/agent/pstack-models.md`, read explicitly by the skills at delegation time |
| cursor MCPs (the `why` skill) | connector discovery at run time: installed skills (`lark-*`), CLIs (`gh`, `lark-cli`), MCP servers if your harness has them |
| cursor transcripts (`agent-transcripts/`) | pi sessions (`~/.pi/agent/sessions/`) and `orca orchestration worker-read` |
| cursor `/loop` | rolling `orca orchestration check --wait`, or scheduled `orca automations create` |
| cursor automations (benny) | scheduled Orca automations; the [benny pack](./automations/benny/) installs at `.orca/benny/` |
| `cursor-team-kit` (`deslop`, `control-ui`, `control-cli`) | `unslop` covers prose; real-surface driving uses **ego-browser** (web) and the real CLI/TUI in a terminal |
| cursor built-ins (`create-skill`, babysit, plan mode) | the [authoring-a-skill playbook](./skills/poteto-mode/playbooks/authoring-a-skill.md) and the [babysit playbook](./skills/poteto-mode/playbooks/babysit.md) |

[`MIGRATION.md`](./MIGRATION.md) has the full mapping and the reasoning behind each call. [`docs/harnesses.md`](./docs/harnesses.md) covers running pstack-orca from Claude Code, Codex, and Grok — as Orca workers (first-class, that's the multi-model design) and as your primary harness instead of pi (`./scripts/install-harnesses.sh` symlinks the skills into `~/.claude/skills/` and `~/.codex/skills/`).

## usage

use [`/poteto-mode`](./prompts/poteto-mode.md) at the start of a task. it reads your
request, picks from a set of playbooks, and runs the other skills as the steps need them.

### just use `/poteto-mode`

this skill is the main shortcut. i use it whenever i need the agent to do rigorous
engineering work. it comes with twenty-two playbooks:

```
/poteto-mode this pr has a subtle bug where the scroll drifts every 750ms even when idle. repro
first, then fix and verify.
```

```
/poteto-mode i'm going to bed. land the stack even if ci flakes. i want everything merged by
morning.
```

<details>
<summary>the twenty-two playbooks</summary>

| playbook | for |
|---|---|
| [investigation](./skills/poteto-mode/playbooks/investigation.md) | a read-only question. how does x work, why was y built this way, are we sure. |
| [bug fix](./skills/poteto-mode/playbooks/bug-fix.md) | reproduce a defect, root-cause it, and fix with runtime evidence. |
| [perf](./skills/poteto-mode/playbooks/perf-issue.md) | trace a measured slowness and improve it against a baseline. |
| [hillclimb](./skills/poteto-mode/playbooks/hillclimb.md) | sustained, scientific improvement of one metric against a target, looping hypotheses with before/after measurement and one commit per accepted win. |
| [runtime forensics](./skills/poteto-mode/playbooks/runtime-forensics.md) | diagnose a live symptom (leak, idle-cpu spin, glitch) from instrumentation. |
| [trace forensics](./skills/poteto-mode/playbooks/trace-forensics.md) | diagnose a captured profiling artifact (cpuprofile, trace, spindump, heap snapshot). |
| [feature](./skills/poteto-mode/playbooks/feature.md) | new or changed behavior, built from a named data shape. |
| [refactoring](./skills/poteto-mode/playbooks/refactoring.md) | a behavior-preserving change to structure or shape. |
| [prototype](./skills/poteto-mode/playbooks/prototype.md) | a throwaway sketch to make a design or behavioral decision cheaply, or to settle an empirical fork by observing it. |
| [visual parity](./skills/poteto-mode/playbooks/visual-parity.md) | pixel-exact ui equivalence between two implementations. |
| [authoring a skill](./skills/poteto-mode/playbooks/authoring-a-skill.md) | writing or editing a SKILL.md. |
| [eval](./skills/poteto-mode/playbooks/eval.md) | test how a skill or prompt change affects agent behavior, blinded. |
| [babysit](./skills/poteto-mode/playbooks/babysit.md) | drive a pr or a stack to merge-ready: conflicts, review threads, ci. |
| [shipping](./skills/poteto-mode/playbooks/shipping.md) | independently verify a green stack, then land the contiguous verified run with graphite merge-when-ready. |
| [autonomous run](./skills/poteto-mode/playbooks/autonomous-run.md) | drive a long task to completion without stopping. |
| [orchestrate](./skills/poteto-mode/playbooks/orchestrate.md) | a standing project handed to one coordinator chat: multi-day, many stacked prs, fleets of workers. |
| [autopilot-full](./skills/poteto-mode/playbooks/autopilot-full.md) | run independent prs to merged with one owner per pr and root verification of each merge-ready head. |
| [autopilot-stack](./skills/poteto-mode/playbooks/autopilot-stack.md) | build and verify one linear graphite stack for the operator to review and land. |
| [session pickup](./skills/poteto-mode/playbooks/session-pickup.md) | resume or take over a prior agent's in-flight work. |
| [pause safely](./skills/poteto-mode/playbooks/pause-safely.md) | suspend in-flight work cleanly so it can be resumed later. |
| [multi-phase plan](./skills/poteto-mode/playbooks/multi-phase-plan.md) | work that spans phases or stacked PRs. |
| [worktree cleanup](./skills/poteto-mode/playbooks/worktree-cleanup.md) | reclaim disk by pruning merged or abandoned worktrees and stale ios simulators, safety-gated. |

</details>

when invoked it:

1. opens a todo list. the first item is reading the inline principles index in the skill.
2. matches your task to a [playbook](./skills/poteto-mode/playbooks/) and copies the
   steps in verbatim.
3. routes to the other skills as the steps fire.
4. writes unslopped replies framed for the consumer and the maintainer.

the full rules and playbooks live in
[`skills/poteto-mode/SKILL.md`](./skills/poteto-mode/SKILL.md).

`/poteto-mode` is also a sticky mode: once entered it stays on across turns, applying
itself when a playbook matches or the task needs rigor and staying out of the way
otherwise. opt out any time by saying so.

`/poteto-mode` works extremely well with long-running Orca setups: the autonomous
playbooks hold their cadence with rolling `check --wait` loops or scheduled Orca
automations, so a coordinator can run for many hours without sacrificing rigor.

## skills

`/poteto-mode` runs most of these for you when a step needs them (`how`, `why`,
`architect`, `arena`, `swarm`, `interrogate`, `unslop`, `no-comments`,
`technical-writing`, `tdd`, and the principles). the table below is for when you want
one directly. invoke as `/skill:<name>` or just ask for it by name:

```
/skill:how do we cancel runs? do we have an n+1 when we look up every run to cancel?
```

```
/skill:interrogate review this pr.
```

<details>
<summary>all skills</summary>

| skill | use it when |
|---|---|
| [`poteto-mode`](./skills/poteto-mode/SKILL.md) | default entry point for any non-trivial task. |
| [`how`](./skills/how/SKILL.md) | you want a walkthrough of how a subsystem works. |
| [`why`](./skills/why/SKILL.md) | you want to know why something was built this way. discovers available connectors at run time and queries each evidence category in parallel (source control, issue tracker, long-form docs, real-time chat, infra observability, error tracking, analytics warehouse). |
| [`recall`](./skills/recall/SKILL.md) | you're starting or resuming work and want your recent context on a topic rebuilt from your own session history and the shared record, handed back as a tight current-state brief. |
| [`blast-radius`](./skills/blast-radius/SKILL.md) | you have a small-looking change and want to know what else it could break, with the one fact it's safe because of proven by running code, not asserted. |
| [`architect`](./skills/architect/SKILL.md) | you're about to write code that crosses a function boundary and want the caller's usage, types, and module shape settled first. |
| [`arena`](./skills/arena/SKILL.md) | you want N parallel attempts at the same thing, then to grab the best parts of each. |
| [`swarm`](./skills/swarm/SKILL.md) | you want N parallel workers across different slices or races, then one aggregated report. |
| [`interrogate`](./skills/interrogate/SKILL.md) | you have a diff and want several different agent families to try to break it, including a strict code-quality lens. |
| [`automate-me`](./skills/automate-me/SKILL.md) | you want your own `-mode` skill, drafted from how you've actually worked. |
| [`setup-pstack`](./skills/setup-pstack/SKILL.md) | you want to pick which agents and models pstack uses per role. detects your agents and writes a config file. |
| [`reflect`](./skills/reflect/SKILL.md) | a long task landed and you want the recipe captured as a skill edit. |
| [`teach`](./skills/teach/SKILL.md) | you want to actually understand a change or subsystem, not just have it summarized. runs how + why and weaves one plain explanation, built up diagram by diagram. |
| [`tdd`](./skills/tdd/SKILL.md) | you're fixing a bug and there's a cheap local test path. write the failing test first, then the fix. |
| [`no-comments`](./skills/no-comments/SKILL.md) | strip comments before review; dispatches Comment Sicko, fixes accepted findings, offers encodings for claimed constraints. |
| [`typescript-best-practices`](./skills/typescript-best-practices/SKILL.md) | you're reading or editing typescript. grounds the type-system-discipline principle in syntax. |
| [`figure-it-out`](./skills/figure-it-out/SKILL.md) | no bundled playbook fits. designs a rigorous, auditable playbook for the task. |
| [`show-me-your-work`](./skills/show-me-your-work/SKILL.md) | you want a reviewable decision trail. logs decisions to a tsv you can commit. |
| [`create-verification-skill`](./skills/create-verification-skill/SKILL.md) | your project has no scripted way to prove app behavior. generates a project-local verify skill with a feature map, for any language or platform. |
| [`maintain-verification-skill`](./skills/maintain-verification-skill/SKILL.md) | your verify skill's feature map has drifted from the app. source wave + one live pass, at most one PR of proven corrections. |
| [`unslop`](./skills/unslop/SKILL.md) | you're cleaning up writing. removes AI tells. |
| [`bro`](./skills/bro/SKILL.md) | you want the last message restated in plain human language, no jargon. |
| [`technical-writing`](./skills/technical-writing/SKILL.md) | layered doc standard (Diátaxis + Google developer style + STE + Global English) for docs, RFCs, readmes, PR descriptions, commit messages. |

</details>

### examples

mostly i type `/poteto-mode` at the start of a task and let it route to a playbook. the
other skills fire as the steps need them. a few i reach for directly.

<details>
<summary>all the examples</summary>

```
bug fix:           /poteto-mode this pr has a subtle bug where the scroll drifts every 750ms even
                   when idle. repro first, then fix and verify.
perf:              /poteto-mode a big list takes a second or two to load even though we virtualize.
                   run a cpu trace and tell me why.
feature:           /poteto-mode build a small feature behind a feature flag. verify it really works.
prototype:         /poteto-mode build two prototypes of the markdown renderer so we can compare.
                   dispatch a worker for each.
multi-phase:       /poteto-mode open source these skills as a package. nothing internal leaks, work
                   in a temp dir, show me the dependency graph first.
overnight run:     /poteto-mode i'm going to bed. land the stack even if ci flakes. i want
                   everything merged by morning.
babysit:           /poteto-mode check on pr 123. anything outstanding?
visual parity:     /poteto-mode the row spacing is too tall when this flag is on. the second image
                   is correct. repro and fix until it matches.
figure it out:     /poteto-mode i'm stepping away. migrate every caller from the synchronous store
                   to the new async one, keeping behavior identical. i want to trust it was done
                   right when i'm back.
how:               /skill:how do we cancel runs? do we have an n+1 when we look up every run to cancel?
why:               /skill:why is this feature flag not on yet?
architect:         design this instrumentation to be high signal with no false positives. /skill:architect
                   this first.
arena:             /skill:arena take my prompt to the arena verbatim. i want to compare their proposals
                   with yours.
swarm:             /skill:swarm check every package under packages/ against its check.sh. one worker per
                   package. one report.
interrogate:       /skill:interrogate review this pr.
tdd:               /skill:tdd implement
unslop:            can we unslop and tighten the new changes?
reflect:           /skill:reflect that took too long. capture what we learned so the next run doesn't
                   repeat it.
show-me-your-work: /skill:show-me-your-work keep a decision trail i can review when i'm back.
automate-me:       /skill:automate-me
```

</details>

## the poteto worker and Comment Sicko briefs

Orca has no subagent-type registry, so the Cursor subagents became **dispatch briefs**
in [`briefs/`](./briefs/). when a playbook says to spawn a `poteto-agent`, paste
[`briefs/poteto-worker.md`](./briefs/poteto-worker.md)'s block into the worker's task
spec. it makes the worker read `poteto-mode` in full, including its inline principles
index, before doing any work. a plain worker without the brief drifts.

[Comment Sicko](./briefs/comment-sicko.md) is a read-only comment reviewer dispatched the
same way, usually through [`/skill:no-comments`](./skills/no-comments/SKILL.md), not
directly.

## principles

twenty-one short skills, one principle each. `poteto-mode` indexes them inline and reads
that index at task start. the standalone files are there so other skills can reference a
principle by name, and so the index can point at the full rule for each.

<details>
<summary>all twenty-one principles</summary>

| principle | group | rule |
|---|---|---|
| [laziness-protocol](./skills/principle-laziness-protocol/SKILL.md) | core | Bias toward deletion and the smallest change that solves the problem. |
| [foundational-thinking](./skills/principle-foundational-thinking/SKILL.md) | core | Apply before writing logic: choosing core types and data structures, sequencing scaffold-vs-feature work, asking what concurrent actors share. Get the data structures right so downstream code becomes obvious. |
| [redesign-from-first-principles](./skills/principle-redesign-from-first-principles/SKILL.md) | core | Redesign as if the requirement had been a foundational assumption from day one, instead of bolting it on. |
| [subtract-before-you-add](./skills/principle-subtract-before-you-add/SKILL.md) | core | Remove dead weight, redundant validators, and stub references first, then build on the simpler base. |
| [minimize-reader-load](./skills/principle-minimize-reader-load/SKILL.md) | core | Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope. |
| [outcome-oriented-execution](./skills/principle-outcome-oriented-execution/SKILL.md) | core | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture; don't preserve smooth intermediate states with throwaway compatibility code. |
| [experience-first](./skills/principle-experience-first/SKILL.md) | core | Choose user delight over implementation convenience; ship fewer polished features over more rough ones. |
| [exhaust-the-design-space](./skills/principle-exhaust-the-design-space/SKILL.md) | core | Build 2-3 competing prototypes and compare side by side before committing. |
| [build-the-lever](./skills/principle-build-the-lever/SKILL.md) | core | Apply to any non-trivial work, not just bulk work: edits, migrations, analyses, checks. Build the tool that does it or proves it (codemod, script, generator, or a skill your workers follow) instead of working by hand. The tool is the artifact a reviewer can rerun. |
| [model-the-domain](./skills/principle-model-the-domain/SKILL.md) | architecture | Encode the domain in a structure instead of scattered conditionals. |
| [boundary-discipline](./skills/principle-boundary-discipline/SKILL.md) | architecture | Concentrate guards at system boundaries (CLI, config, network, external APIs); trust internal types and keep business logic in pure functions. |
| [type-system-discipline](./skills/principle-type-system-discipline/SKILL.md) | architecture | Make illegal states unrepresentable, brand semantic primitives, parse external data at boundaries, refuse to lie to the compiler, exhaust variants, derive from authoritative schemas. |
| [make-operations-idempotent](./skills/principle-make-operations-idempotent/SKILL.md) | architecture | Converge to the same end state regardless of partial prior runs. |
| [migrate-callers-then-delete-legacy-apis](./skills/principle-migrate-callers-then-delete-legacy-apis/SKILL.md) | architecture | Migrate callers and delete the old API in the same wave instead of preserving compatibility layers. |
| [separate-before-serializing-shared-state](./skills/principle-separate-before-serializing-shared-state/SKILL.md) | architecture | Eliminate the sharing first; serialize structurally only when one shared writer is a real invariant. |
| [prove-it-works](./skills/principle-prove-it-works/SKILL.md) | verification | Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.'. |
| [fix-root-causes](./skills/principle-fix-root-causes/SKILL.md) | verification | Trace each symptom to its root cause and fix it there; reproduce first, ask why until you reach it, resist nil-check guards that silence crashes. |
| [sequence-verifiable-units](./skills/principle-sequence-verifiable-units/SKILL.md) | verification | Apply to multi-step work (sweeps, migrations, runs of similar edits) and to how you stack commits and PRs. Break work into small units that each end in a verifiable state, check each before the next, and order delivery so the sequence proves itself to a reviewer. |
| [guard-the-context-window](./skills/principle-guard-the-context-window/SKILL.md) | delegation | Route bulk to workers; keep summaries in the main thread, not raw payloads. |
| [never-block-on-the-human](./skills/principle-never-block-on-the-human/SKILL.md) | delegation | Proceed, present the result, let the human course-correct after the fact; reserve confirmation for irreversible actions. |
| [encode-lessons-in-structure](./skills/principle-encode-lessons-in-structure/SKILL.md) | meta | Encode the rule as a lint, metadata flag, runtime check, or script instead of more text. |

</details>

## not ported

a few things the original pstack references don't carry over:

- `deslop`, `control-cli`, and `control-ui` ship in Cursor's `cursor-team-kit` plugin.
  here, `unslop` covers prose cleanup, and real-surface driving goes through the
  **ego-browser** skill (web UIs) or the real CLI/TUI in a terminal.
- `/create-skill` is a Cursor built-in. the [authoring-a-skill
  playbook](./skills/poteto-mode/playbooks/authoring-a-skill.md) owns skill authoring
  here.
- `make-bot-ui` depended on Cursor routines and their webhook sender-key flow. Orca
  automations are schedule-triggered, so the skill was dropped rather than half-ported.
- Cursor's `/goal`, `/loop`, plan mode, and built-in babysit have no pi equivalent; the
  playbooks that used them now hold state in the Orca Run objective + standing orders
  and keep cadence with `check --wait` loops or `orca automations`.

## why are there no planning skills?

personally, i don't believe in planning. the best spec is code. if you do want to make a
plan, `/poteto-mode` covers it, but it's not a default.

## configuration: yours, your team's, or nobody's

pstack-orca ships **zero user configuration**. nothing in this repo names your models,
your plans, or your paths, so a published copy is safe as-is. the role-to-worker mapping
is layered, most specific first:

1. **project** `.pstack-models.md` at the repo root. per-project and per-use-case; commit
   it to share a team's worker policy with the code it applies to.
2. **user** `~/.pi/agent/pstack-models.md`. your defaults across every project.
3. **skill inline defaults.** `grok` / `codex` / `claude` / `pi`, mirroring the original
   pstack's split of fast mechanical, precise execution, judgment, and a fourth panel
   family.

a role set in the project file beats the user file; a role absent from both keeps the
skill default. [`/skill:setup-pstack`](./skills/setup-pstack/SKILL.md) writes either scope
after detecting which agent CLIs Orca can actually launch on the machine.

two properties make this portable:

- **config values are agent ids, not model slugs.** agents run their own configured
  default model (a pi worker inherits pi's default model), so model and plan choices
  stay in each user's harness where they belong. `--model` exists only as an optional
  passthrough for the agents Orca documents it for.
- **`inherit-parent` / `auto` is a first-class value.** a user with a single agent (one
  plan, one CLI) sets roles to `inherit-parent` and the whole system still works; panels
  just lose their cross-family signal, which the skills say out loud instead of hiding.

## make it yours

`poteto-mode` is poteto's style. you may not want exactly that.

type [`/skill:automate-me`](./skills/automate-me/SKILL.md). it mines your recent pi
sessions, drafts a `<your-name>-mode` skill from how you've actually worked, and routes
through pstack underneath. you keep pstack as the base and end up with your own routing
skill alongside `poteto-mode`.

type [`/skill:setup-pstack`](./skills/setup-pstack/SKILL.md) to configure agents. it
detects the agent CLIs Orca can launch and writes the config file for the scope you pick
(project or user). every skill reads it and falls back to sensible defaults when it's
absent, so you override only what you want.

## automations

pstack-orca also ships a dormant [benny automation pack](./automations/benny/). benny
triages chat issue reports (slack or lark), then reproduces and fixes confirmed bugs
with real ui evidence. its files are not registered as skills.

to set it up, point your agent at [`FOR_AGENTS.md`](./automations/benny/FOR_AGENTS.md).
setup copies the pack into the target repository at `.orca/benny/`, enables pstack there
for shared skills, creates the two scheduled Orca automations, and keeps user
configuration outside the copied pack.

## license

MIT
