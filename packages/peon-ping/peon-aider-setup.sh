#!/usr/bin/env bash
set -euo pipefail

aider_config="$HOME/.aider.conf.yml"
notify_cmd="@OUT@/bin/peon-aider-notify"

@PYTHON3@/bin/python3 - "$aider_config" "$notify_cmd" <<'PY'
import pathlib
import re
import sys

config_path = pathlib.Path(sys.argv[1])
notify_cmd = sys.argv[2]

if config_path.exists():
    text = config_path.read_text(encoding="utf-8")
else:
    text = ""

if text and not text.endswith("\n"):
    text += "\n"

lines = text.splitlines()


def upsert(lines, key, value):
    pattern = re.compile(rf"^(\s*){re.escape(key)}\s*:")
    for i, line in enumerate(lines):
        m = pattern.match(line)
        if m:
            indent = m.group(1)
            lines[i] = f"{indent}{key}: {value}"
            return
    lines.append(f"{key}: {value}")


upsert(lines, "notifications", "true")
upsert(lines, "notifications_command", f'"{notify_cmd}"')

config_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Updated {config_path}")
print("Set notifications: true")
print(f"Set notifications_command: {notify_cmd}")
PY

echo "Done. Run aider normally; peon notifications are now enabled."
