#!/usr/bin/env bash
# Runs inside the beam. Claude gets read-only tools over the PR checkout.
set -euo pipefail
cd ~/work
claude -p "$(cat ~/reply/prompt.md)" \
  --output-format json \
  --max-turns 25 \
  --allowedTools Read Grep Glob \
  --disallowedTools Bash Edit Write NotebookEdit WebFetch WebSearch \
  > ~/reply/claude.json 2> ~/reply/claude-stderr.log
