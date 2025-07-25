# IPv6 RA Flood Attack - Technical Documentation

## Implementation Overview

This project implements a comprehensive IPv6 Router Advertisement flooding attack for security research and educational purposes. The implementation includes multiple attack vectors, evasion techniques, and monitoring capabilities.

## Architecture

### Core Components

1. **ra_flood.py** - Main attack engine
   - Single-threaded and multi-threaded modes
   - Rate limiting and packet counting
   - Progress monitoring with tqdm
   - Signal handling for graceful shutdown

2. **utils.py** - Utility functions
   - Random MAC address generation (locally administered)
   - MAC to IPv6 link-local address conversion
   - EUI-64 identifier generation

3. **network_discovery.py** - Network interface management
   - Automatic interface detection
   - Interface validation and status checking
   - IPv6 capability assessment

4. **capture.py** - Traffic analysis and monitoring
   - Real-time packet capture during attacks
   - Impact assessment and baseline comparison
   - Statistical analysis of attack effectiveness

### Attack Features

#### Basic RA Flooding
- Generates forged Router Advertisement packets
- Random IPv6 prefixes (2001:xxxx::/64)
- Locally administered source MAC addresses
- Link-local source addresses derived from MAC

#### Advanced Evasion Techniques
- **RA-Guard Bypass**: IPv6 Fragment headers to evade switch filtering
- **Stealth Mode**: Randomized timing patterns and realistic RA parameters
- **Random MTU Options**: Appends MTU options with random values (1280-9000)

#### Multi-Threading Support
- Configurable worker thread count
- Thread-safe packet generation
- Coordinated shutdown handling

## Packet Structure

```
Ethernet Frame
├── Destination: 33:33:00:00:00:01 (IPv6 All-Nodes multicast)
├── Source: 02:xx:xx:xx:xx:xx (Random locally administered)
└── EtherType: 0x86DD (IPv6)

IPv6 Header
├── Version: 6
├── Traffic Class: 0
├── Flow Label: 0
├── Payload Length: Variable
├── Next Header: 58 (ICMPv6) or 44 (Fragment)
├── Hop Limit: 255
├── Source: fe80::xxxx:xxxx:xxxx:xxxx (Link-local)
└── Destination: ff02::1 (All-Nodes multicast)

[Optional] IPv6 Fragment Header
├── Next Header: 58 (ICMPv6)
├── Reserved: 0
├── Fragment Offset: 0
├── Reserved: 0
├── More Fragments: 0
└── Identification: Random

ICMPv6 Router Advertisement
├── Type: 134 (Router Advertisement)
├── Code: 0
├── Checksum: Calculated
├── Current Hop Limit: 64
├── Flags: 0x40 (Managed=0, Other=1)
├── Router Lifetime: 0 (normal) or random (stealth)
├── Reachable Time: 0 (normal) or random (stealth)
├── Retrans Timer: 0 (normal) or random (stealth)
└── Options:
    ├── Prefix Information Option
    │   ├── Type: 3
    │   ├── Length: 4
    │   ├── Prefix Length: 64
    │   ├── Flags: 0xC0 (On-link=1, Auto=1)
    │   ├── Valid Lifetime: 0xFFFFFFFF
    │   ├── Preferred Lifetime: 0xFFFFFFFF
    │   └── Prefix: 2001:xxxx::/64
    └── [Optional] MTU Option
        ├── Type: 5
        ├── Length: 1
        └── MTU: Random (1280-9000)
```

## Attack Vectors

### 1. Basic Flooding
- Rapid transmission of RA packets
- Causes victim hosts to create multiple IPv6 addresses
- Can exhaust address space and system resources

### 2. RA-Guard Bypass
- Uses IPv6 Fragment headers to evade inspection
- Many RA-Guard implementations only check first fragment
- Allows attacks on "protected" networks

### 3. Stealth Mode
- Randomized timing patterns to avoid detection
- Realistic RA parameters to blend with legitimate traffic
- Variable packet intervals to evade rate-based detection

## Security Implications

### Attack Impact
1. **IPv6 Address Exhaustion**: Victims create numerous addresses
2. **CPU/Memory Consumption**: Processing overhead on victim systems  
3. **Network Disruption**: Potential DoS through resource exhaustion
4. **Routing Table Pollution**: Multiple default routes on victims

### Defense Mechanisms
1. **RA-Guard**: Switch-based filtering (can be bypassed)
2. **Rate Limiting**: Limit RA processing rate
3. **Source Validation**: Verify legitimate router sources
4. **Monitoring**: Detect unusual RA traffic patterns

## Usage Patterns

### Testing Scenarios
1. **Penetration Testing**: Assess network IPv6 security
2. **Research**: Study IPv6 vulnerabilities and defenses
3. **Education**: Demonstrate IPv6 security concepts
4. **Defense Validation**: Test RA-Guard implementations

### Operational Modes

#### Development/Testing
```bash
# Safe testing without transmission
python test_suite.py

# List available interfaces  
sudo python src/ra_flood.py --list-interfaces
```

#### Attack Execution
```bash
# Basic attack
sudo python src/ra_flood.py -i eth0 -c 1000

# Advanced attack with all features
sudo python src/ra_flood.py -i eth0 --fast --threads 4 --fragment --stealth --random-mtu --capture
```

#### Monitoring
```bash
# Monitor victim impact
sudo ./scripts/victim_logs.sh eth0

# Analyze captured traffic
ls captures/  # Review .pcap files
```

## Performance Characteristics

### Single-Threaded Mode
- Rate: ~100-500 packets/second (hardware dependent)
- Memory: Low overhead
- CPU: Single core utilization

### Multi-Threaded Mode  
- Rate: ~1000-5000+ packets/second (with 4-8 threads)
- Memory: Moderate overhead per thread
- CPU: Multi-core utilization

### Stealth Mode
- Rate: Variable (0.1-2 second intervals)
- Detection: Lower probability
- Duration: Longer attack window

## Implementation Details

### Error Handling
- Permission checks for raw socket access
- Interface validation before attack
- Graceful shutdown on interruption
- Comprehensive error reporting

### Monitoring Integration
- Real-time progress bars
- Packet capture during attacks
- Impact assessment metrics
- Statistical analysis

### Extensibility
- Modular design for easy enhancement
- Plugin architecture for new attack vectors
- Configurable packet generation
- Flexible output formats

## Security Considerations

### Ethical Use
- Educational and research purposes only
- Authorized testing with explicit permission
- Understanding of legal implications
- Responsible disclosure practices

### Operational Security
- Root privileges required
- Network interface access needed
- Potential for network disruption
- Trace evidence in network logs

## Future Enhancements

### Planned Features
- Web-based monitoring dashboard
- Additional IPv6 attack vectors (DHCPv6, MLD)
- Machine learning-based evasion
- Automated defense testing

### Research Directions
- IPv6 security assessment frameworks
- Advanced evasion techniques
- Defensive countermeasures
- Performance optimization

## References

- RFC 4861: Neighbor Discovery for IP version 6
- RFC 4291: IP Version 6 Addressing Architecture  
- RFC 6104: Rogue IPv6 Router Advertisement Problem Statement
- RFC 3972: Cryptographically Generated Addresses (CGA)
