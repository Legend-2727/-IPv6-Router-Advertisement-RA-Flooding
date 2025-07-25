#!/usr/bin/env python3
"""
Packet Capture and Analysis Module
---------------------------------
Capture and analyze network traffic during RA flood attacks
"""

import time
import threading
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from scapy.all import sniff, wrpcap, IPv6, ICMPv6ND_RA, ICMPv6ND_NS, ICMPv6ND_NA

class TrafficAnalyzer:
    """Analyze captured traffic during RA flood attacks."""
    
    def __init__(self, interface: str, capture_dir: str = "captures"):
        self.interface = interface
        self.capture_dir = Path(capture_dir)
        self.capture_dir.mkdir(exist_ok=True)
        
        # Statistics
        self.stats = {
            'ra_sent': 0,
            'ns_received': 0,
            'na_received': 0,
            'other_icmpv6': 0,
            'start_time': None,
            'end_time': None
        }
        
        # Captured packets
        self.captured_packets = []
        self.capture_thread = None
        self.capturing = False
        
    def start_capture(self):
        """Start packet capture in background thread."""
        if self.capturing:
            return
            
        self.capturing = True
        self.stats['start_time'] = datetime.now()
        
        def capture_worker():
            try:
                # Capture IPv6 ICMPv6 packets
                sniff(
                    iface=self.interface,
                    filter="icmp6",
                    prn=self._process_packet,
                    stop_filter=lambda x: not self.capturing,
                    store=False
                )
            except Exception as e:
                print(f"Capture error: {e}")
        
        self.capture_thread = threading.Thread(target=capture_worker, daemon=True)
        self.capture_thread.start()
        print(f"[+] Started packet capture on {self.interface}")
    
    def stop_capture(self):
        """Stop packet capture and save results."""
        if not self.capturing:
            return
            
        self.capturing = False
        self.stats['end_time'] = datetime.now()
        
        if self.capture_thread:
            self.capture_thread.join(timeout=5)
        
        # Save captured packets
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        pcap_file = self.capture_dir / f"ra_flood_{timestamp}.pcap"
        
        if self.captured_packets:
            wrpcap(str(pcap_file), self.captured_packets)
            print(f"[+] Saved {len(self.captured_packets)} packets to {pcap_file}")
        
        # Print statistics
        self._print_statistics()
    
    def _process_packet(self, packet):
        """Process captured packet and update statistics."""
        if not self.capturing:
            return
            
        try:
            if IPv6 in packet:
                # Store packet for later analysis
                self.captured_packets.append(packet)
                
                # Update statistics
                if ICMPv6ND_RA in packet:
                    self.stats['ra_sent'] += 1
                elif ICMPv6ND_NS in packet:
                    self.stats['ns_received'] += 1
                elif ICMPv6ND_NA in packet:
                    self.stats['na_received'] += 1
                else:
                    self.stats['other_icmpv6'] += 1
                    
        except Exception as e:
            # Skip malformed packets
            pass
    
    def _print_statistics(self):
        """Print capture statistics."""
        duration = (self.stats['end_time'] - self.stats['start_time']).total_seconds()
        
        print("\n" + "="*50)
        print("PACKET CAPTURE STATISTICS")
        print("="*50)
        print(f"Capture Duration: {duration:.2f} seconds")
        print(f"Router Advertisements: {self.stats['ra_sent']}")
        print(f"Neighbor Solicitations: {self.stats['ns_received']}")
        print(f"Neighbor Advertisements: {self.stats['na_received']}")
        print(f"Other ICMPv6: {self.stats['other_icmpv6']}")
        print(f"Total Packets: {len(self.captured_packets)}")
        
        if duration > 0:
            print(f"Average RA/sec: {self.stats['ra_sent'] / duration:.2f}")
        print("="*50)

class ImpactAssessment:
    """Assess the impact of RA flood attacks."""
    
    def __init__(self):
        self.baseline_metrics = {}
        self.attack_metrics = {}
        
    def capture_baseline(self, interface: str, duration: int = 30):
        """Capture baseline network metrics before attack."""
        print(f"[+] Capturing baseline metrics for {duration} seconds...")
        
        start_time = time.time()
        packets = []
        
        def capture_baseline_packets(pkt):
            packets.append(pkt)
        
        # Capture for specified duration
        sniff(
            iface=interface,
            timeout=duration,
            filter="icmp6",
            prn=capture_baseline_packets,
            store=False
        )
        
        self.baseline_metrics = {
            'duration': duration,
            'packet_count': len(packets),
            'timestamp': datetime.now()
        }
        
        print(f"[+] Baseline captured: {len(packets)} packets in {duration}s")
    
    def analyze_impact(self, capture_stats: Dict):
        """Analyze the impact of the attack."""
        if not self.baseline_metrics:
            print("[-] No baseline metrics available")
            return
        
        print("\n" + "="*50)
        print("IMPACT ASSESSMENT")
        print("="*50)
        
        baseline_rate = self.baseline_metrics['packet_count'] / self.baseline_metrics['duration']
        attack_rate = capture_stats.get('ra_sent', 0) / (
            (capture_stats.get('end_time', datetime.now()) - 
             capture_stats.get('start_time', datetime.now())).total_seconds() or 1
        )
        
        print(f"Baseline ICMPv6 rate: {baseline_rate:.2f} pkt/s")
        print(f"Attack RA rate: {attack_rate:.2f} pkt/s")
        print(f"Traffic increase: {(attack_rate / baseline_rate * 100) if baseline_rate > 0 else 'N/A'}%")
        
        # Assess severity
        if attack_rate > 100:
            severity = "HIGH"
        elif attack_rate > 50:
            severity = "MEDIUM"
        else:
            severity = "LOW"
        
        print(f"Attack Severity: {severity}")
        print("="*50)

def create_capture_session(interface: str, enable_impact_assessment: bool = False) -> TrafficAnalyzer:
    """Create a new capture session."""
    analyzer = TrafficAnalyzer(interface)
    
    if enable_impact_assessment:
        impact = ImpactAssessment()
        impact.capture_baseline(interface)
        analyzer.impact_assessor = impact
    
    return analyzer

if __name__ == "__main__":
    # Test capture functionality
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python capture.py <interface>")
        sys.exit(1)
    
    interface = sys.argv[1]
    
    print(f"Testing packet capture on {interface}")
    print("Press Ctrl+C to stop...")
    
    analyzer = create_capture_session(interface, enable_impact_assessment=True)
    analyzer.start_capture()
    
    try:
        time.sleep(30)  # Capture for 30 seconds
    except KeyboardInterrupt:
        pass
    
    analyzer.stop_capture()
    
    if hasattr(analyzer, 'impact_assessor'):
        analyzer.impact_assessor.analyze_impact(analyzer.stats)
