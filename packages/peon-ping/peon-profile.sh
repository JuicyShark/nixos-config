#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  peon-profile status
  peon-profile <quiet|focus|normal>
USAGE
}

profile="${1:-}"
if [ -z "$profile" ]; then
  usage
  exit 1
fi

opencode_config="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/peon-ping/config.json"
claude_config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/peon-ping/config.json"

if [ -f "$opencode_config" ]; then
  target_config="$opencode_config"
elif [ -f "$claude_config" ]; then
  target_config="$claude_config"
else
  target_config="$opencode_config"
  @COREUTILS@/bin/mkdir -p "$(dirname "$target_config")"
  cat > "$target_config" <<'JSONEOF'
{
  "active_pack": "peon",
  "volume": 0.4,
  "enabled": true,
  "categories": {
    "session.start": true,
    "session.end": true,
    "task.acknowledge": true,
    "task.complete": true,
    "task.error": true,
    "task.progress": true,
    "input.required": true,
    "resource.limit": true,
    "user.spam": true
  },
  "spam_threshold": 3,
  "spam_window_seconds": 10,
  "pack_rotation": [],
  "debounce_ms": 500
}
JSONEOF
fi

@PYTHON3@/bin/python3 - "$target_config" "$profile" <<'PY'
import json
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1])
profile = sys.argv[2]

cfg = json.loads(config_path.read_text(encoding="utf-8"))
cats = cfg.setdefault("categories", {})

profiles = {
    "quiet": {
        "volume": 0.2,
        "desktop_notifications": True,
        "categories": {
            "session.start": False,
            "session.end": False,
            "task.acknowledge": False,
            "task.complete": False,
            "task.error": True,
            "task.progress": False,
            "input.required": True,
            "resource.limit": True,
            "user.spam": False,
        },
    },
    "focus": {
        "volume": 0.3,
        "desktop_notifications": True,
        "categories": {
            "session.start": False,
            "session.end": False,
            "task.acknowledge": False,
            "task.complete": True,
            "task.error": True,
            "task.progress": False,
            "input.required": True,
            "resource.limit": True,
            "user.spam": False,
        },
    },
    "normal": {
        "volume": 0.4,
        "desktop_notifications": True,
        "categories": {
            "session.start": True,
            "session.end": True,
            "task.acknowledge": True,
            "task.complete": True,
            "task.error": True,
            "task.progress": True,
            "input.required": True,
            "resource.limit": True,
            "user.spam": True,
        },
    },
}

if profile == "status":
    enabled = [k for k, v in cats.items() if bool(v)]
    print(f"Config: {config_path}")
    print(f"Volume: {cfg.get('volume', 'unknown')}")
    print(f"Desktop notifications: {cfg.get('desktop_notifications', True)}")
    print("Enabled categories: " + ", ".join(sorted(enabled)))
    raise SystemExit(0)

if profile not in profiles:
    print("Unknown profile. Use: quiet, focus, normal, status", file=sys.stderr)
    raise SystemExit(1)

selected = profiles[profile]
cfg["volume"] = selected["volume"]
cfg["desktop_notifications"] = selected["desktop_notifications"]
for key, value in selected["categories"].items():
    cats[key] = value

config_path.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
print(f"Applied '{profile}' profile to {config_path}")
PY
