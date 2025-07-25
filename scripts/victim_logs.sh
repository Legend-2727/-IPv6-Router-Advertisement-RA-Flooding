#!/usr/bin/env bash
# Enhanced victim logging script with consistent path handling
# Usage: sudo ./victim_logs.sh [iface]

IFACE=${1:-$(ip route show default | awk '{print $5; exit}')}

# Use consistent log directory - check if running with sudo
if [[ $EUID -eq 0 ]]; then
    # Running as root/sudo - use /tmp for consistency with demo.sh  
    LOGDIR="/tmp/ra_flood_logs"
else
    # Running as regular user
    LOGDIR="$HOME/ra_flood_logs" 
fi

mkdir -p "$LOGDIR"

echo "[i] Enhanced logging on interface $IFACE → $LOGDIR  (Ctrl‑C to stop)"
echo "[i] Monitoring IPv6 addresses, CPU usage, and network traffic"

# Enhanced address count monitoring with more frequent updates
(
  echo "timestamp,addr_count,cpu_percent,memory_mb" > "$LOGDIR/enhanced_monitoring.csv"
  while true; do
    timestamp=$(date +%s)
    addr_count=$(ip -6 addr show dev "$IFACE" | grep -c 'inet6 ' || echo "0")
    
    # Get CPU and memory usage
    cpu_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "0")
    memory_mb=$(free -m | awk 'NR==2{printf "%.1f", $3*100/$2}' || echo "0")
    
    printf "%s,%s,%s,%s\n" "$timestamp" "$addr_count" "$cpu_percent" "$memory_mb"
    sleep 0.5  # High-frequency monitoring for attack detection
  done
) > "$LOGDIR/enhanced_monitoring.csv" &

# Legacy compatibility - maintain original format
(
  echo "timestamp,addr_count" > "$LOGDIR/addr_count.csv"
  while true; do
    printf "%s,%s\n" "$(date +%s)" \
      "$(ip -6 addr show dev "$IFACE" | grep -c 'inet6 ' || echo "0")"
    sleep 2
  done
) > "$LOGDIR/addr_count.csv" &

# Enhanced system monitoring
(
    echo "Enhanced system monitoring started at $(date)" > "$LOGDIR/system_performance.log"
    echo "==================================================" >> "$LOGDIR/system_performance.log"
    
    while true; do
        echo "" >> "$LOGDIR/system_performance.log"
        echo "Timestamp: $(date)" >> "$LOGDIR/system_performance.log"
        echo "IPv6 Addresses on $IFACE:" >> "$LOGDIR/system_performance.log"
        ip -6 addr show dev "$IFACE" | grep -c 'inet6' >> "$LOGDIR/system_performance.log"
        echo "CPU Usage:" >> "$LOGDIR/system_performance.log"
        top -bn1 | head -20 >> "$LOGDIR/system_performance.log"
        echo "Memory Usage:" >> "$LOGDIR/system_performance.log"
        free -h >> "$LOGDIR/system_performance.log"
        echo "Network Interface Stats:" >> "$LOGDIR/system_performance.log"
        cat /proc/net/dev | grep "$IFACE" >> "$LOGDIR/system_performance.log"
        echo "===========================================" >> "$LOGDIR/system_performance.log"
        sleep 5
    done
) &

echo "[+] Monitoring processes started:"
echo "    - Enhanced CSV monitoring: $LOGDIR/enhanced_monitoring.csv"  
echo "    - Legacy address count: $LOGDIR/addr_count.csv"
echo "    - System performance: $LOGDIR/system_performance.log"
echo "    - Update frequency: 0.5 seconds (enhanced), 2 seconds (legacy)"

wait
