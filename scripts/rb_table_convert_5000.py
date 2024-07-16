#!/bin/env python
import fileinput
import json
from collections import defaultdict

# parse data from stdin
nozzle_data = defaultdict(dict)
press_psi = 0
for line in fileinput.input():
    parts = line.split()
    if len(parts) == 6:
        press_psi = int(parts[0])
        parts = parts[1:]
    nozzle = parts[0]
    dist_ft = int(parts[1])
    flow_gpm = float(parts[2])
    nozzle_data[nozzle][press_psi] = {'dist_ft':dist_ft, 'flow_gpm':flow_gpm}

# dump data to json out
for nozzle in sorted(nozzle_data.keys()):
    print("{")
    print("  'nozzle' : '%s'," % nozzle)
    print("  'data' : [")
    press_data = nozzle_data[nozzle]
    print("    # press_psi, dist_ft, flow_gpm, optimal")
    for idx, press_psi in enumerate(sorted(press_data.keys())):
        is_last = idx == (len(press_data.keys()) - 1)
        data = press_data[press_psi]
        print("    [ %-9d, %-7d, %-8s, false]%s" % (press_psi, data['dist_ft'], "%0.2f" % data['flow_gpm'], "" if is_last else ","))
    print("  ]")
    print("},")

