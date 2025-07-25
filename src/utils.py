# src/utils.py
"""
Utility helpers for the IPv6 RA‑Flood project
"""

import random

# ----------------------------------------------------------------------
# 1.  Generate a locally administered, unicast MAC address (02:xx:xx:xx:xx:xx)
# ----------------------------------------------------------------------
def random_mac() -> str:
    mac = [0x02, 0x00, 0x00,
           random.randint(0x00, 0x7F),
           random.randint(0x00, 0xFF),
           random.randint(0x00, 0xFF)]
    return ":".join(f"{b:02x}" for b in mac)

# ----------------------------------------------------------------------
# 2.  Convert MAC‑48 → EUI‑64 → fe80:: link‑local address
#     Steps (RFC 4291, sect. 2.5.1):
#       • split MAC into 6 bytes
#       • flip the U/L bit (bit 1) of the first byte
#       • insert FFFE in the middle   (**** **** ff fe **** ****)
#       • format as XXXX:XXXX:XXXX:XXXX (four‑hextet string)
# ----------------------------------------------------------------------
def mac_to_link_local(mac: str) -> str:
    parts = mac.split(":")
    if len(parts) != 6:
        raise ValueError("MAC address must have 6 octets")

    # flip the “universal / local” bit
    first_byte = int(parts[0], 16) ^ 0x02
    parts[0] = f"{first_byte:02x}"

    # build the EUI‑64 (8 bytes) by inserting FF:FE in the middle
    eui64_parts = parts[:3] + ["ff", "fe"] + parts[3:]
    eui64 = "".join(eui64_parts)                # 16 hex chars

    # group into four‑character hextets
    hextets = [eui64[i:i + 4] for i in range(0, len(eui64), 4)]
    return "fe80::" + ":".join(hextets)

# ----------------------------------------------------------------------
# Quick self‑test when run directly
# ----------------------------------------------------------------------
if __name__ == "__main__":
    mac = random_mac()
    print("MAC :", mac)
    print("LLA :", mac_to_link_local(mac))
