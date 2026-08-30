---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
disable-model-invocation: true
---

# Swarm

Fan out N parallel Orca workers. They may cover separate slices, race the same brief, or mix both. The coordinator waits, aggregates, and returns one report.

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Set N from the user or derive it from the shape. N is total workers, not the cloud concurrency limit.
4. Pick the worker from `swarm workers` in `~/.pi/agent/pstack-models.md` when present. Otherwise use `grok`. For an agent race, name each arm's agent up front.
5. Give each worker its own writable output when it writes. Use an Orca worktree (`--worktree new-child --name <slug>`), a branch, or `/tmp/swarm-<slug>/worker-<n>/`.

## Phase B: Fan out

Create one Task per worker, then start every worker before waiting. Once per swarm, create the Run; then per worker:

```bash
orca orchestration task-create --spec "<standalone brief>" --json
orca orchestration worker-start --task <task_id> --worktree <placement> --agent <id> [--model <slug>] --json
```

Workers launch as fresh agent terminals. Use `--worktree current` when the worker reads your checkout as-is, a new worktree when it writes and could conflict, and `--on <environment>` when the work must run on another machine (the replacement for cloud workers: auth, simulators, or local state that lives elsewhere). When a worker must start from a non-default pushed branch, create its worktree with `--base-branch <ref>`.

Wait for the fleet to settle:

```bash
orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 900000 --json
```

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Process the `worker_done` deliveries. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps; `worker-read` a dispatch only when its report is unclear. Release each settled worker (`worker-release`) unless a follow-up task reuses its terminal.

Keep a compact result table, one-line evidenced issues, and explicit gaps or dropouts.

## Phase D: Report

Return one consolidated in-chat report with the table, issue one-liners, gaps or dropouts, and the race rule when used.
