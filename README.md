# Autometric
Autometric is minimal script to set Linux default route based on ICMP RTT(Round Trip Time) when there are multiple default routes in routing table.

## Quick Install:
Download the autometric.sh and run:
```
./automertic.sh install
```

## Options:
Options can be changed by editing autometric.sh file.

- MAINIF
  - Main network interface name.
- DEFAULT_METRIC
  - Set default metric , arbitrary 32bit number.
- MAINIF_PREF
  - Set milliseconds MAINIF preferred or set it to 0 for no priority.
- PING_HOST
  - Host address to ping
