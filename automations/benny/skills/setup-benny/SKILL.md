---
name: setup-benny
description: Configure Benny and prepare its triage and repro Orca automations. Use when installing Benny or changing its chat channel, tracker, repository, routing, control, agent, or budget settings.
disable-model-invocation: true
---

# Set up Benny

Benny ships as a dormant automation pack inside pstack-orca. This file and the two
operational files are not registered skills; the automation prompts read them by path.

The human enters setup by pointing their agent at the pack's `FOR_AGENTS.md`. The
bootstrap flow copies the whole pack into the target repository, then reads this file
directly at `.orca/benny/skills/setup-benny/SKILL.md`.

Benny needs external configuration and two live Orca automations.

Do not create or update an automation until the user explicitly asks. Never put a secret
value in pack files, prompts, or committed configuration.

## 1. Copy the pack and enable shared pstack skills

Do this before asking for Benny configuration and before running `orca automations create`.

Ask which repository will run the automations. The source pack is the directory containing `FOR_AGENTS.md`. The destination is `<target-repository>/.orca/benny/`.

Merge the entire source pack into the destination:

1. Create the destination when it is absent.
2. Copy every source file to the same relative path.
3. Preserve destination-only files. Never delete unrelated files during install or refresh.
4. Keep user-owned configuration, feature maps, and routing maps outside the destination. Never overwrite them.
5. When an existing source-managed file differs, inspect the diff and merge without discarding local edits. If ownership is ambiguous, stop and ask before replacing it.
6. Verify that the destination contains `FOR_AGENTS.md`, this setup file, both operational files, their references, and the templates.

If this file is already being read from the target destination, treat the copy as complete and run the same verification before continuing.

Give the target repository access to pstack-orca's skills. Either add a `skills` entry to
the target's `.pi/settings.json` pointing at the pstack-orca checkout's `skills/`
directory (absolute path), or run `pi install <pstack-orca path or git URL> -l` for a
project-scoped package install. Create `.pi/settings.json` when absent, preserve every
unrelated setting, and validate the JSON after editing.

Start a fresh agent rooted in the target repository. Verify that these shared pstack skills resolve from project scope:

- `how`
- `why`
- `tdd`
- `unslop`
- `principle-separate-before-serializing-shared-state`
- `principle-minimize-reader-load`
- `principle-guard-the-context-window`
- `principle-sequence-verifiable-units`
- `principle-fix-root-causes`
- `principle-prove-it-works`

Do not count a skill loaded from the current session or a user-scoped install. The check must show that a fresh agent in the target repository receives pstack through project settings.

If project-scoped skills are unavailable or any shared dependency does not resolve, stop and explain the failure.

The Benny files are read directly from `.orca/benny/`. Do not add that directory to a package manifest or expect its `SKILL.md` files to appear in the skill list.

Tell the user that `.pi/settings.json`, `.orca/benny/`, and any referenced secret-free configuration must be committed before either automation is enabled. Do not commit them unless the user asks.

Once this check passes, live automation prompts may read the committed operational files by their stable repository-relative paths. They must not embed a package cache path or copy the file contents.

## 2. Adapt the configuration

Open these copied examples:

- `../../templates/configuration.example.yaml`
- `../reproduce-and-fix-issues/references/feature-map.example.md`

Create user-owned copies outside `.orca/benny/`. These are configuration files, not pack files. Example locations:

- Project config, such as `.benny/configuration.yaml`
- Project feature map, such as `.benny/feature-map.md`
- Project routing map, such as `.benny/routing.md`
- User config, such as `~/.config/benny/configuration.yaml`
- User feature map, such as `~/.config/benny/feature-map.md`

Fill one feature-map section for every user-facing feature the automation may reproduce. Keep it at the user point of view. Do not freeze implementation details or current code paths in the map.

Do not edit the copied examples. Pack refreshes may update source-managed files after conflict review, but they must never touch the user-owned copies.

Prefer committed, secret-free files in the target repository when a fresh automation run must read them. Otherwise paraphrase the required values into the live prompt. Reference a repository file only after confirming it is committed in the repository where the automation runs.

Use stable repository-relative paths for committed pack and configuration files. Never reference a package source directory or cache path from a live automation.

## 3. Fill the required choices

Ask for or confirm:

- Source chat channel ID (Slack or Lark)
- Optional operations or status channel ID
- Repository URL and default branch
- Triage identity or chat user ID
- Issue tracker type, team, project, labels, and intake status
- Tracker adapter (a skill, CLI, or MCP actions)
- Optional routing map path
- Required control adapter (ego-browser for web UIs, the real CLI harness otherwise)
- Required user-facing feature-map path
- Status emoji strings
- Pull request URL format
- Polling and effort budgets
- Agent (`--provider`) for triage, repro, code work, and media review

Use only agent ids launchable on this machine (`command -v pi claude codex grok ...`). Do
not guess an id and do not carry over a private default. Leave model selection to each
agent's own default unless the user names a model they have confirmed.

The source channel, triage identity, repository, tracker adapter, control adapter, and feature map must be explicit. Fail setup if any required value stays ambiguous.

Use pstack's `unslop` skill on the final automation names, descriptions, and prompt shims before saving them.

## 4. Check integration capabilities

The triage automation needs:

- Read access to the configured source channel and its threads (`lark-im` for Lark, the configured Slack adapter otherwise)
- Thread-reply access in that channel
- Attachment metadata and file download access when reports include media
- Search, read, create, and update access through the configured issue-tracker adapter

