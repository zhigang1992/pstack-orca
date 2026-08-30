---
name: reflect
description: Dispatch three parallel review workers over the active session, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
disable-model-invocation: true
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

## When to invoke

- The user said "reflect" or "/skill:reflect".
- A complex task (5+ tool calls) just landed cleanly and the recipe is worth keeping.
- The agent hit dead ends, found the working path, and the path generalizes.
- The user corrected the agent's approach mid-task.
- A non-trivial workflow emerged that isn't captured anywhere.

Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## Process

### 1. Locate the active session transcript

The parent finds its own session file before fanning out. In pi, `/session` prints the
current session file path; sessions live under `~/.pi/agent/sessions/`, organized per
working directory, one JSONL file per session. Stay inside the current working
directory's session folder. Do not glob across `~/.pi/agent/sessions/*/` wholesale; that
crosses workspace boundaries and reads private sessions from unrelated projects.

```bash
ls -t ~/.pi/agent/sessions/<this-workspace-dir>/*.jsonl 2>/dev/null | head -10
```

For each candidate, scan the first JSONL events for the conversation's opening user
prompt (pi's session JSONL is a tree of events; the session-format docs describe the
shape). Take the matching path. If no path resolves, write a tight digest of the session
and pass that instead. When the work happened in an Orca worker rather than the local
session, read it through `orca orchestration worker-read --dispatch <id> --json`.

### 2. Dispatch three reviewers in parallel

One Task per reviewer, all workers started before waiting. Reviewers need connector
access for context lookups (tickets, chat threads, observability traces referenced in
the session), so their briefs name the connectors available (`gh`, `lark-cli`, installed
skills) and forbid file writes; the parent applies edits.

| Lens | agent | Prompt template |
|---|---|---|
| Judgment | your configured reflect-judgment worker (default `claude`) | `references/judgment-reviewer.md` |
| Tooling | your configured reflect-tooling worker (default `codex`) | `references/tooling-reviewer.md` |
| Divergent | your configured reflect-judgment worker (default `claude`) | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the session path or digest where marked.
Reviewers report findings in their `worker_done` body.

### 3. Synthesize

Dispatch one synthesizer worker, your configured reflect-judgment worker (default
`claude`). The synthesizer's quality check includes spot-verifying citations, which can
require connector access. Use `references/synthesizer.md` verbatim, with each reviewer's
full output inlined where marked. The synthesizer returns a structured Accepted /
Rejected / Backlog list.

### 4. Structural enforcement check

Sanity-check the synthesizer's Accepted list. For any item that would be enforced more reliably by a lint rule, script, metadata flag, or runtime check, move it from Accepted to Backlog. The synthesizer already applies this criterion; this is a final pass before edits land. See the **encode-lessons-in-structure** principle skill.

### 5. Apply

Before applying any Accepted edit, present the synthesizer's full Accepted/Rejected/Backlog output to the user and wait for explicit approval. The user picks which subset to apply and may redirect routings. Skill changes affect every future agent in the org; do not auto-apply.

Backlog items file to whatever devex / backlog tracker your team uses automatically. Those are tracker submissions, not skill edits. Only the Accepted list waits for approval.

For each approved Accepted item, follow the Routing field exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): parent does directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): follow the **Authoring a skill** playbook (`../poteto-mode/playbooks/authoring-a-skill.md`) and run its draft / test / iterate loop.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): same playbook, its description-optimization loop.
- `new skill: <kebab-name>`: author it per the same playbook. pi discovers skills from `~/.pi/agent/skills/`, project `.pi/skills/`, or package `skills/` directories; place accordingly. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator (pi validates frontmatter on load and
warns), run it on every touched skill before declaring done. Skip this step if it doesn't.

### 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
