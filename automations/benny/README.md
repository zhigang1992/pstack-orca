# benny

benny gives you two orca automations for chat issue reports (slack or lark). one triages each report. the other reproduces confirmed bugs and may prepare a small draft fix.

the files in this directory are dormant setup and automation sources. they do not appear as registered skills.

## set it up

1. point your agent at [`FOR_AGENTS.md`](./FOR_AGENTS.md) and name the target repository.
2. let setup merge this whole directory into the target at `.orca/benny/`. it must preserve destination-only files and review conflicts instead of overwriting local edits.
3. let setup give the target repository access to pstack-orca's skills through its committed `.pi/settings.json` (a `skills` path entry or a project-scoped `pi install -l`) for shared dependencies such as `how`, `why`, `tdd`, `unslop`, and the principle skills.
4. keep user-owned configuration outside the copied pack, for example in `.benny/`. adapt [`configuration.example.yaml`](./templates/configuration.example.yaml) and [`feature-map.example.md`](./skills/reproduce-and-fix-issues/references/feature-map.example.md).
5. commit `.pi/settings.json`, `.orca/benny/`, and any secret-free configuration before enabling either automation.
6. create each automation with `orca automations create` (schedule, `--provider`, prompt per the setup checklist), review it with `orca automations show`, then send a harmless test report and verify every source-channel post stays in the original thread.
