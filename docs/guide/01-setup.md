# Set up pstack

In this page you install the plugin, pick which models pstack uses, and run your first task. Setup is one command plus a short conversation.

## Install the package

From a checkout of pstack-orca, run:

```bash
pi install /path/to/pstack-orca
```

or add its `skills/` directory to the `skills` array in `~/.pi/agent/settings.json`. `pi list` confirms the package is installed.

## Pick your agents

Run:

```text
/skill:setup-pstack
```

[`/setup-pstack`](../../skills/setup-pstack/SKILL.md) detects the agent CLIs Orca can launch as workers, shows you each role (code delegates, judgment, the review panels), and asks what you want. Answer the questions. It writes `~/.pi/agent/pstack-models.md`, a small config file every pstack skill reads at delegation time.

You only override what you care about. A role with no line in the config keeps the skill's default. To restore a default later, delete that role's line, or just run `/skill:setup-pstack` again.

Set a role to `inherit-parent` or `auto` and that role runs on your own agent and model instead of a dispatched worker. Both values mean the same thing. For a panel role the value is a list, and one worker runs per entry, so the list length sets the panel size. Setup also configures `swarm workers`, the default agent for every `/skill:swarm` worker unless a race names one per arm.

## Accept the verification offer, or don't

At the end of setup, `/setup-pstack` looks for a way to prove app behavior in your project, either a `verify-*` skill or an existing harness. If it finds neither, it offers once to generate one with [`/create-verification-skill`](../../skills/create-verification-skill/SKILL.md).

Say yes and it writes `.pi/skills/verify-<app>/`, a project-local skill that teaches agents to drive your app the way a user does. It proves the skill works once before handing it over. Say no and setup moves on. You can run `/create-verification-skill` yourself any time. [Verify and ship](./06-verify-and-ship.md#create-a-project-verification-skill) covers when it earns its place.

After setup, start a new chat. The model rule applies to new sessions.

## Run your first task

Pick something real but small, and describe it the way you'd describe it to a colleague:

```text
/poteto-mode add a --json flag to this command. text output stays byte-identical. verify both.
```

Watch the todo list. The first item is always "read the Principles section". The rest are the matched playbook's steps copied in, the Feature playbook for this prompt. If `/poteto-mode` skips a step, the step stays in the list with `skip: <reason>`, so you can see what it chose not to do.

From here you can type normal follow-ups. `/poteto-mode` is sticky. It stays on for the conversation until you opt out by saying so.

Next: [Route work through `/poteto-mode`](./02-poteto-mode.md).
