#!/usr/bin/env python3
"""
Network Discovery and Interface Detection
-----------------------------------------
Utilities for discovering network interfaces and IPv6 configurations
"""

import subprocess
import psutil
import netifaces
from typing import List, Dict, Optional

def get_network_interfaces() -> List[Dict[str, str]]:
    """Get list of available network interfaces with their details."""
    interfaces = []
    
    for interface in netifaces.interfaces():
        try:
            # Get interface details
            addrs = netifaces.ifaddresses(interface)
            
            # Check if interface has IPv6
            has_ipv6 = netifaces.AF_INET6 in addrs
            has_ipv4 = netifaces.AF_INET in addrs
            
            # Get MAC address
            mac = None
            if netifaces.AF_LINK in addrs:
                mac = addrs[netifaces.AF_LINK][0].get('addr')
            
            # Check if interface is up
            is_up = False
            try:
                stats = psutil.net_if_stats()[interface]
                is_up = stats.isup
            except KeyError:
                pass
            
            interfaces.append({
                'name': interface,
                'mac': mac or 'Unknown',
                'has_ipv6': has_ipv6,
                'has_ipv4': has_ipv4,
                'is_up': is_up,
                'ipv6_addrs': [addr['addr'] for addr in addrs.get(netifaces.AF_INET6, [])],
                'ipv4_addrs': [addr['addr'] for addr in addrs.get(netifaces.AF_INET, [])]
            })
            
        except Exception as e:
            # Skip interfaces that cause errors
            continue
    
    return interfaces

def get_default_interface() -> Optional[str]:
    """Get the default network interface."""
    try:
        # Try to get default route interface
        result = subprocess.run(['ip', 'route', 'show', 'default'], 
                              capture_output=True, text=True, check=True)
        for line in result.stdout.split('\n'):
            if 'dev' in line:
                parts = line.split()
                dev_idx = parts.index('dev')
                if dev_idx + 1 < len(parts):
                    return parts[dev_idx + 1]
    except:
        pass
    
    # Fallback: return first up interface with IPv6
    interfaces = get_network_interfaces()
    for iface in interfaces:
        if iface['is_up'] and iface['has_ipv6'] and not iface['name'].startswith('lo'):
            return iface['name']
    
    return None

def print_interface_info():
    """Print detailed information about network interfaces."""
    interfaces = get_network_interfaces()
    default = get_default_interface()
    
    print("Available Network Interfaces:")
    print("=" * 60)
    
    for iface in interfaces:
        marker = " (DEFAULT)" if iface['name'] == default else ""
        status = "UP" if iface['is_up'] else "DOWN"
        
        print(f"Interface: {iface['name']}{marker}")
        print(f"  Status: {status}")
        print(f"  MAC: {iface['mac']}")
        print(f"  IPv4: {iface['has_ipv4']} - {', '.join(iface['ipv4_addrs'])}")
        print(f"  IPv6: {iface['has_ipv6']} - {', '.join(iface['ipv6_addrs'])}")
        print()

def validate_interface(interface: str) -> bool:
    """Validate if an interface exists and is suitable for the attack."""
    interfaces = get_network_interfaces()
    
    for iface in interfaces:
        if iface['name'] == interface:
            if not iface['is_up']:
                print(f"Warning: Interface {interface} is DOWN")
                return False
            if not iface['has_ipv6']:
                print(f"Warning: Interface {interface} has no IPv6 configuration")
                return False
            return True
    
    print(f"Error: Interface {interface} not found")
    return False

if __name__ == "__main__":
    print_interface_info()
    
    default = get_default_interface()
    if default:
        print(f"Recommended interface for attack: {default}")
    else:
        print("No suitable interface found for IPv6 attack")
