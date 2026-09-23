{
  pkgs,
  host,
  username,
  passwordFile,
  port ? 1883,
}:
pkgs.writeShellApplication {
  name = "ha-mqtt-pub";
  runtimeInputs = [pkgs.mosquitto];
  text = ''
    topic="''${1:?usage: ha-mqtt-pub <topic> <payload> [retain]}"
    payload="''${2:?usage: ha-mqtt-pub <topic> <payload> [retain]}"
    retain="''${3:-true}"
    auth_file="$(mktemp)"
    trap 'rm -f "$auth_file"' EXIT

    if [ ! -r "${passwordFile}" ]; then
      echo "ha-mqtt-pub: cannot read ${passwordFile}" >&2
      exit 1
    fi

    {
      printf '%s %s\n' '-u' "${username}"
      printf '%s ' '-P'
      cat "${passwordFile}"
      printf '\n'
    } >"$auth_file"

    retain_args=()
    if [ "$retain" = true ]; then
      retain_args=(-r)
    fi

    mosquitto_pub \
      -o "$auth_file" \
      -h "${host}" \
      -p "${toString port}" \
      -t "$topic" \
      -m "$payload" \
      -q 1 \
      --keepalive 10 \
      "''${retain_args[@]}"
  '';
}
