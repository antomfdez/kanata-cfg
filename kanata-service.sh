#!/usr/bin/env bash
set -euo pipefail

LABEL="dev.kanata.kanata"
PLIST="/Library/LaunchDaemons/${LABEL}.plist"
DOMAIN="system"
SERVICE="${DOMAIN}/${LABEL}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--start|--stop|--restart|--status]

Manage the Kanata LaunchDaemon:
  --start      Load and start ${LABEL}
  --stop       Stop and unload ${LABEL}
  --restart    Stop/unload, then load/start ${LABEL}
  --status     Print launchd status for ${LABEL}
  -h, --help   Show this help
USAGE
}

require_plist() {
  if [[ ! -f "$PLIST" ]]; then
    echo "Missing plist: $PLIST" >&2
    exit 1
  fi
}

is_loaded() {
  sudo launchctl print "$SERVICE" >/dev/null 2>&1
}

start_service() {
  require_plist

  if is_loaded; then
    sudo launchctl kickstart "$SERVICE"
    echo "Started ${LABEL}."
    return
  fi

  sudo launchctl bootstrap "$DOMAIN" "$PLIST"
  sudo launchctl kickstart "$SERVICE"
  echo "Started ${LABEL}."
}

stop_service() {
  if ! is_loaded; then
    echo "${LABEL} is not loaded."
    return
  fi

  sudo launchctl bootout "$SERVICE"
  echo "Stopped ${LABEL}."
}

restart_service() {
  if is_loaded; then
    sudo launchctl bootout "$SERVICE"
  fi

  require_plist
  sudo launchctl bootstrap "$DOMAIN" "$PLIST"
  sudo launchctl kickstart "$SERVICE"
  echo "Restarted ${LABEL}."
}

status_service() {
  if is_loaded; then
    sudo launchctl print "$SERVICE"
  else
    echo "${LABEL} is not loaded."
    exit 3
  fi
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

case "$1" in
  --start)
    start_service
    ;;
  --stop)
    stop_service
    ;;
  --restart)
    restart_service
    ;;
  --status)
    status_service
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
