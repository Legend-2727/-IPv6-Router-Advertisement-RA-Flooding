# IPv6 Router Advertisement (RA) Flood Attack

This project implements an IPv6 Router Advertisement flooding attack for security research and educational purposes.

## Overview

The IPv6 RA flood attack exploits the IPv6 Neighbor Discovery Protocol (NDP) by sending numerous forged Router Advertisement messages. This can cause:
- IPv6 address exhaustion on victim hosts
- Performance degradation due to processing overhead
- Potential DoS conditions

## Features

### Core Attack Features
- ✅ **Basic RA Flooding**: Send crafted RA packets with random prefixes
- ✅ **Multi-threaded Mode**: High-speed flooding with configurable thread count
- ✅ **RA-Guard Bypass**: Use IPv6 Fragment headers to bypass RA-Guard protection
- ✅ **Random MTU Options**: Append MTU options with random values
- ✅ **Rate Limiting**: Control packet sending rate (packets per second)
- ✅ **Progress Monitoring**: Real-time progress bars with tqdm

### Advanced Features
- 🔄 **Packet Capture**: Capture and analyze victim responses (TODO)
- 🔄 **Multiple Attack Vectors**: Different RA flooding strategies (TODO)
- 🔄 **Network Discovery**: Auto-detect network interfaces (TODO)
- 🔄 **Stealth Mode**: Randomized timing and patterns (TODO)

### Monitoring & Analysis
- ✅ **Victim Logging**: Monitor victim IPv6 address count and system resources
- 🔄 **Traffic Analysis**: Analyze network traffic during attack (TODO)
- 🔄 **Impact Assessment**: Measure attack effectiveness (TODO)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd IPv6-Router-Advertisement-RA-Flooding
```

2. Create and activate virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Usage

### Basic RA Flood Attack

**Note: Root privileges required for raw packet sending**

```bash
# Basic flood (infinite packets)
sudo python src/ra_flood.py -i eth0

# Send specific number of packets
sudo python src/ra_flood.py -i eth0 -c 1000

# Rate-limited attack (100 packets per second)
sudo python src/ra_flood.py -i eth0 -r 100

# Multi-threaded high-speed attack
sudo python src/ra_flood.py -i eth0 --fast --threads 8

# RA-Guard bypass using fragment headers
sudo python src/ra_flood.py -i eth0 --fragment

# Add random MTU options
sudo python src/ra_flood.py -i eth0 --random-mtu

# Combined attack with all features
sudo python src/ra_flood.py -i eth0 --fast --threads 4 --fragment --random-mtu -r 500
```

### Victim Monitoring

Monitor the victim system's IPv6 addresses and resource usage:

```bash
# Run on victim machine
sudo ./scripts/victim_logs.sh eth0
```

This creates logs in `$HOME/ra_flood_logs/`:
- `addr_count.csv`: IPv6 address count over time
- `cpu_mem.log`: CPU and memory usage

### Command Line Options

```
usage: IPv6 Router‑Advertisement flooder [-h] [-i IFACE] [-r RATE] [-c COUNT] 
                                         [--fast] [--threads THREADS] 
                                         [--fragment] [--random-mtu]

options:
  -h, --help            show this help message and exit
  -i IFACE, --iface IFACE
                        Network interface (default: eno1)
  -r RATE, --rate RATE  Packets per second per thread (default: unlimited)
  -c COUNT, --count COUNT
                        Number of packets to send (0 = infinite)
  --fast                Enable multi-threaded high-speed mode
  --threads THREADS     Number of worker threads for --fast mode (default: 4)
  --fragment            Add IPv6 Fragment header (RA-Guard bypass)
  --random-mtu          Append MTU option with random size (1280-9000)
```

## Technical Details

### Attack Mechanism

1. **Packet Generation**: Creates forged IPv6 Router Advertisement packets
2. **Random Prefixes**: Each RA contains a unique IPv6 prefix (2001:xxxx::/64)
3. **MAC Address Spoofing**: Uses locally administered MAC addresses (02:xx:xx:xx:xx:xx)
4. **Link-Local Addresses**: Generates corresponding fe80:: addresses using EUI-64

### Packet Structure

```
Ethernet Header
├── Dst: 33:33:00:00:00:01 (IPv6 All-Nodes multicast)
└── Src: 02:xx:xx:xx:xx:xx (Random locally administered MAC)

IPv6 Header
├── Src: fe80::xxxx:xxxx:xxxx:xxxx (Link-local from MAC)
├── Dst: ff02::1 (All-Nodes multicast)
└── [Optional] Fragment Header (for RA-Guard bypass)

ICMPv6 Router Advertisement
├── Router Lifetime: 0
├── Reachable Time: 0
├── Retrans Timer: 0
└── Options:
    ├── Prefix Information (2001:xxxx::/64)
    └── [Optional] MTU Option (random 1280-9000)
```

### RA-Guard Bypass

Many enterprise switches implement RA-Guard to filter Router Advertisements from untrusted ports. This implementation can bypass RA-Guard using:

- **IPv6 Fragment Headers**: Fragments the RA packet to evade inspection
- **Randomized Source MACs**: Avoids MAC-based filtering

## Project Structure

```
IPv6-Router-Advertisement-RA-Flooding/
├── src/
│   ├── ra_flood.py          # Main attack script
│   ├── utils.py             # Utility functions (MAC/IPv6 generation)
│   └── __init__.py
├── scripts/
│   └── victim_logs.sh       # Victim monitoring script
├── captures/                # Packet captures directory
├── docs/                    # Documentation
├── requirements.txt         # Python dependencies
├── README.md               # This file
└── venv/                   # Virtual environment
```

## Educational Purpose

This tool is designed for:
- **Security Research**: Understanding IPv6 vulnerabilities
- **Network Testing**: Testing RA-Guard implementations
- **Educational Labs**: Learning IPv6 security concepts

## Ethical Use

⚠️ **WARNING**: This tool is for educational and authorized testing purposes only.

- Only use on networks you own or have explicit permission to test
- Understand legal implications in your jurisdiction
- Follow responsible disclosure practices
- Do not use for malicious purposes

## Common Issues

### Permission Denied
```bash
PermissionError: [Errno 1] Operation not permitted
```
**Solution**: Run with sudo privileges:
```bash
sudo python src/ra_flood.py [options]
```

### Network Interface Not Found
**Solution**: List available interfaces and specify the correct one:
```bash
ip link show
sudo python src/ra_flood.py -i <correct_interface>
```

### Dependencies Missing
**Solution**: Install requirements in virtual environment:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

## Future Enhancements

- [ ] Packet capture and analysis module
- [ ] Web-based monitoring dashboard
- [ ] Multiple attack strategies (DHCPv6, MLD, etc.)
- [ ] Automated network discovery
- [ ] Stealth mode with randomized patterns
- [ ] Impact assessment metrics
- [ ] Defense mechanism testing

## References

- [RFC 4861 - Neighbor Discovery for IP version 6](https://tools.ietf.org/html/rfc4861)
- [RFC 4291 - IP Version 6 Addressing Architecture](https://tools.ietf.org/html/rfc4291)
- [RFC 6104 - Rogue IPv6 Router Advertisement Problem Statement](https://tools.ietf.org/html/rfc6104)

## License

This project is for educational purposes. Use responsibly and in accordance with applicable laws.