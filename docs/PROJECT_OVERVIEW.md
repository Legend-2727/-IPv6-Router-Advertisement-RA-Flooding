# IPv6 Router Advertisement Flooding Attack

## What This Project Does

This project implements an IPv6 Router Advertisement (RA) flooding attack - a network security assessment tool that demonstrates vulnerabilities in IPv6 network infrastructure. The attack exploits the IPv6 Stateless Address Autoconfiguration (SLAAC) mechanism to cause Denial of Service (DoS) on victim systems.

## Why This Attack Matters

### The Problem
IPv6 networks use Router Advertisement messages to automatically configure host addresses. Malicious actors can exploit this by:
- Sending fake RA messages with random network prefixes
- Forcing victims to create multiple IPv6 addresses
- Exhausting system resources and degrading network performance
- Bypassing traditional network security controls (RA-Guard)

### Real-World Impact
- **Resource Exhaustion**: Victims create hundreds of IPv6 addresses
- **Performance Degradation**: Network stack becomes overwhelmed
- **Security Bypass**: Fragments can evade RA-Guard protection
- **DoS Conditions**: Systems become unresponsive or unstable

## How The Attack Works

### 1. Basic RA Flooding
```
Attacker → [Fake RA Messages] → Victim
         Multiple random prefixes   Creates new IPv6 addresses
```

### 2. Advanced Techniques
- **Fragment Headers**: Split RA packets to bypass RA-Guard filters
- **Random MTU Options**: Include variable MTU advertisements
- **Multi-threading**: High-speed concurrent packet transmission
- **Stealth Mode**: Randomized source addresses for evasion

### 3. Technical Implementation
- **Scapy**: Crafts custom IPv6/ICMPv6 packets
- **Raw Sockets**: Direct network interface access
- **Threading**: Parallel attack streams
- **Monitoring**: Real-time impact measurement

## Attack Flow Diagram
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Attacker  │    │   Network    │    │   Victim    │
│             │    │              │    │             │
│ 1. Craft RA │───▶│ 2. Forward   │───▶│ 3. Process  │
│    packets  │    │    packets   │    │    RA msgs  │
│             │    │              │    │             │
│ 4. Monitor  │◄───│ 5. Capture   │◄───│ 6. Create   │
│    impact   │    │    traffic   │    │    addresses│
└─────────────┘    └──────────────┘    └─────────────┘
```

## Defense Evasion Techniques

### RA-Guard Bypass
Traditional RA-Guard inspects RA messages but fails with:
- **IPv6 Fragment Headers**: Split critical fields across fragments
- **Extension Header Chains**: Hide RA payload behind extensions
- **Malformed Packets**: Edge cases in parsing logic

### Detection Evasion
- **Source Randomization**: Different MAC/IPv6 for each packet
- **Timing Variation**: Non-uniform packet intervals
- **Legitimate-Looking Traffic**: Proper IPv6 header structure

## Educational Purpose

This tool is designed for:
- **Security Research**: Understanding IPv6 vulnerabilities
- **Network Testing**: Assessing infrastructure resilience  
- **Educational Demos**: Teaching IPv6 security concepts
- **Penetration Testing**: Authorized security assessments

⚠️ **IMPORTANT**: This tool is for educational and authorized testing only. Unauthorized use against networks you don't own is illegal and unethical.

## Technical Architecture

### Core Components
1. **ra_flood.py**: Main attack engine with packet crafting
2. **utils.py**: Helper functions for network operations
3. **demo.sh**: Automated demonstration script
4. **requirements.txt**: Python dependencies

### Packet Structure
```
Ethernet Header
├── IPv6 Header
│   ├── Fragment Header (optional)
│   └── ICMPv6 Header (Type 134 - Router Advertisement)
│       ├── Router Lifetime
│       ├── Reachable Time
│       ├── Retrans Timer
│       └── Options
│           ├── Prefix Information (random network)
│           └── MTU (optional, random value)
```

### Attack Modes
- **Single-threaded**: Sequential packet transmission
- **Multi-threaded**: Parallel attack streams  
- **Fragment mode**: RA-Guard bypass technique
- **Stealth mode**: Enhanced evasion capabilities
