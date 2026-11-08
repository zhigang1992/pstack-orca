---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
disable-model-invocation: true
---

# Swarm

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Pick the worker from the `swarm workers` line. First hit wins: project `.pstack-models.md`, then `~/.claude/rules/pstack-models.md`, then `~/.pi/agent/pstack-models.md`. If the line is missing, use `claude --model claude/claude-sonnet-5-5`. For `auto` or `inherit-parent`, this session does the work. Launch any other value as `--agent claude` the way the Workers section of **poteto-mode** says. Pass only the model that line names. If a launch fails, say so and run that seat in this session. For a model race, name each arm's model up front. All arms stay `--agent claude`.
4. Give each worker its own writable output when it writes. When workers verify or measure commits, each brief names the exact SHAs. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Spawn all N workers in one turn, on the step 3 agent. Each worker is an Orca coding agent in its own Orca workspace (`--worktree new-top-level`). Stay on `--worktree current` only when the worker must use this workspace's uncommitted state. There is no `environment: "cloud"` and no `cloud_base_branch`. Name a non-default branch in the brief, and the worker checks it out. Do not open a terminal yourself.

Every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. Drop a result that does not record the SHAs and method its brief names, and respawn that worker once. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

## Phase D: Report

Return one consolidated in-chat report with a result table, issue one-liners, gaps or dropouts, and the race rule when used.
