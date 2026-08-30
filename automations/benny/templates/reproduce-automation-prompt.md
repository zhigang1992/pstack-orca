# Reproduce automation prompt

> Source material for the copied setup workflow. Paraphrase this intent into the
> `--prompt` of `orca automations create` after confirming the copied pack is committed
> in the repository where the automation will run.

Read and follow `.orca/benny/skills/reproduce-and-fix-issues/SKILL.md` for this run.

Configuration source. Include this repository-relative path only when it is committed in the same target repository. Otherwise paraphrase the configured values. Never use a package cache path:

```text
{{BENNY_CONFIG_PATH}}
```

Trigger model: this automation runs on a schedule. Each run scans the configured source channel for reports carrying a configured triage marker (`[benny:bug]` or `[benny:performance]`) from the configured triage identity, posted since the last successful run, and picks up each as an independent unit. The prompt should name the configured repository, default branch, issue tracker, control adapter, feature map, and draft pull request capability. Keep the channel id and root thread timestamp immutable for the whole run. If either is missing or does not match configuration, stop without posting.

Require the configured control-adapter before attempting a repro. Reproduce the exact discriminating symptom twice through the real UI. Verify existing pull requests or commits without authoring over them. Attempt a bounded fix only after a confirmed repro and the operational file's fix gate.

The coordinator is the only channel poster. Every delegated orca worker's brief must forbid chat writes (`lark-cli im` send/reply commands, `chat.postMessage`, and all other channel writes). Workers return findings only.

Never post a root message in the source channel.
