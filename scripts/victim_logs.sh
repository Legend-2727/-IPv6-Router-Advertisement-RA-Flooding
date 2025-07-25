#!/usr/bin/env bash
# Usage: sudo ./victim_log.sh [iface]
IFACE=${1:-$(ip route show default | awk '{print $5; exit}')}
LOGDIR=$HOME/ra_flood_logs
mkdir -p "$LOGDIR"

echo "[i] Logging on interface $IFACE → $LOGDIR  (Ctrl‑C to stop)"

# address count
(
  echo "timestamp,addr_count"
  while true; do
    printf "%s,%s\n" "$(date +%s)" \
      "$(ip -6 addr show dev "$IFACE" | grep -c 'inet6 ')"
    sleep 2
  done
) > "$LOGDIR/addr_count.csv" &

# CPU / mem
top -b -d2 > "$LOGDIR/cpu_mem.log" &
wait
