---
name: arena
description: "Spawn N parallel candidates at the same task, pick a base, graft the strongest parts of the losers into it. Use for /arena, 'arena this', 'throw it in the arena', or when one attempt at a non-trivial artifact would lock in the wrong shape."
disable-model-invocation: true
---

# Arena

Open a todolist with one entry per phase (Frame, Fan out, Cross-judge, Pick, Graft, Verify) before launching anything.

## Phase A: Frame

Every candidate gets the same prompt, so the prompt is the contract.

1. State the artifact each candidate is producing.
2. Derive the rubric, 3-6 concrete gradeable criteria for what success looks like on *this* task. It is the picker's tool in Phase D. Candidates only see the task.
3. Pick the runners. Use the `arena runners` line. First hit wins: project `.pstack-models.md`, then `~/.claude/rules/pstack-models.md`, then `~/.pi/agent/pstack-models.md`. If the line is missing, default to one Claude Code worker on each of `claude-fable-5-1`, `claude/claude-opus-5-5`, and `claude/claude-sonnet-5-5`. An `auto` or `inherit-parent` entry is this session, and it still counts as one seat. Launch every other entry as `--agent claude` with that entry's `--model`, the way the Workers section of **poteto-mode** says. Do not call `Task`. Do not pass `--agent codex`, `grok`, or `pi`. The short aliases `opus`, `sonnet`, and `haiku` are not distinct models. If a launch fails, drop that seat and say so. If fewer than two runners remain, add a missing model from those three, or run the missing seat in this session when none remain, and say so. Spawn more runners when the arena covers multiple design directions. Reuse one model N times only when the work is generation-bound rather than judgment-sensitive.
4. Give each candidate its own output location (a git worktree where possible, otherwise `/tmp/arena-<slug>/candidate-<n>/`), per the **separate-before-serializing-shared-state** principle skill.

## Phase B: Fan out

Spawn all N workers in one turn, each with the task, the path to the shared grounding, its own output path, and instructions to produce the artifact and a short rationale naming the alternatives it considered and what it rejected. A runner that is not this session is an Orca coding agent in its own Orca workspace (`--worktree new-top-level`).

If a candidate produces no output, proceed with N-1 and note the dropout.

## Phase C: Cross-judge

After all Phase B candidates complete, choose one model from the `arena cross-judge pool` line, same lookup as Phase A. If the line is missing, the pool is `claude-fable-5-1`, then `claude/claude-sonnet-5-5`, then `claude/claude-opus-5-5`, each launched as `--agent claude`. Spawn one read-only judge. The judge's model is never the parent's model. This session is usually the Magpie group, not one of these pins, so try fable first. An `auto` or `inherit-parent` entry is this session, so it never judges. If a launch fails, move to the next entry. If no other model launches, skip the judge, pick the base alone in Phase D, and say so. The judge sees the rubric and the candidates by path label, scores each criterion, and recommends a base with rationale. It runs in parallel with your reading in Phase D. Don't spawn it while candidates are still writing. Say read-only in the brief. There is no readonly flag.

## Phase D: Pick a base

Read every candidate end to end before picking. Score each against the rubric criterion by criterion, not on holistic feel, and compare with the cross-judge when Phase C ran one. Agreement on the base confirms the pick. Disagreement means one of you is biased or the rubric was ambiguous. Read both rationales before deciding.

Pick the base a future maintainer can extend most easily without breaking invariants. When two feel tied, prefer the cleaner boundary or smaller API, per the Laziness Protocol.

## Phase E: Graft

Walk each losing candidate once more for what is worth porting into the base, usually one or two things per candidate, not most of it. Fold each graft in by hand, per the **redesign-from-first-principles** principle skill, so the result stays coherent under one mental model. Don't paste mechanically.

If the candidates converge on one shape, that is strong agreement. Note it and ship the consensus shape. No graft is needed. If they wildly diverge, Phase A was under-specified. Reframe and re-run rather than averaging the divergence.

## Phase F: Verify

Verify the synthesized artifact like any other output, per the **prove-it-works** principle skill. If verification finds a problem the arena missed, either Phase A was wrong (re-frame and re-run) or a candidate caught it and you missed the graft (go back to Phase E). Don't paper over it.

## Outputs

One synthesized artifact, with a short synthesis note alongside naming the base and why, the cross-judge's verdict or that Phase C skipped the judge, each graft with its source candidate, what was rejected and why, any convergence or dropouts, and the verification result.
