#!/usr/bin/env bash
set -euo pipefail

opencode_plugins_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"
peon_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/peon-ping"
packs_dir="$HOME/.openpeon/packs"

@COREUTILS@/bin/mkdir -p "$opencode_plugins_dir" "$peon_config_dir" "$packs_dir"
@COREUTILS@/bin/cp "@OUT@/share/peon-ping/adapters/opencode/peon-ping.ts" "$opencode_plugins_dir/peon-ping.ts"

if [ ! -f "$peon_config_dir/config.json" ]; then
  cat > "$peon_config_dir/config.json" <<'JSONEOF'
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
  echo "Created config at $peon_config_dir/config.json"
else
  echo "Config already exists, preserved at $peon_config_dir/config.json"
fi

if [ ! -d "$packs_dir/peon" ]; then
  @COREUTILS@/bin/cp -r "@OUT@/share/openpeon/packs/peon" "$packs_dir/"
  echo "Installed default pack to $packs_dir/peon"
else
  echo "Default pack already exists at $packs_dir/peon"
fi

echo "Installed OpenCode plugin to $opencode_plugins_dir/peon-ping.ts"
echo "Done. Restart OpenCode to load peon-ping."
