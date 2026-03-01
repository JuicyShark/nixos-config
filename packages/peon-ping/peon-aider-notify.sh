#!/usr/bin/env bash
set -euo pipefail

peon_hook="@OUT@/share/peon-ping/peon.sh"
cwd="${PWD:-$HOME}"
session_id="${AIDER_SESSION_ID:-aider}"

@PYTHON3@/bin/python3 - "$cwd" "$session_id" <<'PY' | @BASH@/bin/bash "$peon_hook" >/dev/null 2>&1 || true
import json
import sys

cwd = sys.argv[1]
session_id = sys.argv[2]

print(
    json.dumps(
        {
            "hook_event_name": "Stop",
            "cwd": cwd,
            "session_id": session_id,
        }
    )
)
PY
