#!/usr/bin/env bash
# Symlink pstack-orca's skills into other harnesses' skill directories so
# Claude Code and Codex (as primary agents or as Orca workers) discover them.
# User scope by default; --project <dir> for project scope. Idempotent.
#
# Usage: install-harnesses.sh [--project <dir>] [--uninstall]
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
project=""
uninstall=0
while [ $# -gt 0 ]; do
	case "$1" in
		--project) project="${2:?--project needs a directory}"; shift 2 ;;
		--uninstall) uninstall=1; shift ;;
		*) echo "unknown arg: $1" >&2; exit 1 ;;
	esac
done

if [ -n "$project" ]; then
	targets=("$project/.claude/skills" "$project/.codex/skills")
else
	targets=("$HOME/.claude/skills" "$HOME/.codex/skills")
fi

for target in "${targets[@]}"; do
	if [ "$uninstall" = 1 ]; then
		[ -d "$target" ] || continue
		find "$target" -maxdepth 1 -type l -lname "$repo/skills/*" -delete
		echo "cleaned $target"
		continue
	fi
	mkdir -p "$target"
	for skill in "$repo"/skills/*/; do
		name="$(basename "$skill")"
		link="$target/$name"
		if [ -L "$link" ] && [ "$(readlink "$link")" = "${skill%/}" ]; then
			continue
		fi
		if [ -e "$link" ] && [ ! -L "$link" ]; then
			echo "skip $link (exists, not our symlink)" >&2
			continue
		fi
		ln -sfn "${skill%/}" "$link"
		echo "linked $link"
	done
done
