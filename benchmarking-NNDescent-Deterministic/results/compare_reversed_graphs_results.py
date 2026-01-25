#!/usr/bin/env python3
"""
Compare two neighbour-list dumps produced by K-NNG debugging.

For every datapoint we expect exactly four lines (possibly continued on
later lines):

    old forward  (N):  <space-separated IDs>
    old reverse  (M):  ...
    new forward  (K):  ...
    new reverse  (L):  ...

Order of the IDs is irrelevant; only the declared size and the *set*
matter.  Any discrepancy is printed together with the verbatim block
from both files so you can inspect the problem quickly.

Usage
-----
    python3 compare_reversed_graphs_results.py FILE_A FILE_B
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional

# ── regexes ────────────────────────────────────────────────────────────────
DP_RE  = re.compile(r'^\s*datapoint\s+(\d+)\s*:?\s*$', re.I)
HDR_RE = re.compile(
    r'^\s*(old|new)\s+(forward|reverse)\s+\((\d+)\):\s*(.*)$', re.I
)

# ── parsing ────────────────────────────────────────────────────────────────
def parse_file(path: Path) -> Tuple[Dict[int, dict], Dict[int, List[str]]]:
    data:  Dict[int, dict]      = {}
    lines: Dict[int, List[str]] = {}

    dp_id: Optional[int]        = None
    block: List[str]            = []

    pending_key: Optional[str]  = None     # e.g. "old_forward"
    declared_len: int           = 0
    vals: List[int]             = []

    def flush_pending() -> None:
        nonlocal pending_key, declared_len, vals
        if pending_key is None:
            return
        if dp_id is None:
            raise RuntimeError("parser internal error")

        data[dp_id]['%s_len' % pending_key] = declared_len
        data[dp_id][pending_key]            = set(vals)

        if len(vals) != declared_len:       # sloppy input → warning
            print(f'⚠  {path.name}  datapoint {dp_id}  {pending_key} – '
                  f'declared {declared_len} IDs but read {len(vals)}')

        pending_key  = None
        declared_len = 0
        vals         = []

    with path.open() as fh:
        for raw in fh:
            line = raw.rstrip('\n')

            if not line.strip():            # blank line
                if dp_id is not None:
                    block.append(line)
                continue

            m = DP_RE.match(line)           # start of a datapoint?
            if m:
                if dp_id is not None:
                    flush_pending()
                    lines[dp_id] = block
                dp_id = int(m.group(1))
                data[dp_id] = {}
                block = [line]
                continue

            m = HDR_RE.match(line)          # header “old forward (N): …”
            if m:
                flush_pending()
                kind, direction, n_str, tail = m.groups()
                pending_key  = '%s_%s' % (kind.lower(), direction.lower())
                declared_len = int(n_str)
                vals         = [int(x) for x in tail.split()] if tail else []
                block.append(line)
                continue

            if pending_key:                 # continuation of current list
                vals.extend(int(x) for x in line.split())
                block.append(line)
            elif dp_id is not None:         # unexpected line → keep it
                block.append(line)

    if dp_id is not None:                   # flush last block
        flush_pending()
        lines[dp_id] = block

    return data, lines

# ── comparison helpers ─────────────────────────────────────────────────────
def compare_dp(a: dict, b: dict) -> List[str]:
    diffs: List[str] = []
    for key in ('old_forward', 'old_reverse', 'new_forward', 'new_reverse'):
        len_a = a.get('%s_len' % key)
        len_b = b.get('%s_len' % key)
        if len_a != len_b:
            diffs.append('%s length %s vs %s' % (key, len_a, len_b))

        set_a: Set[int] = a.get(key, set())
        set_b: Set[int] = b.get(key, set())
        if set_a != set_b:
            missing = sorted(set_a - set_b)
            extra   = sorted(set_b - set_a)
            diffs.append('%s set differs (missing %s  extra %s)'
                         % (key, missing, extra))
    return diffs

# ── main ────────────────────────────────────────────────────────────────────
def main() -> None:
    ap = argparse.ArgumentParser(
        description='Compare two K-NNG neighbour-dump files'
    )
    ap.add_argument('fileA', type=Path, help='first dump')
    ap.add_argument('fileB', type=Path, help='second dump')
    args = ap.parse_args()

    dataA, linesA = parse_file(args.fileA)
    dataB, linesB = parse_file(args.fileB)

    all_dp = sorted(set(dataA) | set(dataB))
    diff_found = False

    for dp in all_dp:
        if dp not in dataA or dp not in dataB:
            diff_found = True
            print('\n▶ datapoint %d present only in %s' %
                  (dp, 'fileA' if dp in dataA else 'fileB'))
            if dp in linesA:
                print('-- fileA ------------------------------')
                print('\n'.join(linesA[dp]))
            if dp in linesB:
                print('-- fileB ------------------------------')
                print('\n'.join(linesB[dp]))
            continue

        reasons = compare_dp(dataA[dp], dataB[dp])
        if reasons:
            diff_found = True
            print('\n▶ datapoint %d differs:' % dp)
            for r in reasons:
                print('  -', r)
            print('-- fileA ------------------------------')
            print('\n'.join(linesA[dp]))
            print('-- fileB ------------------------------')
            print('\n'.join(linesB[dp]))

    if not diff_found:
        print('✔  dumps are identical (sizes & sets)')

if __name__ == '__main__':
    main()