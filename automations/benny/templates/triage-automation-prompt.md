# Triage automation prompt

> Source material for the copied setup workflow. Paraphrase this intent into the
> `--prompt` of `orca automations create` after confirming the copied pack is committed
> in the repository where the automation will run.

Read and follow `.orca/benny/skills/triage-issue-reports/SKILL.md` for this run.

Configuration source. Include this repository-relative path only when it is committed in the same target repository. Otherwise paraphrase the configured values. Never use a package cache path:

```text
{{BENNY_CONFIG_PATH}}
```

Trigger model: this automation runs on a schedule (`--trigger`, for example `*/15 * * * *`). Each run scans the configured source channel for new top-level reports since the last successful run, using the chat adapter's own read state or a watermark recorded under the configured state path. There is no event payload; the run discovers its work. Process each new report as an independent unit and keep its channel id and root thread timestamp immutable for the whole run. If the channel configuration is missing or uncertain, stop without posting or writing to the issue tracker.

The committed operational file owns classification, attachment review, cause tracing, routing, dedupe, tracker writes, and the final verdict. Post no progress messages. Never post a root message in the source channel.

The coordinator is the only channel poster. Any delegated orca worker must be read-only, return findings only, and receive an explicit ban on every chat write action.

End the single verdict with exactly one configured marker:

```text
[benny:bug]
[benny:performance]
[benny:other]
```

A bug or performance marker may add `tracker=<URL>`.