The repro automation needs:

- Read access to the source thread
- Thread-reply access in the source channel
- Optional post and edit access in the configured operations channel
- Repository read and history access
- A pull request action that can open a draft pull request (`gh pr create --draft`)
- The configured control adapter

Prefer the configured chat adapter's own actions for reads and posts. The optional `BENNY_SLACK_BOT_TOKEN` (or Lark equivalent) may fill a narrow gap such as editing one operations status message or downloading an attachment. Store the value in a secret manager or environment, not in YAML.

Do not use undocumented integration endpoints.

## 5. Prepare the routing map

If the user wants reroutes or owner pings:

1. Copy `../triage-issue-reports/references/routing.example.md` outside `.orca/benny/`.
2. Replace every placeholder with public or organization-local values.
3. Keep owner pings off by default.
4. Allow a ping only for a configured feature owner or a confirmed likely regression author.

If no routing map is configured, triage may classify a report but must not guess a destination or owner.

## 6. Verify the control adapter

Read `../reproduce-and-fix-issues/references/control-adapter.md` and the user's completed feature map.

Confirm that the named adapter can:

- Bring up the target app
- Navigate every mapped feature through the real UI
- Exercise mapped states through declared adapter actions
- Inspect state without forcing the result
- Capture screenshots
- Start and stop a recording
- Clean up its processes and temporary data

If any capability is missing, leave the repro automation disabled. It must fail closed rather than claim a reproduction it did not perform.

## 7. Prepare the live automations

Ask whether this is first-time creation or configuration of existing automations.

Read `../../FOR_AGENTS.md` from the copied pack as the primary user-intent source for either path. Use it to understand the two triggers, tools, instructions, outcomes, and shared rules.

### First-time creation

Create one automation at a time with `orca automations create`. For each automation:

1. Read the matching copied prompt template as secondary internal source material.
2. Turn `FOR_AGENTS.md`, the finished Benny configuration, and the template intent into the `--prompt` text.
3. Tell the live prompt to read and follow its exact committed operational file under `.orca/benny/`.
4. Use the stable repository-relative path, not a package source or cache path. Do not copy the operational file contents into the live prompt.
5. Confirm the copied pack and any referenced configuration files are committed in the same repository the automation runs against (`--repo <selector>`).
6. Review the created automation with `orca automations show` and do one dry run with `orca automations run` before enabling the schedule.

Triage automation, filled from configuration:

```bash
orca automations create \
	--name benny-triage \
	--trigger "*/15 * * * *" \
	--provider <triage agent> \
	--repo <target repo selector> \
	--prompt "Read and follow .orca/benny/skills/triage-issue-reports/SKILL.md for every run. Scan the configured source channel for new top-level reports since the last run. Classify, inspect evidence, trace cause, dedupe against the configured tracker, and create only clear new bugs. End one thread-only verdict per report with the configured [benny:bug], [benny:performance], or [benny:other] marker and optional tracker URL. Never post a source-channel root message." \
	--json
```

Repro automation, after the triage automation is reviewed:

```bash
orca automations create \
	--name benny-reproduce \
	--trigger "*/15 * * * *" \
	--provider <repro agent> \
	--repo <target repo selector> \
	--prompt "Read and follow .orca/benny/skills/reproduce-and-fix-issues/SKILL.md for every run. Pick up source-channel reports carrying the configured triage marker from the configured triage identity. Reproduce the exact symptom twice through the mapped real UI using the configured control adapter and feature map, and capture evidence. Verify an existing fix without authoring over it. Attempt an optional bounded fix only after confirmed repro, then open a draft pull request when proof and checks pass. Never post a source-channel root message." \
	--json
```

Create both disabled (`--disabled`) until the thread-safety test in step 8 passes, then
enable with `orca automations edit`.

### Existing automations

Do not create replacements or duplicates. Finish configuration, routing, control-adapter, and feature-map validation, then update each automation with `orca automations edit`:

For the existing triage automation, update:

- Name and description
- The prompt: direct instruction to read `.orca/benny/skills/triage-issue-reports/SKILL.md`, the scan-and-triage intent, thread-only rule, and Benny verdict markers
- Schedule and `--provider`
- Repo selector

For the existing repro automation, update:

- Name and description
- The prompt: direct instruction to read `.orca/benny/skills/reproduce-and-fix-issues/SKILL.md`, the marker wait, evidence, verification, and bounded-fix intent
- Repository and default branch context
- Schedule and `--provider`

### Creation boundary

Create and edit automations only through `orca automations create` / `orca automations edit` / `orca automations run`. Never hand-roll a scheduler, a cron entry outside Orca, or a background shell loop as a substitute.

Do not enable either automation until the thread-safety test passes after the first dry run.

## 8. Test thread safety

Use a test channel or a harmless test report.

Before testing, confirm that the target repository's `.pi/settings.json`, `.orca/benny/`, and every referenced secret-free configuration file are committed on the branch the automation runs against. Confirm that both live prompts point at their exact committed operational files. If any check fails, stop. Tell the user that the automation cannot be enabled yet.

Verify:

1. Triage stores the root thread coordinates and posts exactly one verdict as a reply.
2. The verdict contains one configured marker.
3. Repro accepts the marker only from the configured triage identity.
4. Repro keeps the same immutable source coordinates.
5. No source-channel root message appears.
6. A delegated worker cannot use any chat write action.
7. Missing coordinates, a deleted parent, or a failed preflight produces no post and no tracker issue.

Enable normal traffic only after all seven checks pass.
