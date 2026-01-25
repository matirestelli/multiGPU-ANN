#!/usr/bin/env python3
"""
Check that every datapoint mentioned in REPORT_A also appears in REPORT_B.

Reports are the text files produced by the neighbour-comparison script
(they contain lines that start with the "▶ datapoint N differs:" marker).

If a datapoint listed in REPORT_A is missing from REPORT_B, the script
prints an error line:

    ERROR: datapoint <id> present in REPORT_A but not in REPORT_B
"""

import argparse
import re
from pathlib import Path
from typing import Set

# recognise:  ▶ datapoint 40 differs:      or   ▶ datapoint 4
DP_LINE = re.compile(r'^▶\s*datapoint\s+(\d+)\b')

def collect_ids(path: Path) -> Set[int]:
    """Return the set of all datapoint IDs mentioned in *path*."""
    ids = set()
    with path.open() as fh:
        for line in fh:
            m = DP_LINE.match(line)
            if m:
                ids.add(int(m.group(1)))
    return ids

def main() -> None:
    ap = argparse.ArgumentParser(
        description='Check overlap of datapoint IDs between two reports')
    ap.add_argument('reportA', type=Path, help='reference report')
    ap.add_argument('reportB', type=Path, help='second report')
    args = ap.parse_args()

    ids_A = collect_ids(args.reportA)
    ids_B = collect_ids(args.reportB)

    missing = sorted(ids_A - ids_B)

    if not missing:
        print('✔  Every datapoint in', args.reportA.name,
              'also appears in', args.reportB.name)
        return

    print('✘  The following datapoints are missing in',
          args.reportB.name + ':')
    for dp in missing:
        print(f'  ERROR: datapoint {dp} present in {args.reportA.name} '
              f'but not in {args.reportB.name}')

if __name__ == '__main__':
    main()
