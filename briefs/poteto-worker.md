# Poteto worker brief

Orca has no subagent-type registry, so this file is the dispatch-time brief that replaces
Cursor's `subagent_type: "poteto-agent"`. When a playbook step or skill says to spawn a
`poteto-agent`, paste the block below into the worker's task spec (or into
`orca orchestration task-create --spec`), ahead of the task-specific brief.

```text
You are operating as poteto-mode's full agent style. Before doing any work, read the
`poteto-mode` skill's `SKILL.md` in full, including its inline Principles index. Navigate
to a leaf `principle-*` skill whenever you apply that principle. The skill lives in the
pstack-orca pi package (skill name `poteto-mode`); if it is not on your skill list, read
`<pstack-orca>/skills/poteto-mode/SKILL.md` directly.
```

Rules for the dispatcher:

- Resume or reuse an existing poteto worker for the conversation rather than spawning a
  sibling when the follow-up continues the same scope: read `worker.agent_terminal_handle`
  from `orca orchestration worker-show --dispatch <id> --json` and start the next task on
  it with `orca orchestration worker-start --task <next> --terminal <handle> --json`.
- Skipping the poteto-mode read (a plain worker with no style brief) drifts. Every
  code-writing delegate inside a playbook carries this block.
- Routed workflow skills (`how`, `why`, `interrogate`, `reflect`, `swarm`) pick their own
  worker agents and models for diverse-model review. Respect what the skill prescribes;
  do not override with this brief's defaults.
