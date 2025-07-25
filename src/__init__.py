# src/__init__.py
"""
IPv6 Router Advertisement Flood Attack Implementation
===================================================

This package implements an IPv6 RA flooding attack for security research
and educational purposes.

Main modules:
- ra_flood: Main attack implementation
- utils: Utility functions for MAC/IPv6 generation
- network_discovery: Network interface discovery and validation
- capture: Packet capture and traffic analysis

Usage:
    python src/ra_flood.py --help

Warning:
    This tool is for educational and authorized testing purposes only.
    Root privileges are required for raw packet sending.
"""

__version__ = "1.0.0"
__author__ = "Security Research Team"
__license__ = "Educational Use Only"

# Export main functions
from .utils import random_mac, mac_to_link_local

try:
    from .network_discovery import (
        get_network_interfaces,
        get_default_interface,
        validate_interface,
        print_interface_info
    )
    HAS_NETWORK_DISCOVERY = True
except ImportError:
    HAS_NETWORK_DISCOVERY = False

try:
    from .capture import create_capture_session, TrafficAnalyzer, ImpactAssessment
    HAS_CAPTURE = True
except ImportError:
    HAS_CAPTURE = False

__all__ = [
    'random_mac',
    'mac_to_link_local',
    'HAS_NETWORK_DISCOVERY',
    'HAS_CAPTURE'
]

# Add network discovery functions if available
if HAS_NETWORK_DISCOVERY:
    __all__.extend([
        'get_network_interfaces',
        'get_default_interface', 
        'validate_interface',
        'print_interface_info'
    ])

# Add capture functions if available
if HAS_CAPTURE:
    __all__.extend([
        'create_capture_session',
        'TrafficAnalyzer',
        'ImpactAssessment'
    ])
